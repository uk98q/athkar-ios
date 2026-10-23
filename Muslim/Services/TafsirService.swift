import Foundation

/// Ibn Kathir (Arabic) tafsir from the quran.com API v4 (resource 14).
/// Public domain author (d. 774 AH); the text is shown with attribution.
actor TafsirService {
    static let shared = TafsirService()

    static let attribution = "التفسير: تفسير ابن كثير (الحافظ ابن كثير، ت 774هـ) عبر واجهة quran.com"

    private var cache: [String: String] = [:]

    private struct Response: Decodable {
        struct Body: Decodable {
            let text: String
        }
        let tafsir: Body
    }

    func text(surah: Int, ayah: Int) async throws -> String {
        let key = "\(surah):\(ayah)"
        if let cached = cache[key] {
            return cached
        }
        let url = URL(string: "https://api.quran.com/api/v4/tafsirs/14/by_ayah/\(key)")!
        var request = URLRequest(url: url)
        request.timeoutInterval = 30
        let (data, response) = try await URLSession.shared.data(for: request)
        guard (response as? HTTPURLResponse)?.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }
        let decoded = try JSONDecoder().decode(Response.self, from: data)
        let plain = TafsirService.plainText(decoded.tafsir.text)
        cache[key] = plain
        return plain
    }

    nonisolated static func plainText(_ html: String) -> String {
        var s = html.replacingOccurrences(of: "<br\\s*/?>", with: "\n", options: .regularExpression)
        s = s.replacingOccurrences(of: "</p>", with: "\n\n")
        s = s.replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression)
        let entities = [
            ("&quot;", "\""), ("&#39;", "'"), ("&lt;", "<"), ("&gt;", ">"),
            ("&nbsp;", " "), ("&amp;", "&")
        ]
        for (entity, replacement) in entities {
            s = s.replacingOccurrences(of: entity, with: replacement)
        }
        return s.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
