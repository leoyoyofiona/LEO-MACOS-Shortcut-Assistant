# Contributing / 参与贡献

Thanks for helping improve LEO-MACOS Shortcut Assistant.

感谢你参与改进 LEO-MACOS快捷键助手。

## Before opening a pull request

1. Search existing issues and pull requests.
2. Keep each change focused on one problem.
3. Build locally with `swift build`.
4. Test trigger press/release behavior in at least two apps.
5. Never commit signing certificates, provisioning profiles, API keys, or personal menu data.

## Local development

```zsh
swift build
./build-app.sh
open "dist/LEO-MACOS快捷键助手.app"
```

The app needs Accessibility and Input Monitoring permissions for full testing. Re-signing with a different identity can invalidate existing TCC permissions.

## Pull requests

Describe:

- what changed;
- why it changed;
- how it was tested;
- screenshots or a short recording for UI changes.

By contributing, you agree that your contribution is licensed under the MIT License.
