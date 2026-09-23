"""Regression checks for publication gates and artifact integrity; no Apple account needed."""
import argparse
import importlib.util
import json
from pathlib import Path
import tempfile
import unittest
from unittest.mock import patch

spec = importlib.util.spec_from_file_location("release", Path(__file__).resolve().parents[1] / "scripts/release.py")
release = importlib.util.module_from_spec(spec)
spec.loader.exec_module(release)


class ReleaseTests(unittest.TestCase):
    def test_missing_credentials_stop_before_build(self):
        args = argparse.Namespace(mode="release", version="0.1.0", build_number=1)
        with patch.dict("os.environ", {}, clear=True), patch.object(release, "run") as run:
            with self.assertRaisesRegex(ValueError, "Release requires"):
                release.build(args)
            run.assert_not_called()

    def test_rejected_notarization_is_not_success(self):
        with patch.object(release, "run", return_value='{"status":"Invalid","id":"test-id"}'):
            with self.assertRaisesRegex(ValueError, "not accepted"):
                release.notarize(Path("test.dmg"), "test-profile")

    def test_unfinished_notarization_is_not_success(self):
        with patch.object(release, "run", return_value='{"status":"In Progress","id":"test-id"}'):
            with self.assertRaises(ValueError):
                release.notarize(Path("test.dmg"), "test-profile")

    def test_version_cannot_escape_artifact_directory(self):
        for value in ["../0.1.0", "v1.0.0", "1.0.0;echo bad", "1.0.0-beta"]:
            with self.subTest(value=value), self.assertRaises(argparse.ArgumentTypeError):
                release.version_value(value)

    def test_repository_cannot_inject_ruby(self):
        for value in ['owner/repo"', "owner/#{system('bad')}", "../repo", "owner/.."]:
            with self.subTest(value=value), self.assertRaises(argparse.ArgumentTypeError):
                release.repository_value(value)

    def make_artifacts(self, directory, distribution="developer-id-notarized"):
        dmg = directory / "MacStatus-0.1.0-arm64.dmg"
        dmg.write_bytes(b"test fixture, not a real disk image")
        manifest = {"version": "0.1.0", "distribution": distribution, "architecture": "arm64",
                    "minimum_macos": "26.0", "files": {dmg.name: release.sha256(dmg)}}
        (directory / "release.json").write_text(json.dumps(manifest))
        return argparse.Namespace(artifacts=directory, repository="example/mac-status",
                                  output=directory / "Casks/mac-status.rb")

    def test_local_build_cannot_become_public_cask(self):
        with tempfile.TemporaryDirectory() as temporary:
            args = self.make_artifacts(Path(temporary), "local-adhoc")
            with self.assertRaisesRegex(ValueError, "not a local test package"):
                release.cask(args)
            self.assertFalse(args.output.exists())

    def test_cask_detects_modified_dmg(self):
        with tempfile.TemporaryDirectory() as temporary:
            args = self.make_artifacts(Path(temporary))
            (args.artifacts / "MacStatus-0.1.0-arm64.dmg").write_bytes(b"modified")
            with self.assertRaisesRegex(ValueError, "checksum"):
                release.cask(args)
            self.assertFalse(args.output.exists())

    def test_cask_links_exact_release_with_verified_checksum(self):
        with tempfile.TemporaryDirectory() as temporary:
            args = self.make_artifacts(Path(temporary))
            release.cask(args)
            cask = args.output.read_text()
            self.assertIn('version "0.1.0"', cask)
            self.assertIn(release.sha256(args.artifacts / "MacStatus-0.1.0-arm64.dmg"), cask)
            self.assertIn('https://github.com/example/mac-status/releases/download/v#{version}/MacStatus-#{version}-arm64.dmg', cask)
            self.assertIn('depends_on arch: :arm64', cask)
            self.assertNotIn("@REPOSITORY@", cask)

    def test_verify_rejects_manifest_path_traversal_before_mounting(self):
        with tempfile.TemporaryDirectory() as temporary:
            args = self.make_artifacts(Path(temporary))
            manifest_path = args.artifacts / "release.json"
            metadata = json.loads(manifest_path.read_text())
            metadata["files"] = {"../outside.dmg": "0" * 64}
            manifest_path.write_text(json.dumps(metadata))
            with patch.object(release, "run") as run:
                with self.assertRaisesRegex(ValueError, "expected DMG and ZIP"):
                    release.verify_package(args)
                run.assert_not_called()

    def test_verify_rejects_tampered_archive_before_mounting(self):
        with tempfile.TemporaryDirectory() as temporary:
            args = self.make_artifacts(Path(temporary))
            archive = args.artifacts / "MacStatus-0.1.0-arm64.zip"
            archive.write_bytes(b"original")
            manifest_path = args.artifacts / "release.json"
            metadata = json.loads(manifest_path.read_text())
            metadata["files"][archive.name] = release.sha256(archive)
            manifest_path.write_text(json.dumps(metadata))
            archive.write_bytes(b"changed")
            with patch.object(release, "run") as run:
                with self.assertRaisesRegex(ValueError, "Checksum mismatch"):
                    release.verify_package(args)
                run.assert_not_called()


if __name__ == "__main__":
    unittest.main()
