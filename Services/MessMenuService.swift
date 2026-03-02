import Foundation

// MARK: - MessMenuService
//
// Loads weekly mess menu data from bundled JSON files.
// Falls back gracefully if a file is missing.
// Phase 4 can extend this to also read/write from Supabase mess_menus table.

@MainActor
final class MessMenuService: ObservableObject {
    static let shared = MessMenuService()

    // Simple in-memory cache so JSON is only parsed once per session.
    private var cache: [Int: [LocalMenuEntry]] = [:]

    private init() {}

    // MARK: - Load a full week

    func loadMenu(weekNumber: Int) -> [LocalMenuEntry] {
        if let cached = cache[weekNumber] { return cached }
        let entries = parseJSON(weekNumber: weekNumber)
        cache[weekNumber] = entries
        return entries
    }

    private func parseJSON(weekNumber: Int) -> [LocalMenuEntry] {
        let filename = "MessMenuWeek\(weekNumber)"
        guard
            let url  = Bundle.main.url(forResource: filename, withExtension: "json"),
            let data = try? Data(contentsOf: url)
        else { return [] }

        return (try? JSONDecoder().decode([LocalMenuEntry].self, from: data)) ?? []
    }

    // MARK: - Today's entries

    /// All LocalMenuEntry objects for today (all meal types).
    func todaysEntries(for date: Date = Date()) -> [LocalMenuEntry] {
        let weekNum = WeekResolver.weekNumber(for: date)
        let day     = WeekResolver.dayOfWeek(for: date).rawValue
        return loadMenu(weekNumber: weekNum).filter { $0.dayOfWeek == day }
    }

    /// Items for a specific meal type today.
    func todaysItems(mealType: MealType, for date: Date = Date()) -> [LocalMenuItem] {
        todaysEntries(for: date)
            .filter { $0.mealType == mealType.rawValue }
            .flatMap { $0.items }
    }

    // MARK: - Week data organised by day → mealType

    /// Returns [dayOfWeek raw value → [MealType → [LocalMenuItem]]] for the week.
    func weeklyMenu(for date: Date = Date()) -> [String: [MealType: [LocalMenuItem]]] {
        let weekNum = WeekResolver.weekNumber(for: date)
        let entries = loadMenu(weekNumber: weekNum)

        var result: [String: [MealType: [LocalMenuItem]]] = [:]
        for entry in entries {
            if result[entry.dayOfWeek] == nil { result[entry.dayOfWeek] = [:] }
            if let mealType = MealType(rawValue: entry.mealType) {
                result[entry.dayOfWeek]![mealType] = entry.items
            }
        }
        return result
    }

    // MARK: - Items for a specific day + meal

    func items(day: DayOfWeek, mealType: MealType, weekNumber: Int) -> [LocalMenuItem] {
        loadMenu(weekNumber: weekNumber)
            .filter { $0.dayOfWeek == day.rawValue && $0.mealType == mealType.rawValue }
            .flatMap { $0.items }
    }
}
