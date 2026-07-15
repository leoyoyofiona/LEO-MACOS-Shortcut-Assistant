import Foundation

enum DisplayLanguage: String, CaseIterable, Identifiable {
    case chinese = "zh-Hans"
    case english = "en"

    var id: String { rawValue }
}

enum PanelLocalization {
    private static let pairs: [(String, String)] = [
        ("文件", "File"), ("编辑", "Edit"), ("显示", "View"), ("视图", "View"),
        ("窗口", "Window"), ("帮助", "Help"), ("前往", "Go"), ("格式", "Format"),
        ("历史记录", "History"), ("书签", "Bookmarks"), ("标签页", "Tab"), ("工具", "Tools"),
        ("常用", "Common"), ("正在读取", "Loading"),
        ("关于", "About"), ("设置", "Settings"), ("偏好设置", "Preferences"),
        ("服务", "Services"), ("隐藏", "Hide"), ("隐藏其他", "Hide Others"),
        ("全部显示", "Show All"), ("退出", "Quit"),
        ("新建", "New"), ("新建窗口", "New Window"), ("新建标签页", "New Tab"),
        ("打开", "Open"), ("打开最近使用", "Open Recent"), ("关闭", "Close"),
        ("关闭窗口", "Close Window"), ("关闭标签页", "Close Tab"),
        ("保存", "Save"), ("另存为", "Save As"), ("复制副本", "Duplicate"),
        ("重新命名", "Rename"), ("移到", "Move To"), ("复原到", "Revert To"),
        ("页面设置", "Page Setup"), ("打印", "Print"),
        ("撤销", "Undo"), ("重做", "Redo"), ("剪切", "Cut"), ("复制", "Copy"),
        ("粘贴", "Paste"), ("粘贴并匹配样式", "Paste and Match Style"),
        ("删除", "Delete"), ("全选", "Select All"),
        ("查找", "Find"), ("查找下一个", "Find Next"), ("查找上一个", "Find Previous"),
        ("替换", "Replace"), ("拼写和语法", "Spelling and Grammar"),
        ("开始听写", "Start Dictation"), ("表情与符号", "Emoji & Symbols"),
        ("最小化", "Minimize"), ("缩放", "Zoom"), ("进入全屏幕", "Enter Full Screen"),
        ("退出全屏幕", "Exit Full Screen"), ("前置全部窗口", "Bring All to Front"),
        ("返回", "Back"), ("前进", "Forward"), ("重新载入", "Reload"),
        ("停止", "Stop"), ("实际大小", "Actual Size"), ("放大", "Zoom In"), ("缩小", "Zoom Out"),
        ("下载", "Downloads"), ("添加书签", "Add Bookmark"), ("显示边栏", "Show Sidebar"),
        ("隐藏边栏", "Hide Sidebar"), ("检查器", "Inspector"), ("开发者工具", "Developer Tools"),
        ("上一个标签页", "Previous Tab"), ("下一个标签页", "Next Tab"),
        ("强制退出", "Force Quit"), ("锁定屏幕", "Lock Screen"), ("退出登录", "Sign Out"),
        ("全部最小化", "Minimize All"), ("填充", "Fill"), ("居中", "Center"),
        ("左侧", "Left"), ("右侧", "Right"), ("顶部", "Top"), ("底部", "Bottom"),
        ("正在读取这个应用的菜单快捷键", "Reading this app's menu shortcuts")
    ]

    private static let chineseToEnglish = Dictionary(uniqueKeysWithValues: pairs)
    private static let englishToChinese: [String: String] = {
        var result: [String: String] = [:]
        for (chinese, english) in pairs where result[english.lowercased()] == nil {
            result[english.lowercased()] = chinese
        }
        return result
    }()

    static func text(_ source: String, language: DisplayLanguage) -> String {
        let (base, suffix) = splitEllipsis(source)
        switch language {
        case .chinese:
            if let translated = englishToChinese[base.lowercased()] { return translated + suffix }
            return translateEnglishPrefix(base) + suffix
        case .english:
            if let translated = chineseToEnglish[base] { return translated + suffix }
            return translateChinesePrefix(base) + suffix
        }
    }

    static func needsMachineTranslation(_ source: String, language: DisplayLanguage) -> Bool {
        let candidate = text(source, language: language)
        switch language {
        case .chinese:
            if containsChinese(candidate) || isLikelyProperName(candidate) { return false }
            return candidate.range(of: "[A-Za-z]", options: .regularExpression) != nil
        case .english:
            return containsChinese(candidate)
        }
    }

    static func isValidTargetText(_ value: String, language: DisplayLanguage) -> Bool {
        switch language {
        case .chinese:
            return containsChinese(value) || isLikelyProperName(value)
        case .english:
            return !containsChinese(value)
        }
    }

    static func cachedTranslations(language: DisplayLanguage) -> [String: String] {
        UserDefaults.standard.dictionary(forKey: cacheKey(language)) as? [String: String] ?? [:]
    }

    static func saveTranslations(_ translations: [String: String], language: DisplayLanguage) {
        var cache = cachedTranslations(language: language)
        cache.merge(translations) { _, new in new }
        UserDefaults.standard.set(cache, forKey: cacheKey(language))
    }

    private static func cacheKey(_ language: DisplayLanguage) -> String {
        "automaticTranslationCache.\(language.rawValue)"
    }

    private static func containsChinese(_ value: String) -> Bool {
        value.range(of: "[\\u{3400}-\\u{9FFF}]", options: .regularExpression) != nil
    }

    private static func isLikelyProperName(_ value: String) -> Bool {
        guard !value.contains(where: { $0.isWhitespace }), value.count <= 30 else { return false }
        let letters = value.filter(\.isLetter)
        guard !letters.isEmpty else { return true }
        let uppercaseCount = letters.filter(\.isUppercase).count
        return uppercaseCount >= 2 || value.contains(where: \.isNumber)
    }

    private static func splitEllipsis(_ value: String) -> (String, String) {
        if value.hasSuffix("…") { return (String(value.dropLast()), "…") }
        if value.hasSuffix("...") { return (String(value.dropLast(3)), "…") }
        return (value, "")
    }

    private static func translateEnglishPrefix(_ value: String) -> String {
        let prefixes = [("About ", "关于 "), ("Quit ", "退出 "), ("Hide ", "隐藏 ")]
        for (source, target) in prefixes where value.hasPrefix(source) {
            return target + String(value.dropFirst(source.count))
        }
        return value
    }

    private static func translateChinesePrefix(_ value: String) -> String {
        let prefixes = [
            ("强制退出", "Force Quit "), ("退出登录", "Sign Out "),
            ("关于", "About "), ("退出", "Quit "), ("隐藏", "Hide ")
        ]
        for (source, target) in prefixes where value.hasPrefix(source) && value.count > source.count {
            return target + String(value.dropFirst(source.count))
        }
        return value
    }
}
