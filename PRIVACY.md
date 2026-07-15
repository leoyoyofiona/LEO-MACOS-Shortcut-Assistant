# Privacy

LEO-MACOS Shortcut Assistant is designed as a local-first utility.

## Data accessed

- Name and bundle identifier of the frontmost application.
- Menu titles and keyboard-shortcut metadata exposed by that application through the macOS Accessibility API.
- Modifier-key press and release state for the trigger selected by the user.

## Data not collected

- Ordinary keyboard input.
- Document contents, passwords, clipboard contents, browser history, or files.
- Analytics, advertising identifiers, or telemetry.

## Storage and network

Preferences and translation cache are stored locally through macOS `UserDefaults`. The app does not operate a server and does not upload application menu data. Translation of unknown menu commands uses Apple's system Translation framework and its installed language models.

Removing the app and its preferences deletes the app's locally stored settings and translation cache.
