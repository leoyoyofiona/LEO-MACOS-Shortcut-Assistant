import AppKit
import SwiftUI

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private let reader = AccessibilityReader()
    private let keyMonitor = ControlKeyMonitor()
    private let panelController = ShortcutPanelController()
    private var statusItem: NSStatusItem?
    private var settingsWindow: NSWindow?
    private var lastExternalApplication: NSRunningApplication?
    private var cachedSnapshot: ShortcutSnapshot?
    private var cachedApplicationPID: pid_t?
    private var controlIsDown = false
    private var readGeneration = 0
    private var previewHideWorkItem: DispatchWorkItem?

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.regular)
        configureStatusItem()
        observeApplications()
        updateFrontmostApplication()

        keyMonitor.onControlChanged = { [weak self] isDown in
            guard let self else { return }
            self.controlIsDown = isDown
            isDown ? self.showPanel() : self.panelController.hide()
        }

        _ = reader.requestPermission()
        keyMonitor.start()
        openSettings()

        if ProcessInfo.processInfo.arguments.contains("--demo-overlay") {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) { [weak self] in
                self?.settingsWindow?.orderOut(nil)
                self?.previewPanel()
            }
        }
    }

    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        openSettings()
        return true
    }

    func applicationWillTerminate(_ notification: Notification) {
        keyMonitor.stop()
        NSWorkspace.shared.notificationCenter.removeObserver(self)
    }

    private func configureStatusItem() {
        let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        item.button?.image = NSImage(systemSymbolName: "command.square", accessibilityDescription: "LEO-MACOS快捷键助手")

        let menu = NSMenu()
        menu.addItem(withTitle: "设置 / Settings…", action: #selector(openSettings), keyEquivalent: ",")
        menu.addItem(withTitle: "预览面板 / Preview Panel", action: #selector(previewPanel), keyEquivalent: "")
        menu.addItem(withTitle: "辅助功能设置 / Accessibility", action: #selector(openAccessibilitySettings), keyEquivalent: "")
        menu.addItem(.separator())
        menu.addItem(withTitle: "退出 LEO-MACOS快捷键助手 / Quit", action: #selector(terminate), keyEquivalent: "q")
        menu.items.forEach { $0.target = self }
        item.menu = menu
        statusItem = item
    }

    private func observeApplications() {
        NSWorkspace.shared.notificationCenter.addObserver(
            self,
            selector: #selector(applicationActivated(_:)),
            name: NSWorkspace.didActivateApplicationNotification,
            object: nil
        )
    }

    @objc private func applicationActivated(_ notification: Notification) {
        guard let app = notification.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication,
              app.bundleIdentifier != Bundle.main.bundleIdentifier else { return }
        lastExternalApplication = app
        cachedSnapshot = nil
        cachedApplicationPID = nil
        prefetchShortcuts(for: app)
    }

    private func updateFrontmostApplication() {
        if let app = NSWorkspace.shared.frontmostApplication,
           app.bundleIdentifier != Bundle.main.bundleIdentifier {
            lastExternalApplication = app
        }
    }

    private func showPanel() {
        previewHideWorkItem?.cancel()
        guard reader.isTrusted() else {
            _ = reader.requestPermission()
            return
        }
        updateFrontmostApplication()
        guard let application = lastExternalApplication else { return }

        if let cachedSnapshot, cachedApplicationPID == application.processIdentifier {
            panelController.show(snapshot: cachedSnapshot, position: selectedPanelPosition)
        } else {
            // Always provide immediate visual feedback; replace it when the app menu is ready.
            panelController.show(snapshot: loadingSnapshot(for: application), position: selectedPanelPosition)
            prefetchShortcuts(for: application)
        }
    }

    @objc private func previewPanel() {
        previewHideWorkItem?.cancel()
        panelController.show(snapshot: previewSnapshot(), position: selectedPanelPosition)
        let workItem = DispatchWorkItem { [weak self] in
            guard let self, !self.controlIsDown else { return }
            self.panelController.hide()
        }
        previewHideWorkItem = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + 8, execute: workItem)
    }

    private func previewSnapshot() -> ShortcutSnapshot {
        ShortcutSnapshot(
            appName: "Safari",
            bundleIdentifier: "com.apple.Safari",
            sections: [
                ShortcutSection(title: "File", items: [
                    ShortcutItem(title: "New Window", keys: "⌘N"),
                    ShortcutItem(title: "New Tab", keys: "⌘T"),
                    ShortcutItem(title: "Open", keys: "⌘O"),
                    ShortcutItem(title: "Close Tab", keys: "⌘W"),
                    ShortcutItem(title: "Save As", keys: "⇧⌘S")
                ]),
                ShortcutSection(title: "Edit", items: [
                    ShortcutItem(title: "Undo", keys: "⌘Z"),
                    ShortcutItem(title: "Cut", keys: "⌘X"),
                    ShortcutItem(title: "Copy", keys: "⌘C"),
                    ShortcutItem(title: "Paste", keys: "⌘V"),
                    ShortcutItem(title: "Find", keys: "⌘F")
                ]),
                ShortcutSection(title: "View", items: [
                    ShortcutItem(title: "Actual Size", keys: "⌘0"),
                    ShortcutItem(title: "Zoom In", keys: "⌘+"),
                    ShortcutItem(title: "Zoom Out", keys: "⌘−"),
                    ShortcutItem(title: "Show Sidebar", keys: "⇧⌘L"),
                    ShortcutItem(title: "Enter Full Screen", keys: "⌃⌘F")
                ]),
                ShortcutSection(title: "Window", items: [
                    ShortcutItem(title: "Minimize", keys: "⌘M"),
                    ShortcutItem(title: "Previous Tab", keys: "⇧⌃⇥"),
                    ShortcutItem(title: "Next Tab", keys: "⌃⇥"),
                    ShortcutItem(title: "Bring All to Front", keys: "⌥⌘B")
                ]),
                ShortcutSection(title: "Help", items: [
                    ShortcutItem(title: "Downloads", keys: "⌥⌘L"),
                    ShortcutItem(title: "History", keys: "⌘Y")
                ])
            ]
        )
    }

    private var selectedPanelPosition: PanelPosition {
        let rawPosition = UserDefaults.standard.string(forKey: "panelPosition") ?? PanelPosition.center.rawValue
        return PanelPosition(rawValue: rawPosition) ?? .center
    }

    private func loadingSnapshot(for application: NSRunningApplication) -> ShortcutSnapshot {
        ShortcutSnapshot(
            appName: application.localizedName ?? "当前应用",
            bundleIdentifier: application.bundleIdentifier,
            sections: [
                ShortcutSection(
                    title: "正在读取",
                    items: [ShortcutItem(title: "正在读取这个应用的菜单快捷键", keys: "…")]
                )
            ]
        )
    }

    private func prefetchShortcuts(for application: NSRunningApplication) {
        guard reader.isTrusted() else { return }
        readGeneration += 1
        let generation = readGeneration
        let pid = application.processIdentifier
        let reader = self.reader

        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            let snapshot = reader.readShortcuts(from: application)
            DispatchQueue.main.async {
                guard let self,
                      generation == self.readGeneration,
                      self.lastExternalApplication?.processIdentifier == pid else { return }
                self.cachedSnapshot = snapshot
                self.cachedApplicationPID = pid
                if self.controlIsDown {
                    self.panelController.show(snapshot: snapshot, position: self.selectedPanelPosition)
                }
            }
        }
    }

    @objc private func openSettings() {
        let view = SettingsView(
            accessibilityGranted: reader.isTrusted(),
            inputMonitoringGranted: keyMonitor.hasInputMonitoringPermission,
            onRequestAccessibility: { [weak self] in _ = self?.reader.requestPermission() },
            onRequestInputMonitoring: { [weak self] in _ = self?.keyMonitor.requestInputMonitoringPermission() }
        )

        if settingsWindow == nil {
            let window = NSWindow(
                contentRect: NSRect(x: 0, y: 0, width: 620, height: 480),
                styleMask: [.titled, .closable, .miniaturizable],
                backing: .buffered,
                defer: false
            )
            window.title = "LEO-MACOS快捷键助手"
            window.contentView = NSHostingView(rootView: view)
            window.isReleasedWhenClosed = false
            settingsWindow = window
        } else {
            settingsWindow?.contentView = NSHostingView(rootView: view)
        }

        NSApp.activate(ignoringOtherApps: true)
        settingsWindow?.center()
        settingsWindow?.makeKeyAndOrderFront(nil)
    }

    @objc private func openAccessibilitySettings() {
        let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")!
        NSWorkspace.shared.open(url)
    }

    @objc private func terminate() {
        NSApp.terminate(nil)
    }
}
