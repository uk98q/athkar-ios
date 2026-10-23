import Foundation

/// Hafs 'an 'Asim, Uthmani script. Text from the Tanzil Project (CC BY 3.0), bundled unchanged.
struct QuranSurah: Identifiable, Hashable, Decodable {
    let number: Int
    let name: String
    let revelation: String
    let ayahCount: Int
    let ayahs: [String]

    var id: Int { number }

    var revelationLabel: String {
        revelation == "makkah" ? "مكية" : "مدنية"
    }
}

private struct QuranFile: Decodable {
    let surahs: [QuranSurah]
}

/// Loads the bundled Quran once, on first use.
final class QuranStore: ObservableObject {
    static let shared = QuranStore()

    let surahs: [QuranSurah]

    private init() {
        var loaded: [QuranSurah] = []
        if let url = Bundle.main.url(forResource: "quran-hafs-uthmani", withExtension: "json"),
           let data = try? Data(contentsOf: url),
           let file = try? JSONDecoder().decode(QuranFile.self, from: data) {
            loaded = file.surahs
        }
        surahs = loaded
    }

    func surah(_ number: Int) -> QuranSurah? {
        surahs.first { $0.number == number }
    }
}

enum Reciter: Int, CaseIterable, Identifiable {
    case alafasy, basit, sudais, ghamidi, maher, yasser

    var id: Int { rawValue }

    var name: String {
        switch self {
        case .alafasy: return "مشاري راشد العفاسي"
        case .basit: return "عبد الباسط عبد الصمد (مرتل)"
        case .sudais: return "عبد الرحمن السديس"
        case .ghamidi: return "سعد الغامدي"
        case .maher: return "ماهر المعيقلي"
        case .yasser: return "ياسر الدوسري"
        }
    }

    /// Folder names on everyayah.com (verified: each returns an MP3 for 2:255).
    var folder: String {
        switch self {
        case .alafasy: return "Alafasy_128kbps"
        case .basit: return "Abdul_Basit_Murattal_192kbps"
        case .sudais: return "Abdurrahmaan_As-Sudais_192kbps"
        case .ghamidi: return "Ghamadi_40kbps"
        case .maher: return "MaherAlMuaiqly128kbps"
        case .yasser: return "Yasser_Ad-Dussary_128kbps"
        }
    }

    func url(surah: Int, ayah: Int) -> URL {
        let s = String(format: "%03d", surah)
        let a = String(format: "%03d", ayah)
        return URL(string: "https://everyayah.com/data/\(folder)/\(s)\(a).mp3")!
    }

    static func from(_ raw: Int) -> Reciter {
        Reciter(rawValue: raw) ?? .alafasy
    }
}

/// Eastern Arabic-Indic digits for ayah numbers.
func arabicDigits(_ value: Int) -> String {
    let map: [Character: Character] = [
        "0": "٠", "1": "١", "2": "٢", "3": "٣", "4": "٤",
        "5": "٥", "6": "٦", "7": "٧", "8": "٨", "9": "٩"
    ]
    return String(String(value).map { map[$0] ?? $0 })
}
