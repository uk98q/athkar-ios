import Foundation
import SwiftUI

/// Stores today's counter values on the device only (UserDefaults).
/// Keys look like "2026-10-23|morning|m01" and old days are dropped on load.
final class ProgressStore: ObservableObject {
    @Published private(set) var counts: [String: Int] = [:]

    private let storageKey = "athkar.progress.v1"

    private static let dayFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()

    init() {
        load()
    }

    private var todayPrefix: String {
        Self.dayFormatter.string(from: Date()) + "|"
    }

    private func key(_ period: Period, _ id: String) -> String {
        todayPrefix + period.rawValue + "|" + id
    }

    func count(_ period: Period, _ id: String) -> Int {
        counts[key(period, id)] ?? 0
    }

    func tap(_ period: Period, _ dhikr: Dhikr) {
        let k = key(period, dhikr.id)
        let current = counts[k] ?? 0
        guard current < dhikr.target else { return }
        counts[k] = current + 1
        save()
    }

    func resetItem(_ period: Period, _ dhikr: Dhikr) {
        counts[key(period, dhikr.id)] = nil
        save()
    }

    func resetPeriod(_ period: Period) {
        let prefix = todayPrefix + period.rawValue + "|"
        counts = counts.filter { !$0.key.hasPrefix(prefix) }
        save()
    }

    /// Fraction of the whole set completed, weighted by each item's target.
    func progress(_ period: Period) -> Double {
        let items = period.items
        let total = items.reduce(0) { $0 + $1.target }
        guard total > 0 else { return 0 }
        let done = items.reduce(0) { $0 + min(count(period, $1.id), $1.target) }
        return Double(done) / Double(total)
    }

    private func load() {
        guard let data = UserDefaults.standard.data(forKey: storageKey),
              let saved = try? JSONDecoder().decode([String: Int].self, from: data) else { return }
        let prefix = todayPrefix
        counts = saved.filter { $0.key.hasPrefix(prefix) }
    }

    private func save() {
        if let data = try? JSONEncoder().encode(counts) {
            UserDefaults.standard.set(data, forKey: storageKey)
        }
    }
}
