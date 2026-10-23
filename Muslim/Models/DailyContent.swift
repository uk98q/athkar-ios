import Foundation

/// A dua from the authentic Prophetic supplications, with the hadith collection it is reported in.
struct DailyDua: Hashable {
    let text: String
    let source: String
}

/// One verse of the Hafs text, with its surah and ayah numbers.
struct DailyVerse: Hashable {
    let surah: Int
    let surahName: String
    let ayah: Int
    let text: String
}

/// Picks the verse and dua of the day deterministically from the local calendar date,
/// so every day shows the same content on every launch, and consecutive days differ.
enum DailyContent {
    static let duas: [DailyDua] = [
        DailyDua(text: "اللهم إني أسألك علما نافعا، ورزقا طيبا، وعملا متقبلا",
                 source: "رواه ابن ماجه، وصححه الألباني"),
        DailyDua(text: "اللهم اهدني وسددني",
                 source: "رواه مسلم"),
        DailyDua(text: "اللهم إني أعوذ بك من الهم والحزن، والعجز والكسل، والبخل والجبن، وضلع الدين وغلبة الرجال",
                 source: "رواه البخاري"),
        DailyDua(text: "اللهم أصلح لي ديني الذي هو عصمة أمري، وأصلح لي دنياي التي فيها معاشي، وأصلح لي آخرتي التي فيها معادي، واجعل الحياة زيادة لي في كل خير، واجعل الموت راحة لي من كل شر",
                 source: "رواه مسلم"),
        DailyDua(text: "اللهم إني أسألك الهدى والتقى والعفاف والغنى",
                 source: "رواه مسلم"),
        DailyDua(text: "اللهم إني أعوذ بك من علم لا ينفع، ومن قلب لا يخشع، ومن نفس لا تشبع، ومن دعوة لا يستجاب لها",
                 source: "رواه مسلم"),
        DailyDua(text: "اللهم اغفر لي خطيئتي وجهلي وإسرافي في أمري، وما أنت أعلم به مني",
                 source: "متفق عليه"),
        DailyDua(text: "اللهم إني أعوذ بك من الجبن والبخل، وأعوذ بك من أن أرد إلى أرذل العمر، وأعوذ بك من فتنة الدنيا وعذاب القبر",
                 source: "رواه البخاري"),
        DailyDua(text: "اللهم إنك عفو تحب العفو فاعف عني",
                 source: "رواه الترمذي وابن ماجه"),
        DailyDua(text: "اللهم أعني على ذكرك وشكرك وحسن عبادتك",
                 source: "رواه أبو داود والنسائي")
    ]

    /// Every ayah of the bundled Hafs text, in Quran order.
    private static let allVerses: [DailyVerse] = QuranStore.shared.surahs.flatMap { surah in
        surah.ayahs.enumerated().map { index, text in
            DailyVerse(surah: surah.number, surahName: surah.name, ayah: index + 1,
                       text: text.trimmingCharacters(in: .whitespacesAndNewlines))
        }
    }

    /// Whole days since the Unix epoch in the local calendar, taken at local noon to avoid DST edges.
    static func dayKey(_ date: Date = Date(), calendar: Calendar = .current) -> Int {
        let start = calendar.startOfDay(for: date)
        return Int(((start.timeIntervalSince1970 + 43_200) / 86_400).rounded(.down))
    }

    static func dua(for date: Date = Date()) -> DailyDua {
        let count = duas.count
        let index = ((dayKey(date) % count) + count) % count
        return duas[index]
    }

    static func verse(for date: Date = Date()) -> DailyVerse {
        guard !allVerses.isEmpty else {
            return DailyVerse(surah: 1, surahName: "الفاتحة", ayah: 1, text: "بِسْمِ ٱللَّهِ ٱلرَّحْمَـٰنِ ٱلرَّحِيمِ")
        }
        let count = allVerses.count
        let index = ((dayKey(date) % count) + count) % count
        return allVerses[index]
    }
}
