import AppKit
import ApplicationServices

final class AccessibilityReader: @unchecked Sendable {
    func requestPermission() -> Bool {
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true] as CFDictionary
        return AXIsProcessTrustedWithOptions(options)
    }

    func isTrusted() -> Bool {
        AXIsProcessTrusted()
    }

    func readShortcuts(from application: NSRunningApplication) -> ShortcutSnapshot {
        let appName = application.localizedName ?? "当前应用"
        guard isTrusted() else {
            return ShortcutSnapshot(
                appName: appName,
                bundleIdentifier: application.bundleIdentifier,
                sections: []
            )
        }

        let appElement = AXUIElementCreateApplication(application.processIdentifier)
        guard let menuBar = elementAttribute(kAXMenuBarAttribute, from: appElement) else {
            return fallbackSnapshot(for: application)
        }

        let topLevelMenus = children(of: menuBar)
        var sections: [ShortcutSection] = []

        for topLevelMenu in topLevelMenus {
            let sectionTitle = stringAttribute(kAXTitleAttribute, from: topLevelMenu) ?? "其他"
            var collected: [ShortcutItem] = []
            collectMenuItems(from: topLevelMenu, into: &collected, depth: 0)
            let uniqueItems = deduplicate(collected)
            if !uniqueItems.isEmpty {
                sections.append(ShortcutSection(title: sectionTitle, items: uniqueItems))
            }
        }

        if sections.isEmpty {
            return fallbackSnapshot(for: application)
        }

        return ShortcutSnapshot(
            appName: appName,
            bundleIdentifier: application.bundleIdentifier,
            sections: sections
        )
    }

    private func collectMenuItems(from element: AXUIElement, into items: inout [ShortcutItem], depth: Int) {
        guard depth < 8 else { return }

        if let title = stringAttribute(kAXTitleAttribute, from: element),
           !title.isEmpty,
           let shortcut = shortcutString(from: element),
           !shortcut.isEmpty {
            items.append(ShortcutItem(title: title, keys: shortcut))
        }

        for child in children(of: element) {
            collectMenuItems(from: child, into: &items, depth: depth + 1)
        }
    }

    private func shortcutString(from element: AXUIElement) -> String? {
        let commandCharacter = stringAttribute(kAXMenuItemCmdCharAttribute, from: element)
        let virtualKey = intAttribute(kAXMenuItemCmdVirtualKeyAttribute, from: element)
        let modifiers = intAttribute(kAXMenuItemCmdModifiersAttribute, from: element) ?? 0

        guard commandCharacter != nil || virtualKey != nil else { return nil }

        var result = ""
        // AXMenuItem modifiers use Carbon-style bits: command is present unless NoCommand is set.
        if modifiers & (1 << 3) == 0 { result += "⌘" }
        if modifiers & (1 << 0) != 0 { result += "⇧" }
        if modifiers & (1 << 1) != 0 { result += "⌥" }
        if modifiers & (1 << 2) != 0 { result += "⌃" }

        if let commandCharacter, !commandCharacter.isEmpty {
            result += displayCharacter(commandCharacter)
        } else if let virtualKey {
            result += virtualKeyName(virtualKey)
        }
        return result
    }

    private func displayCharacter(_ value: String) -> String {
        switch value {
        case "\r": return "↩"
        case "\t": return "⇥"
        case "\u{8}", "\u{7f}": return "⌫"
        case "\u{1b}": return "⎋"
        case " ": return "Space"
        default: return value.uppercased()
        }
    }

    private func virtualKeyName(_ key: Int) -> String {
        let names: [Int: String] = [
            36: "↩", 48: "⇥", 49: "Space", 51: "⌫", 53: "⎋",
            115: "↖", 116: "⇞", 117: "⌦", 119: "↘", 121: "⇟",
            123: "←", 124: "→", 125: "↓", 126: "↑",
            122: "F1", 120: "F2", 99: "F3", 118: "F4", 96: "F5", 97: "F6",
            98: "F7", 100: "F8", 101: "F9", 109: "F10", 103: "F11", 111: "F12"
        ]
        return names[key] ?? "Key\(key)"
    }

    private func children(of element: AXUIElement) -> [AXUIElement] {
        var value: CFTypeRef?
        guard AXUIElementCopyAttributeValue(element, kAXChildrenAttribute as CFString, &value) == .success,
              let array = value as? [AXUIElement] else { return [] }
        return array
    }

    private func elementAttribute(_ attribute: String, from element: AXUIElement) -> AXUIElement? {
        var value: CFTypeRef?
        guard AXUIElementCopyAttributeValue(element, attribute as CFString, &value) == .success else { return nil }
        return value as! AXUIElement?
    }

    private func stringAttribute(_ attribute: String, from element: AXUIElement) -> String? {
        var value: CFTypeRef?
        guard AXUIElementCopyAttributeValue(element, attribute as CFString, &value) == .success else { return nil }
        return value as? String
    }

    private func intAttribute(_ attribute: String, from element: AXUIElement) -> Int? {
        var value: CFTypeRef?
        guard AXUIElementCopyAttributeValue(element, attribute as CFString, &value) == .success else { return nil }
        if let number = value as? NSNumber { return number.intValue }
        return nil
    }

    private func deduplicate(_ items: [ShortcutItem]) -> [ShortcutItem] {
        var seen = Set<String>()
        return items.filter { seen.insert("\($0.title)|\($0.keys)").inserted }
    }

    private func fallbackSnapshot(for application: NSRunningApplication) -> ShortcutSnapshot {
        let appName = application.localizedName ?? "当前应用"
        let generic = ShortcutSection(title: "常用", items: [
            ShortcutItem(title: "新建", keys: "⌘N"),
            ShortcutItem(title: "打开", keys: "⌘O"),
            ShortcutItem(title: "保存", keys: "⌘S"),
            ShortcutItem(title: "关闭窗口", keys: "⌘W"),
            ShortcutItem(title: "撤销", keys: "⌘Z"),
            ShortcutItem(title: "复制", keys: "⌘C"),
            ShortcutItem(title: "粘贴", keys: "⌘V"),
            ShortcutItem(title: "查找", keys: "⌘F")
        ])
        return ShortcutSnapshot(appName: appName, bundleIdentifier: application.bundleIdentifier, sections: [generic])
    }
}
