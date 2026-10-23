import Foundation

/// One run of words of a verse on a mushaf line. `t` holds words separated by single spaces.
struct MushafItem: Decodable, Hashable {
    let t: String
    let s: Int
    let a: Int
    let e: Int
}

/// `k`: "t" text line, "s" surah header, "b" basmala, "x" blank line.
struct MushafLine: Decodable {
    let k: String
    let surah: Int?
    let items: [MushafItem]?
}

struct MushafPage: Decodable, Identifiable {
    let n: Int
    let juz: Int
    let hizb: Int
    let q: Int
    let lines: [MushafLine]

    var id: Int { n }

    /// Surah of the first verse on the page, used for the header name.
    var leadSurah: Int {
        for line in lines {
            if line.k == "s", let s = line.surah { return s }
            if let first = line.items?.first { return first.s }
        }
        return 1
    }
}

private struct MushafFile: Decodable {
    let pages: [MushafPage]
}

/// 604-page Madani layout. Layout from quran.com; text from Tanzil (Hafs, Uthmani), CC BY 3.0.
final class MushafStore {
    static let shared = MushafStore()

    let pages: [MushafPage]
    private var surahStartPage: [Int: Int] = [:]
    private var ayahStartPage: [Int: Int] = [:]

    static let juzNames = [
        "الجزء الأول", "الجزء الثاني", "الجزء الثالث", "الجزء الرابع", "الجزء الخامس",
        "الجزء السادس", "الجزء السابع", "الجزء الثامن", "الجزء التاسع", "الجزء العاشر",
        "الجزء الحادي عشر", "الجزء الثاني عشر", "الجزء الثالث عشر", "الجزء الرابع عشر",
        "الجزء الخامس عشر", "الجزء السادس عشر", "الجزء السابع عشر", "الجزء الثامن عشر",
        "الجزء التاسع عشر", "الجزء العشرون", "الجزء الحادي والعشرون", "الجزء الثاني والعشرون",
        "الجزء الثالث والعشرون", "الجزء الرابع والعشرون", "الجزء الخامس والعشرون",
        "الجزء السادس والعشرون", "الجزء السابع والعشرون", "الجزء الثامن والعشرون",
        "الجزء التاسع والعشرون", "الجزء الثلاثون"
    ]

    private init() {
        var loaded: [MushafPage] = []
        if let url = Bundle.main.url(forResource: "mushaf-pages", withExtension: "json"),
           let data = try? Data(contentsOf: url),
           let file = try? JSONDecoder().decode(MushafFile.self, from: data) {
            loaded = file.pages
        }
        pages = loaded
        for page in loaded {
            for line in page.lines {
                if line.k == "s", let s = line.surah, surahStartPage[s] == nil {
                    surahStartPage[s] = page.n
                }
                for item in line.items ?? [] {
                    let key = item.s * 1000 + item.a
                    if ayahStartPage[key] == nil { ayahStartPage[key] = page.n }
                }
            }
        }
    }

    func startPage(of surah: Int) -> Int {
        surahStartPage[surah] ?? 1
    }

    func page(of surah: Int, ayah: Int) -> Int {
        ayahStartPage[surah * 1000 + ayah] ?? startPage(of: surah)
    }

    func juzName(for page: MushafPage) -> String {
        let index = min(max(page.juz - 1, 0), MushafStore.juzNames.count - 1)
        return MushafStore.juzNames[index]
    }
}
