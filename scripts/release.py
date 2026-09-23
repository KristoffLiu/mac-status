#!/usr/bin/env python3
"""Build MacStatus locally or produce notarized distribution artifacts (stdlib only)."""

import argparse
import hashlib
import json
import os
from pathlib import Path
import plistlib
import re
import subprocess
import sys
import tempfile

ROOT = Path(__file__).resolve().parents[1]
PROJECT = ROOT / "MacStatus/MacStatus.xcodeproj"


def run(*args, capture=False):
    result = subprocess.run([str(arg) for arg in args], check=True, text=True,
                            stdout=subprocess.PIPE if capture else None)
    return result.stdout.strip() if capture else None


def fail(message):
    raise ValueError(message)


def version_value(value):
    if not re.fullmatch(r"[0-9]+\.[0-9]+\.[0-9]+", value):
        raise argparse.ArgumentTypeError("Version must be three numbers, e.g. 0.1.0")
    return value


def repository_value(value):
    if not re.fullmatch(r"[A-Za-z0-9][A-Za-z0-9-]*/[A-Za-z0-9_.-]+", value):
        raise argparse.ArgumentTypeError("Repository must be owner/repository")
    if value.split("/")[1] in (".", ".."):
        raise argparse.ArgumentTypeError("Invalid repository name")
    return value


def sha256(path):
    digest = hashlib.sha256()
    with path.open("rb") as source:
        for chunk in iter(lambda: source.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def app_info(app):
    with (app / "Contents/Info.plist").open("rb") as source:
        return plistlib.load(source)


def source_digest():
    """Detect concurrent edits to files that Xcode includes in the application."""
    paths = list((ROOT / "MacStatus/MacStatus").rglob("*"))
    paths.append(PROJECT / "project.pbxproj")
    digest = hashlib.sha256()
    for path in sorted(path for path in paths if path.is_file() and path.name != ".DS_Store"):
        digest.update(str(path.relative_to(ROOT)).encode())
        digest.update(b"\0")
        digest.update(path.read_bytes())
        digest.update(b"\0")
    return digest.hexdigest()


def verify_app(app, version, build_number):
    info = app_info(app)
    if info["CFBundleShortVersionString"] != version:
        fail("Built app version does not match requested version")
    if info["CFBundleVersion"] != str(build_number):
        fail("Built app build number does not match requested build number")
    executable = app / "Contents/MacOS" / info["CFBundleExecutable"]
    if run("lipo", "-archs", executable, capture=True).split() != ["arm64"]:
        fail("The initial release supports arm64 only")
    if info["LSMinimumSystemVersion"] != "26.0":
        fail("Update release metadata and Cask requirements before changing minimum macOS")
    run("codesign", "--verify", "--deep", "--strict", "--verbose=2", app)
    return info


def notarize(path, profile, keychain=None):
    command = ["xcrun", "notarytool", "submit", path,
               "--keychain-profile", profile, "--wait", "--output-format", "json"]
    if keychain:
        command.extend(["--keychain", keychain])
    result = json.loads(run(*command, capture=True))
    print(json.dumps(result, indent=2), flush=True)
    if result.get("status") != "Accepted":
        fail(f"Notarization was not accepted; submission ID: {result.get('id', 'unknown')}")


def build(args):
    if args.build_number < 1:
        fail("Build number must be positive")
    license_text = (ROOT / "LICENSE").read_bytes()
    if (ROOT / "MacStatus/MacStatus/Resources/LICENSE.txt").read_bytes() != license_text:
        fail("Bundled license must match the repository LICENSE")
    signed = args.mode == "release"
    identity = os.environ.get("MACSTATUS_SIGNING_IDENTITY", "")
    team = os.environ.get("MACSTATUS_TEAM_ID", "")
    profile = os.environ.get("MACSTATUS_NOTARY_PROFILE", "")
    keychain = os.environ.get("MACSTATUS_KEYCHAIN")
    bundle_id = os.environ.get("MACSTATUS_BUNDLE_ID")
    if bundle_id and not re.fullmatch(r"[A-Za-z0-9-]+(?:\.[A-Za-z0-9-]+)+", bundle_id):
        fail("MACSTATUS_BUNDLE_ID must be a reverse-DNS identifier")
    if signed:
        if not identity.startswith("Developer ID Application:") or not team or not profile or not bundle_id:
            fail("Release requires MACSTATUS_SIGNING_IDENTITY (Developer ID Application), "
                 "MACSTATUS_TEAM_ID, MACSTATUS_NOTARY_PROFILE and MACSTATUS_BUNDLE_ID")
        identities = run("security", "find-identity", "-v", "-p", "codesigning",
                         *([keychain] if keychain else []), capture=True)
        if f'"{identity}"' not in identities:
            fail("Requested Developer ID identity is unavailable in the keychain")

    label = f"{args.version}-arm64" + ("" if signed else "-local")
    output = ROOT / "dist" / label
    if output.exists():
        fail(f"Output already exists: {output}. Move it aside or use a new version.")
    derived = ROOT / "build" / f"{args.mode}-DerivedData"
    command = ["xcodebuild", "-project", PROJECT, "-scheme", "MacStatus",
               "-configuration", "Release", "-destination", "generic/platform=macOS",
               "-derivedDataPath", derived, "ARCHS=arm64", "ONLY_ACTIVE_ARCH=NO",
               f"MARKETING_VERSION={args.version}", f"CURRENT_PROJECT_VERSION={args.build_number}",
               "CODE_SIGN_STYLE=Manual", "ENABLE_HARDENED_RUNTIME=YES",
               f"CODE_SIGN_IDENTITY={identity if signed else '-'}",
               f"DEVELOPMENT_TEAM={team if signed else ''}"]
    if bundle_id:
        command.append(f"PRODUCT_BUNDLE_IDENTIFIER={bundle_id}")
    # Never silently omit signing or notarization in release mode.
    command.extend(["CODE_SIGNING_ALLOWED=YES", "CODE_SIGNING_REQUIRED=YES"])
    if signed:
        flags = "--timestamp"
        if keychain:
            # Xcode parses OTHER_CODE_SIGN_FLAGS as a shell argument string.
            import shlex
            flags += " --keychain " + shlex.quote(keychain)
        command.append(f"OTHER_CODE_SIGN_FLAGS={flags}")
    source_hash = source_digest()
    run(*command, "build")
    if source_digest() != source_hash:
        fail("App source changed during the build. Wait for concurrent edits to finish and rebuild.")
    built_app = derived / "Build/Products/Release/MacStatus.app"
    verify_app(built_app, args.version, args.build_number)

    output.parent.mkdir(parents=True, exist_ok=True)
    with tempfile.TemporaryDirectory(prefix=".packaging-", dir=output.parent) as temporary:
        work = Path(temporary)
        assets = work / "assets"
        assets.mkdir()
        staging = work / "volume"
        staging.mkdir()
        app = staging / "MacStatus.app"
        run("ditto", built_app, app)
        info = app_info(app)
        if signed:
            upload = work / "notarization.zip"
            run("ditto", "-c", "-k", "--sequesterRsrc", "--keepParent", app, upload)
            notarize(upload, profile, keychain)
            run("xcrun", "stapler", "staple", app)
            run("xcrun", "stapler", "validate", app)
            run("spctl", "--assess", "--type", "execute", "--verbose=2", app)

        stem = f"MacStatus-{label}"
        archive = assets / f"{stem}.zip"
        run("ditto", "-c", "-k", "--sequesterRsrc", "--keepParent", app, archive)
        (staging / "Applications").symlink_to("/Applications")
        (staging / "安装说明.txt").write_text(
            "将 MacStatus.app 拖入 Applications，再从应用程序中打开。\n"
            "MacStatus 运行于菜单栏。系统要求：Apple Silicon，macOS 26 或更高版本。\n"
            + ("" if signed else "这是本地测试包，未经 Developer ID 签名或 Apple 公证。\n"),
            encoding="utf-8")
        dmg = assets / f"{stem}.dmg"
        run("hdiutil", "create", "-volname", f"MacStatus {args.version}", "-srcfolder", staging,
            "-ov", "-format", "UDZO", dmg)
        if signed:
            command = ["codesign", "--sign", identity, "--timestamp"]
            if keychain:
                command.extend(["--keychain", keychain])
            run(*command, dmg)
            notarize(dmg, profile, keychain)
            run("xcrun", "stapler", "staple", dmg)
            run("xcrun", "stapler", "validate", dmg)
            run("codesign", "--verify", "--verbose=2", dmg)
            run("spctl", "--assess", "--type", "open", "--context", "context:primary-signature",
                "--verbose=2", dmg)
        run("hdiutil", "verify", dmg)
        checksums = {path.name: sha256(path) for path in (dmg, archive)}
        (assets / "SHA256SUMS.txt").write_text(
            "".join(f"{digest}  {name}\n" for name, digest in checksums.items()), encoding="utf-8")
        metadata = {
            "version": args.version, "build_number": args.build_number,
            "architecture": "arm64", "minimum_macos": info["LSMinimumSystemVersion"],
            "bundle_id": info["CFBundleIdentifier"],
            "distribution": "developer-id-notarized" if signed else "local-adhoc",
            "commit": run("git", "-C", ROOT, "rev-parse", "HEAD", capture=True),
            "working_tree_dirty": bool(run("git", "-C", ROOT, "status", "--porcelain", capture=True)),
            "source_sha256": source_hash,
            "files": checksums,
        }
        (assets / "release.json").write_text(json.dumps(metadata, indent=2) + "\n", encoding="utf-8")
        assets.rename(output)
    print(f"\nArtifacts: {output}")


def cask(args):
    directory = args.artifacts.resolve()
    metadata = json.loads((directory / "release.json").read_text(encoding="utf-8"))
    if metadata.get("distribution") != "developer-id-notarized":
        fail("Casks must reference a signed and notarized release, not a local test package")
    version = version_value(metadata["version"])
    if metadata.get("architecture") != "arm64" or metadata.get("minimum_macos") != "26.0":
        fail("Unsupported release architecture or minimum macOS")
    filename = f"MacStatus-{version}-arm64.dmg"
    expected = metadata["files"][filename]
    if sha256(directory / filename) != expected:
        fail("DMG checksum does not match the release manifest")
    template = (ROOT / "packaging/homebrew/mac-status.rb.in").read_text(encoding="utf-8")
    for key, value in {"VERSION": version, "SHA256": expected, "REPOSITORY": args.repository}.items():
        template = template.replace(f"@{key}@", value)
    args.output.parent.mkdir(parents=True, exist_ok=True)
    args.output.write_text(template, encoding="utf-8")
    print(f"Generated Cask: {args.output}")


def verify_package(args):
    directory = args.artifacts.resolve()
    metadata = json.loads((directory / "release.json").read_text(encoding="utf-8"))
    version = version_value(metadata["version"])
    distribution = metadata["distribution"]
    if distribution not in ("local-adhoc", "developer-id-notarized"):
        fail("Unknown distribution mode")
    signed = distribution == "developer-id-notarized"
    stem = f"MacStatus-{version}-arm64" + ("" if signed else "-local")
    expected_names = {f"{stem}.dmg", f"{stem}.zip"}
    if set(metadata["files"]) != expected_names:
        fail("Release manifest must contain exactly the expected DMG and ZIP")
    for name, checksum in metadata["files"].items():
        if sha256(directory / name) != checksum:
            fail(f"Checksum mismatch: {name}")
    expected_checksums = "".join(f"{checksum}  {name}\n" for name, checksum in metadata["files"].items())
    if (directory / "SHA256SUMS.txt").read_text(encoding="utf-8") != expected_checksums:
        fail("SHA256SUMS.txt does not match release.json")
    dmg = directory / f"{stem}.dmg"
    run("hdiutil", "verify", dmg)
    with tempfile.TemporaryDirectory(prefix="macstatus-verify-") as temporary:
        work = Path(temporary)
        mount = work / "volume"
        mount.mkdir()
        run("hdiutil", "attach", "-nobrowse", "-readonly", "-mountpoint", mount, dmg)
        try:
            if not (mount / "Applications").is_symlink() or os.readlink(mount / "Applications") != "/Applications":
                fail("DMG does not contain the Applications installation shortcut")
            installed = work / "installed/MacStatus.app"
            installed.parent.mkdir()
            run("ditto", mount / "MacStatus.app", installed)
        finally:
            run("hdiutil", "detach", mount)
        unpacked = work / "unzipped"
        run("ditto", "-x", "-k", directory / f"{stem}.zip", unpacked)
        for app in (installed, unpacked / "MacStatus.app"):
            info = verify_app(app, version, metadata["build_number"])
            if info["CFBundleIdentifier"] != metadata["bundle_id"]:
                fail("Packaged app identity does not match manifest")
            icon = info.get("CFBundleIconFile")
            if not icon or not (app / "Contents/Resources" / (icon if icon.endswith(".icns") else icon + ".icns")).is_file():
                fail("Packaged app is missing its icon")
            if (app / "Contents/Resources/LICENSE.txt").read_bytes() != (ROOT / "LICENSE").read_bytes():
                fail("Packaged app license does not match repository LICENSE")
            if signed:
                run("xcrun", "stapler", "validate", app)
                run("spctl", "--assess", "--type", "execute", "--verbose=2", app)
        if signed:
            run("xcrun", "stapler", "validate", dmg)
            run("codesign", "--verify", "--verbose=2", dmg)
    print(f"Verified checksums, mounted DMG and extracted ZIP: {directory}")


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    commands = parser.add_subparsers(dest="command", required=True)
    builder = commands.add_parser("build", help="Build and package the app")
    builder.add_argument("--mode", choices=["local", "release"], default="local")
    builder.add_argument("--version", type=version_value, required=True)
    builder.add_argument("--build-number", type=int, default=1)
    builder.set_defaults(handler=build)
    brew = commands.add_parser("cask", help="Generate a Cask from verified release artifacts")
    brew.add_argument("--artifacts", type=Path, required=True)
    brew.add_argument("--repository", type=repository_value, required=True)
    brew.add_argument("--output", type=Path, default=ROOT / "build/Casks/mac-status.rb")
    brew.set_defaults(handler=cask)
    verifier = commands.add_parser("verify", help="Mount the DMG and verify both packaged apps")
    verifier.add_argument("--artifacts", type=Path, required=True)
    verifier.set_defaults(handler=verify_package)
    args = parser.parse_args()
    try:
        args.handler(args)
    except (ValueError, KeyError, OSError, subprocess.CalledProcessError) as error:
        print(f"Release failed: {error}", file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
