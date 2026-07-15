import AppKit
import SwiftUI
import Translation

final class ShortcutPanelController {
    private let panel: NSPanel
    private var hostingView: NSHostingView<ShortcutPanelView>?

    init() {
        panel = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: 900, height: 590),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: true
        )
        panel.level = .statusBar
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = true
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .transient]
        panel.hidesOnDeactivate = false
        // The overlay stays non-activating, but must accept trackpad and mouse-wheel scrolling.
        panel.ignoresMouseEvents = false
        panel.isReleasedWhenClosed = false
    }

    func show(snapshot: ShortcutSnapshot, position: PanelPosition) {
        let screen = screenUnderPointer()
        let visible = screen?.visibleFrame ?? NSRect(x: 0, y: 0, width: 1200, height: 800)
        let panelSize = NSSize(
            width: min(1180, visible.width * 0.94),
            height: min(780, visible.height * 0.90)
        )
        panel.setContentSize(panelSize)

        let view = ShortcutPanelView(snapshot: snapshot, panelSize: panelSize)
        let hostingView = NSHostingView(rootView: view)
        hostingView.frame = panel.contentView?.bounds ?? .zero
        hostingView.autoresizingMask = [.width, .height]
        panel.contentView = hostingView
        self.hostingView = hostingView

        positionPanel(position, on: screen)
        panel.alphaValue = 1
        panel.orderFrontRegardless()
    }

    func hide() {
        guard panel.isVisible else { return }
        panel.alphaValue = 0
        panel.orderOut(nil)
    }

    private func screenUnderPointer() -> NSScreen? {
        let mouseLocation = NSEvent.mouseLocation
        return NSScreen.screens.first(where: { $0.frame.contains(mouseLocation) }) ?? NSScreen.main
    }

    private func positionPanel(_ position: PanelPosition, on screen: NSScreen?) {
        guard let visible = screen?.visibleFrame else { return }
        let size = panel.frame.size
        let padding: CGFloat = 28
        let origin: NSPoint

        switch position {
        case .center:
            origin = NSPoint(x: visible.midX - size.width / 2, y: visible.midY - size.height / 2)
        case .top:
            origin = NSPoint(x: visible.midX - size.width / 2, y: visible.maxY - size.height - padding)
        case .topRight:
            origin = NSPoint(x: visible.maxX - size.width - padding, y: visible.maxY - size.height - padding)
        case .bottomRight:
            origin = NSPoint(x: visible.maxX - size.width - padding, y: visible.minY + padding)
        }
        panel.setFrameOrigin(origin)
    }
}

struct ShortcutPanelView: View {
    let snapshot: ShortcutSnapshot
    let panelSize: NSSize

    @Environment(\.colorScheme) private var colorScheme
    @AppStorage("displayLanguage") private var displayLanguage = DisplayLanguage.chinese.rawValue
    @AppStorage("triggerKey") private var triggerKey = TriggerKey.leftControl.rawValue
    @State private var machineTranslations: [String: String] = [:]
    @State private var translationConfiguration: TranslationSession.Configuration?

    private let columns = [
        GridItem(.adaptive(minimum: 290, maximum: 380), spacing: 18, alignment: .top)
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(spacing: 12) {
                Image(nsImage: appIcon)
                    .resizable()
                    .frame(width: 36, height: 36)
                    .cornerRadius(8)
                VStack(alignment: .leading, spacing: 2) {
                    Text(snapshot.appName)
                        .font(.title2.weight(.semibold))
                    Text(releaseHint)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Text(language == .chinese ? "快捷键 \(shortcutCount) 项" : "\(shortcutCount) shortcuts")
                    .font(.caption.weight(.medium))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(.white.opacity(0.08), in: Capsule())
            }

            ScrollView([.horizontal, .vertical]) {
                LazyVGrid(columns: columns, alignment: .leading, spacing: 18) {
                    ForEach(snapshot.sections) { section in
                        ShortcutSectionView(section: localized(section), fontScale: automaticFontScale)
                    }
                }
                .frame(minWidth: max(580, panelSize.width - 48), alignment: .topLeading)
                .padding(.bottom, 4)
            }
            .scrollIndicators(.visible)
        }
        .padding(24)
        .frame(width: panelSize.width, height: panelSize.height)
        .foregroundStyle(.primary)
        .background(.ultraThinMaterial)
        .background(Color(nsColor: .windowBackgroundColor).opacity(colorScheme == .dark ? 0.30 : 0.44))
        .background {
            LinearGradient(
                colors: [Color.white.opacity(colorScheme == .dark ? 0.07 : 0.20), Color.clear],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(
                    LinearGradient(
                        colors: [Color.white.opacity(0.42), Color.primary.opacity(0.10)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        }
        .task(id: translationTaskID) {
            machineTranslations = PanelLocalization.cachedTranslations(language: language)
            let source = language == .chinese ? "en" : "zh-Hans"
            let target = language == .chinese ? "zh-Hans" : "en"
            translationConfiguration = TranslationSession.Configuration(
                source: Locale.Language(identifier: source),
                target: Locale.Language(identifier: target)
            )
        }
        .translationTask(translationConfiguration) { session in
            await translateMissingText(with: session)
        }
    }

    private var shortcutCount: Int {
        snapshot.sections.reduce(0) { $0 + $1.items.count }
    }

    private var language: DisplayLanguage {
        DisplayLanguage(rawValue: displayLanguage) ?? .chinese
    }

    private var releaseHint: String {
        let key = TriggerKey(rawValue: triggerKey) ?? .leftControl
        return language == .chinese
            ? "松开\(key.chineseName)隐藏"
            : "Release \(key.englishName) to hide"
    }

    private func localized(_ section: ShortcutSection) -> ShortcutSection {
        ShortcutSection(
            title: localizedText(section.title),
            items: section.items.map {
                ShortcutItem(title: localizedText($0.title), keys: $0.keys)
            }
        )
    }

    private func localizedText(_ source: String) -> String {
        let builtIn = PanelLocalization.text(source, language: language)
        guard PanelLocalization.needsMachineTranslation(source, language: language) else {
            return builtIn
        }
        if let translated = machineTranslations[source],
           PanelLocalization.isValidTargetText(translated, language: language) {
            return translated
        }
        return language == .chinese ? "翻译中…" : "Translating…"
    }

    private var translationTaskID: String {
        let titles = snapshot.sections.flatMap { [$0.title] + $0.items.map(\.title) }.joined(separator: "|")
        return "\(displayLanguage)|\(titles.hashValue)"
    }

    private var missingTranslationTexts: [String] {
        let allTexts = snapshot.sections.flatMap { [$0.title] + $0.items.map(\.title) }
        var seen = Set<String>()
        return allTexts.filter {
            seen.insert($0).inserted &&
            PanelLocalization.needsMachineTranslation($0, language: language) &&
            machineTranslations[$0] == nil
        }
    }

    private func translateMissingText(with session: TranslationSession) async {
        let missing = missingTranslationTexts
        guard !missing.isEmpty else { return }
        do {
            try await session.prepareTranslation()
            let requests = missing.map { TranslationSession.Request(sourceText: $0, clientIdentifier: $0) }
            let responses = try await session.translations(from: requests)
            var completed: [String: String] = [:]
            for response in responses {
                if PanelLocalization.isValidTargetText(response.targetText, language: language) {
                    completed[response.clientIdentifier ?? response.sourceText] = response.targetText
                }
            }
            machineTranslations.merge(completed) { _, new in new }
            PanelLocalization.saveTranslations(completed, language: language)
        } catch {
            // Keep the single-language placeholder; a later panel display retries translation.
        }
    }

    private var automaticFontScale: CGFloat {
        let screenScale = min(1.14, max(0.94, panelSize.width / 1050))
        let densityScale: CGFloat
        switch shortcutCount {
        case 0...35: densityScale = 1.10
        case 36...80: densityScale = 1.0
        default: densityScale = 0.94
        }
        return max(0.94, min(1.18, screenScale * densityScale))
    }

    private var appIcon: NSImage {
        guard let bundleIdentifier = snapshot.bundleIdentifier,
              let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleIdentifier) else {
            return NSImage(named: NSImage.applicationIconName) ?? NSImage()
        }
        return NSWorkspace.shared.icon(forFile: url.path)
    }
}

private struct ShortcutSectionView: View {
    let section: ShortcutSection
    let fontScale: CGFloat

    @Environment(\.colorScheme) private var colorScheme

    private var accent: Color {
        let name = section.title.lowercased()
        if name.contains("文件") || name.contains("file") { return adaptiveAccent(hue: 0.58) }
        if name.contains("编辑") || name.contains("edit") { return adaptiveAccent(hue: 0.76) }
        if name.contains("显示") || name.contains("视图") || name.contains("view") { return adaptiveAccent(hue: 0.46) }
        if name.contains("窗口") || name.contains("window") { return adaptiveAccent(hue: 0.08) }
        if name.contains("帮助") || name.contains("help") { return adaptiveAccent(hue: 0.98) }
        if name.contains("前往") || name.contains("go") || name.contains("导航") { return adaptiveAccent(hue: 0.31) }
        if name.contains("格式") || name.contains("format") { return adaptiveAccent(hue: 0.13) }
        return adaptiveAccent(hue: 0.62)
    }

    private func adaptiveAccent(hue: Double) -> Color {
        Color(
            hue: hue,
            saturation: colorScheme == .dark ? 0.48 : 0.66,
            brightness: colorScheme == .dark ? 0.88 : 0.48
        )
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 9) {
            HStack(spacing: 9) {
                Capsule()
                    .fill(accent)
                    .frame(width: 4, height: 22 * fontScale)
                Text(section.title)
                    .font(.system(size: 17 * fontScale, weight: .bold))
                    .foregroundStyle(.primary)
                Spacer()
                Text("\(section.items.count)")
                    .font(.system(size: 12 * fontScale, weight: .bold, design: .rounded))
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(Color.primary.opacity(0.07), in: Capsule())
            }
            ForEach(section.items) { item in
                HStack(alignment: .firstTextBaseline, spacing: 10) {
                    Text(item.title)
                        .font(.system(size: max(15, 15 * fontScale), weight: .medium))
                        .foregroundStyle(.primary)
                        .lineLimit(2)
                    Spacer(minLength: 8)
                    Text(item.keys)
                        .font(.system(size: max(16, 16 * fontScale), weight: .bold, design: .rounded))
                        .foregroundStyle(.primary)
                        .padding(.horizontal, 9)
                        .padding(.vertical, 5)
                        .background(Color.primary.opacity(0.075), in: RoundedRectangle(cornerRadius: 7))
                        .overlay {
                            RoundedRectangle(cornerRadius: 7)
                                .stroke(accent.opacity(0.38), lineWidth: 1)
                        }
                }
                .padding(.vertical, 1)
            }
        }
        .padding(17)
        .frame(maxWidth: .infinity, alignment: .topLeading)
        .background(Color.primary.opacity(0.035), in: RoundedRectangle(cornerRadius: 16))
        .overlay {
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.primary.opacity(0.11), lineWidth: 1)
        }
    }
}
