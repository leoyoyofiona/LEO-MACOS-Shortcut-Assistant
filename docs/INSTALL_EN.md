# Installation and first launch

[Back to the project](../README_EN.md) · [简体中文](INSTALL.md)

The current community preview is not yet notarized with an Apple Developer ID. It still works, but macOS requires a one-time manual approval on first launch. **You do not need to disable Gatekeeper, and should not do so.**

![First-launch guide](images/install-guide-en.svg)

## 1. Download and install

1. Open the [latest release](https://github.com/leoyoyofiona/LEO-MACOS-Shortcut-Assistant/releases/latest).
2. Download the installer whose name ends in `.dmg`.
3. Double-click the DMG.
4. Drag `LEO-MACOS快捷键助手.app` into Applications.

## 2. Try opening the app once

1. Open Applications in Finder.
2. Double-click `LEO-MACOS快捷键助手`.
3. If macOS says the developer cannot be verified or Apple cannot check the app for malicious software, dismiss the message.
4. Do not delete the app; continue below.

## 3. Click Open Anyway

1. Open **System Settings → Privacy & Security**.
2. Scroll down to the Security section.
3. Find the message saying `LEO-MACOS快捷键助手` was blocked.
4. Click **Open Anyway** and authenticate with your Mac password or Touch ID.
5. Click **Open** in the final confirmation dialog.

The Open Anyway button normally appears only after a blocked launch attempt and remains available for about an hour. macOS remembers this exception, so future launches work with a normal double-click. See [Apple's official instructions](https://support.apple.com/guide/mac-help/mh40616/mac).

## 4. Grant required permissions

1. Enable `LEO-MACOS快捷键助手` under **System Settings → Privacy & Security → Accessibility**.
2. Enable it under **System Settings → Privacy & Security → Input Monitoring**.
3. Quit the assistant completely and relaunch it.

| Permission | Purpose |
| --- | --- |
| Accessibility | Detect the frontmost app and read shortcuts exposed by its menus |
| Input Monitoring | Detect only presses and releases of the selected trigger key |

The app does not record normal typing and does not intercept or modify key events.

## Verify the installation

1. Open the assistant and choose a trigger key in Settings.
2. Switch to Finder, Safari, or another app.
3. Hold the trigger key; the shortcut panel should appear immediately.
4. Release the key; the panel should disappear immediately.

## Troubleshooting

### Open Anyway is missing

Double-click the assistant in Applications once, then immediately return to System Settings → Privacy & Security and scroll down. Open Anyway appears only after macOS has blocked a launch attempt.

### Permissions are enabled, but the trigger does nothing

Turn the assistant off and back on in both Accessibility and Input Monitoring, then quit and relaunch it. If an older copy appears in either list, remove it and add the current app from Applications.

### A managed work or school Mac cannot approve the app

Organization-managed Macs may prevent users from overriding this protection. Contact the device administrator instead of disabling system security.
