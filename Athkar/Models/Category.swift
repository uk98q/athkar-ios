import SwiftUI

enum AthkarCategory: String, CaseIterable, Identifiable, Hashable {
    case morning
    case evening
    case afterPrayer
    case sleep
    case wakeUp
    case travel
    case duas

    var id: String { rawValue }

    var title: String {
        switch self {
        case .morning: return "أذكار الصباح"
        case .evening: return "أذكار المساء"
        case .afterPrayer: return "بعد الصلاة"
        case .sleep: return "أذكار النوم"
        case .wakeUp: return "عند الاستيقاظ"
        case .travel: return "دعاء السفر"
        case .duas: return "أدعية متنوعة"
        }
    }

    var subtitle: String {
        switch self {
        case .morning: return "ابدأ يومك بذكر الله"
        case .evening: return "اختم يومك بذكر الله"
        case .afterPrayer: return "تسبيح وأذكار بعد السلام"
        case .sleep: return "قبل أن تنام"
        case .wakeUp: return "أول ما تستيقظ"
        case .travel: return "للمسافر وفي الطريق"
        case .duas: return "أدعية جامعة مأثورة"
        }
    }

    var symbol: String {
        switch self {
        case .morning: return "sun.max.fill"
        case .evening: return "moon.fill"
        case .afterPrayer: return "checkmark.seal.fill"
        case .sleep: return "bed.double.fill"
        case .wakeUp: return "alarm.fill"
        case .travel: return "airplane"
        case .duas: return "sparkles"
        }
    }

    var accent: Color {
        switch self {
        case .morning: return Theme.dawn
        case .evening: return Theme.dusk
        case .afterPrayer: return Theme.mint
        case .sleep: return Theme.dusk
        case .wakeUp: return Theme.dawn
        case .travel: return Theme.mint
        case .duas: return Theme.dawn
        }
    }

    var items: [Dhikr] {
        switch self {
        case .morning: return AthkarData.morning
        case .evening: return AthkarData.evening
        case .afterPrayer: return AthkarData.afterPrayer
        case .sleep: return AthkarData.sleep
        case .wakeUp: return AthkarData.wakeUp
        case .travel: return AthkarData.travel
        case .duas: return AthkarData.duas
        }
    }
}
