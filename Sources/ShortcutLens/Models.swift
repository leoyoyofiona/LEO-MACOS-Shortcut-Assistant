import Foundation
import CoreGraphics

struct ShortcutItem: Identifiable, Hashable {
    let id = UUID()
    let title: String
    let keys: String
}

struct ShortcutSection: Identifiable, Hashable {
    let id = UUID()
    let title: String
    let items: [ShortcutItem]
}

enum PanelPosition: String, CaseIterable, Identifiable {
    case center = "屏幕中央"
    case top = "顶部中央"
    case topRight = "右上角"
    case bottomRight = "右下角"

    var id: String { rawValue }
}

enum TriggerKey: String, CaseIterable, Identifiable {
    case leftControl
    case rightControl
    case leftOption
    case rightOption
    case leftCommand
    case rightCommand
    case function

    var id: String { rawValue }

    var keyCode: Int64 {
        switch self {
        case .leftControl: return 59
        case .rightControl: return 62
        case .leftOption: return 58
        case .rightOption: return 61
        case .leftCommand: return 55
        case .rightCommand: return 54
        case .function: return 63
        }
    }

    var eventFlag: CGEventFlags {
        switch self {
        case .leftControl, .rightControl: return .maskControl
        case .leftOption, .rightOption: return .maskAlternate
        case .leftCommand, .rightCommand: return .maskCommand
        case .function: return .maskSecondaryFn
        }
    }

    var chineseName: String {
        switch self {
        case .leftControl: return "左 Control"
        case .rightControl: return "右 Control"
        case .leftOption: return "左 Option"
        case .rightOption: return "右 Option"
        case .leftCommand: return "左 Command"
        case .rightCommand: return "右 Command"
        case .function: return "Fn"
        }
    }

    var englishName: String {
        switch self {
        case .leftControl: return "Left Control"
        case .rightControl: return "Right Control"
        case .leftOption: return "Left Option"
        case .rightOption: return "Right Option"
        case .leftCommand: return "Left Command"
        case .rightCommand: return "Right Command"
        case .function: return "Fn"
        }
    }

    static var selected: TriggerKey {
        let raw = UserDefaults.standard.string(forKey: "triggerKey") ?? TriggerKey.leftControl.rawValue
        return TriggerKey(rawValue: raw) ?? .leftControl
    }
}

struct ShortcutSnapshot {
    let appName: String
    let bundleIdentifier: String?
    let sections: [ShortcutSection]
}
