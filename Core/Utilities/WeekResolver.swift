import Foundation

// MARK: - WeekResolver
//
// Maps any date to the Royal Foods mess week number (1, 2, or 3).
//
// Anchor schedule:
//   Week 3 (IMG3) → Feb 16-22, 2026
//   Week 2 (IMG2) → Feb 23-Mar 1, 2026
//   Week 1 (IMG1) → Mar 2-8, 2026
// Then the 3-week cycle repeats: 3 → 2 → 1 → 3 → ...

enum WeekResolver {

    // Anchor: Monday, Feb 16, 2026 = start of the Week 3 block.
    private static let anchorMonday: Date = {
        var comps = DateComponents()
        comps.year   = 2026
        comps.month  = 2
        comps.day    = 16
        comps.hour   = 0
        comps.minute = 0
        comps.second = 0
        return Calendar.current.date(from: comps)!
    }()

    // The mess cycle order starting from the anchor: 3, 2, 1, 3, 2, 1, …
    private static let weekCycle = [3, 2, 1]

    // MARK: - Public API

    /// Returns the mess week number (1, 2, or 3) for the given date.
    static func weekNumber(for date: Date = Date()) -> Int {
        let monday = startOfMessWeek(for: date)
        let days   = Calendar.current.dateComponents([.day], from: anchorMonday, to: monday).day ?? 0
        let weeks  = days / 7
        // Use modulo with positive correction for dates before the anchor
        let index  = ((weeks % 3) + 3) % 3
        return weekCycle[index]
    }

    /// Returns the Monday that starts the mess week containing `date`.
    static func startOfMessWeek(for date: Date = Date()) -> Date {
        var cal = Calendar.current
        cal.firstWeekday = 2    // Monday
        let comps = cal.dateComponents([.yearForWeekOfYear, .weekOfYear], from: date)
        return cal.date(from: comps) ?? date
    }

    /// Returns all 7 dates (Mon–Sun) of the mess week containing `date`.
    static func datesOfMessWeek(for date: Date = Date()) -> [Date] {
        let monday = startOfMessWeek(for: date)
        return (0..<7).compactMap { offset in
            Calendar.current.date(byAdding: .day, value: offset, to: monday)
        }
    }

    /// Returns the `DayOfWeek` enum value for a given date.
    static func dayOfWeek(for date: Date = Date()) -> DayOfWeek {
        DayOfWeek.from(date: date)
    }

    /// Convenience: returns (weekNumber, dayOfWeek) tuple for a given date.
    static func resolve(date: Date = Date()) -> (week: Int, day: DayOfWeek) {
        (weekNumber(for: date), dayOfWeek(for: date))
    }
}
