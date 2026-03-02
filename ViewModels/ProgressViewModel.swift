import Foundation
import Combine

// MARK: - DayCalorieData
// Lightweight snapshot used by WeeklyTrendsChart and 30-day stats.

struct DayCalorieData: Identifiable {
    let id = UUID()
    let date: Date
    let calories: Double

    var dayLabel: String {
        let fmt = DateFormatter()
        fmt.dateFormat = "EEE"
        return fmt.string(from: date)
    }

    var dateString: String {
        let fmt = DateFormatter()
        fmt.locale = Locale(identifier: "en_US_POSIX")
        fmt.dateFormat = "yyyy-MM-dd"
        return fmt.string(from: date)
    }
}

// MARK: - ProgressViewModel

@MainActor
final class ProgressViewModel: ObservableObject {

    private let weightService = WeightLogService.shared
    private let logService    = FoodLogService.shared
    private var cancellables  = Set<AnyCancellable>()

    @Published private(set) var weightEntries: [WeightEntry] = []

    // Calorie target (Phase 8 will pull from UserGoals)
    let calorieTarget: Double = 1800

    init() {
        // Mirror weight entries
        weightService.$entries
            .sink { [weak self] entries in
                self?.weightEntries = entries
            }
            .store(in: &cancellables)
        weightEntries = weightService.entries

        // Re-compute calorie stats whenever today's food log changes
        logService.$todaysItems
            .sink { [weak self] _ in self?.objectWillChange.send() }
            .store(in: &cancellables)
    }

    // MARK: - Weight

    var latestWeight: WeightEntry? { weightService.latestEntry }

    /// Net change (kg) between the oldest and newest entry in the last 30 days.
    /// Negative → weight lost.
    var weightChange30Days: Double? {
        let recent = weightService.recentEntries(days: 30)
        guard let first = recent.first, let last = recent.last, first.id != last.id else { return nil }
        return last.weight - first.weight
    }

    /// Last 30 days of weight entries, oldest → newest (for display).
    var recentWeightEntries: [WeightEntry] { weightService.recentEntries(days: 30) }

    // MARK: - Calorie history

    /// Last 7 calendar days (today included), oldest → newest.
    var last7DaysCalories: [DayCalorieData] {
        calorieData(days: 7)
    }

    /// Last 30 calendar days (today included), oldest → newest.
    var last30DaysData: [DayCalorieData] {
        calorieData(days: 30)
    }

    // MARK: - 30-Day Aggregates

    /// Number of days in the last 30 that have at least one logged item.
    var daysLoggedLast30: Int {
        last30DaysData.filter { $0.calories > 0 }.count
    }

    /// Average daily calories over logged days in the last 30.
    var avgCaloriesLast30: Double {
        let logged = last30DaysData.filter { $0.calories > 0 }
        guard !logged.isEmpty else { return 0 }
        return logged.reduce(0) { $0 + $1.calories } / Double(logged.count)
    }

    /// Average daily protein over logged days in the last 30.
    var avgProteinLast30: Double {
        let cal = Calendar.current
        var totalProtein = 0.0
        var daysLogged = 0
        for offset in 0..<30 {
            guard let date = cal.date(byAdding: .day, value: -offset, to: cal.startOfDay(for: .now)) else { continue }
            let protein = logService.items(for: date).reduce(0.0) { $0 + $1.totalProtein }
            if protein > 0 {
                totalProtein += protein
                daysLogged += 1
            }
        }
        guard daysLogged > 0 else { return 0 }
        return totalProtein / Double(daysLogged)
    }

    // MARK: - Streak

    /// Consecutive days ending today (or yesterday) with at least one logged item.
    var currentStreak: Int {
        let cal = Calendar.current
        var streak = 0
        var checkDate = cal.startOfDay(for: .now)
        while true {
            if logService.items(for: checkDate).isEmpty { break }
            streak += 1
            guard let prev = cal.date(byAdding: .day, value: -1, to: checkDate) else { break }
            checkDate = prev
        }
        return streak
    }

    /// Longest consecutive run within the last 30 days.
    var longestStreak30: Int {
        let cal = Calendar.current
        var longest = 0
        var current = 0
        for offset in (0..<30).reversed() {
            guard let date = cal.date(byAdding: .day, value: -offset, to: cal.startOfDay(for: .now)) else { continue }
            if logService.items(for: date).isEmpty {
                current = 0
            } else {
                current += 1
                longest = max(longest, current)
            }
        }
        return longest
    }

    // MARK: - Private helpers

    private func calorieData(days: Int) -> [DayCalorieData] {
        let cal = Calendar.current
        return (0..<days).reversed().compactMap { offset -> DayCalorieData? in
            guard let date = cal.date(byAdding: .day, value: -offset, to: cal.startOfDay(for: .now)) else { return nil }
            let calories = logService.items(for: date).reduce(0.0) { $0 + $1.totalCalories }
            return DayCalorieData(date: date, calories: calories)
        }
    }
}
