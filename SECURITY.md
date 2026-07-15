# Security Policy

## Supported versions

Security fixes are applied to the latest release.

## Reporting a vulnerability

Please do not open a public issue for a vulnerability involving keyboard event handling, Accessibility permissions, code signing, or unintended disclosure of application menu data.

Use GitHub's private vulnerability reporting feature for this repository. Include reproduction steps, affected macOS version, and the expected security impact. You should receive an acknowledgement within seven days.

## Privacy boundary

LEO-MACOS Shortcut Assistant reads menu titles and shortcut metadata exposed by the frontmost application through macOS Accessibility APIs. It does not record ordinary typing, does not modify keyboard events, and does not upload menu data.
