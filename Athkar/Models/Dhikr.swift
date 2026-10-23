import SwiftUI

struct Dhikr: Identifiable, Hashable {
    let id: String
    let text: String
    let target: Int
}

enum Period: String, CaseIterable, Identifiable, Hashable {
    case morning
    case evening

    var id: String { rawValue }

    var title: String {
        switch self {
        case .morning: return "أذكار الصباح"
        case .evening: return "أذكار المساء"
        }
    }

    var subtitle: String {
        switch self {
        case .morning: return "ابدأ يومك بذكر الله"
        case .evening: return "اختم يومك بذكر الله"
        }
    }

    var symbol: String {
        switch self {
        case .morning: return "sun.max.fill"
        case .evening: return "moon.stars.fill"
        }
    }

    var accent: Color {
        switch self {
        case .morning: return Theme.morningAccent
        case .evening: return Theme.eveningAccent
        }
    }

    var items: [Dhikr] {
        switch self {
        case .morning: return AthkarData.morning
        case .evening: return AthkarData.evening
        }
    }
}
