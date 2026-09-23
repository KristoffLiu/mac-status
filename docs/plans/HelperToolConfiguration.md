# Helper Tool Configuration Instructions

> Historical design notes, not the current build or distribution setup. The Xcode project
> currently contains only the MacStatus application target and does not ship this helper.
> These instructions have not been validated for production signing. A privileged helper
> does not make an app eligible for the Mac App Store; see [App Store readiness](../app-store-readiness.md).

To finish setting up the Privileged Helper Tool in Xcode, please follow these steps:

1. In Xcode, go to **File > New > Target...**
2. Choose **macOS > Command Line Tool**
3. Name it **MacStatusHelper**
4. Set Language to **Swift**
5. Add the `MacStatusHelper` directory files to this target:
   - `main.swift`
   - `HelperDelegate.swift`
   - `SMCEngine.swift`
   - `SMC_Bridging_Header.h` (Set this as the Objective-C Bridging Header in Build Settings)
6. Add `HelperProtocol.swift` to BOTH targets (`MacStatus` and `MacStatusHelper`).
7. Update `Info.plist` for MacStatusHelper with:
```xml
<key>SMAuthorizedClients</key>
<array>
    <string>identifier "com.kristoff.MacStatus" and anchor apple generic and certificate leaf[subject.CN] = "Apple Development: YOUR_CERT"</string>
</array>
    
<key>SMPrivilegedExecutables</key>
<dict>
    <key>com.kristoff.MacStatusHelper</key>
    <string>identifier "com.kristoff.MacStatusHelper" and anchor apple generic</string>
</dict>
```

8. Enable **App Sandbox** for MacStatus App, but **DO NOT** sandbox the Helper Tool.

Once these steps are completed in Xcode, our MacStatusApp can use `SMJobBless` or `SMAppService.daemon` to install the helper and establish the XPC connection.
