import Foundation
import Supabase

// MARK: - WeightLogService
//
// @MainActor singleton that stores weight entries in UserDefaults and attempts
// Supabase sync for each new entry. Pattern mirrors FoodLogService.

@MainActor
final class WeightLogService: ObservableObject {
    static let shared = WeightLogService()

    /// All weight entries, sorted newest first.
    @Published private(set) var entries: [WeightEntry] = []

    private let client = SupabaseManager.shared.client
    private let storageKey = "caltracker_weight_log_v1"

    private static let encoder: JSONEncoder = {
        let e = JSONEncoder()
        e.dateEncodingStrategy = .iso8601
        return e
    }()

    private static let decoder: JSONDecoder = {
        let d = JSONDecoder()
        d.dateDecodingStrategy = .iso8601
        return d
    }()

    private init() {
        loadFromDisk()
    }

    // MARK: - Logging

    /// Log (or replace) today's weight entry.
    func log(weight: Double, date: Date = .now) {
        let dateStr = dateString(date)
        // Replace any existing entry for the same date (one entry per day).
        entries.removeAll { $0.date == dateStr }
        // userId is a placeholder for local storage; Supabase sync uses the real session ID.
        let entry = WeightEntry(id: UUID(), userId: UUID(), weight: weight, date: dateStr)
        entries.append(entry)
        entries.sort { $0.date > $1.date }
        saveToDisk()
        Task { try? await syncToSupabase(weight: weight, date: date) }
    }

    func delete(_ entry: WeightEntry) {
        entries.removeAll { $0.id == entry.id }
        saveToDisk()
    }

    // MARK: - Queries

    var latestEntry: WeightEntry? { entries.first }

    /// Returns entries within the last `days` calendar days, sorted oldest → newest.
    func recentEntries(days: Int) -> [WeightEntry] {
        let cal = Calendar.current
        guard let cutoff = cal.date(byAdding: .day, value: -(days - 1), to: cal.startOfDay(for: .now)) else {
            return []
        }
        let cutoffStr = dateString(cutoff)
        return entries
            .filter { $0.date >= cutoffStr }
            .sorted { $0.date < $1.date }
    }

    // MARK: - Persistence (UserDefaults)

    private func saveToDisk() {
        guard let data = try? Self.encoder.encode(entries) else { return }
        UserDefaults.standard.set(data, forKey: storageKey)
    }

    private func loadFromDisk() {
        guard
            let data = UserDefaults.standard.data(forKey: storageKey),
            let saved = try? Self.decoder.decode([WeightEntry].self, from: data)
        else { return }
        entries = saved.sorted { $0.date > $1.date }
    }

    // MARK: - Supabase sync

    private func syncToSupabase(weight: Double, date: Date) async throws {
        guard let userId = try? await client.auth.session.user.id else { return }
        let insert = WeightEntryInsert(userId: userId.uuidString, weight: weight, date: dateString(date))
        try await client.from("weight_log").insert(insert).execute()
    }

    // MARK: - Helpers

    private func dateString(_ date: Date) -> String {
        let fmt = DateFormatter()
        fmt.locale = Locale(identifier: "en_US_POSIX")
        fmt.dateFormat = "yyyy-MM-dd"
        return fmt.string(from: date)
    }
}
