import Foundation
import Supabase

// MARK: - LoggedItem
// Unified log entry that can represent either a database Food or a LocalMenuItem.
// All nutritional values are stored inline so the entry is self-contained.

struct LoggedItem: Codable, Identifiable, Hashable {
    let id: UUID
    let name: String
    let calories: Double       // calories per single serving (base unit)
    let protein: Double
    let carbs: Double
    let fat: Double
    let servings: Double
    let servingUnit: String
    let mealType: MealType
    let date: String           // "YYYY-MM-DD"
    let timestamp: Date
    let foodId: UUID?          // nil for mess-menu / inline items (no Supabase UUID)

    // MARK: - Computed totals

    var totalCalories: Double { calories * servings }
    var totalProtein: Double  { protein  * servings }
    var totalCarbs: Double    { carbs    * servings }
    var totalFat: Double      { fat      * servings }

    var servingDescription: String {
        let count = servings == 1.0 ? "1" : String(format: "%g", servings)
        return "\(count) \(servingUnit)"
    }
}

// MARK: - FoodLogService

@MainActor
final class FoodLogService: ObservableObject {
    static let shared = FoodLogService()

    /// Today's items, updated whenever anything is logged or deleted.
    @Published private(set) var todaysItems: [LoggedItem] = []

    private var allItems: [LoggedItem] = []
    private let client = SupabaseManager.shared.client
    private let storageURL: URL = {
        let dir = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        return dir.appendingPathComponent("caltracker_food_log_v1.json")
    }()

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
        refreshToday()
    }

    // MARK: - Logging

    /// Log a food-database item with a chosen serving count.
    func log(food: Food, servings: Double, mealType: MealType, date: Date = .now) {
        let item = LoggedItem(
            id: UUID(),
            name: food.name,
            calories: food.caloriesPerServing,
            protein: food.protein,
            carbs: food.carbs,
            fat: food.fat,
            servings: servings,
            servingUnit: food.servingUnit,
            mealType: mealType,
            date: dateString(date),
            timestamp: date,
            foodId: food.id
        )
        append(item)
        Task { try? await syncToSupabase(foodId: food.id, servings: servings, mealType: mealType, date: date) }
    }

    /// Log a mess-menu item (no Supabase food UUID — stored locally only).
    func log(menuItem: LocalMenuItem, mealType: MealType, date: Date = .now) {
        let item = LoggedItem(
            id: UUID(),
            name: menuItem.name,
            calories: menuItem.calories,
            protein: menuItem.protein,
            carbs: menuItem.carbs,
            fat: menuItem.fat,
            servings: 1.0,
            servingUnit: menuItem.servingUnit,
            mealType: mealType,
            date: dateString(date),
            timestamp: date,
            foodId: nil
        )
        append(item)
    }

    /// Remove a logged entry.
    func delete(_ item: LoggedItem) {
        allItems.removeAll { $0.id == item.id }
        saveToDisk()
        refreshToday()
    }

    // MARK: - Queries

    func items(for date: Date) -> [LoggedItem] {
        allItems.filter { $0.date == dateString(date) }
    }

    func items(for date: Date, mealType: MealType) -> [LoggedItem] {
        items(for: date).filter { $0.mealType == mealType }
    }

    /// Last 20 unique foods (database entries only, so we can reconstruct a Food for re-logging).
    var recentFoods: [Food] {
        var seen = Set<UUID>()
        var result: [LoggedItem] = []
        for item in allItems.reversed() {
            guard let fid = item.foodId, !seen.contains(fid) else { continue }
            seen.insert(fid)
            result.append(item)
            if result.count == 20 { break }
        }
        return result.compactMap { item in
            guard let fid = item.foodId else { return nil }
            return FoodService.shared.localFoods.first { $0.id == fid }
                ?? syntheticFood(from: item, id: fid)
        }
    }

    // MARK: - Private Helpers

    private func append(_ item: LoggedItem) {
        allItems.append(item)
        saveToDisk()
        refreshToday()
    }

    private func refreshToday() {
        todaysItems = items(for: .now)
    }

    private func dateString(_ date: Date) -> String {
        let fmt = DateFormatter()
        fmt.locale = Locale(identifier: "en_US_POSIX")
        fmt.dateFormat = "yyyy-MM-dd"
        return fmt.string(from: date)
    }

    // MARK: - Persistence (encrypted file storage)

    private func saveToDisk() {
        guard let data = try? Self.encoder.encode(allItems) else { return }
        let dir = storageURL.deletingLastPathComponent()
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        try? data.write(to: storageURL, options: [.atomic, .completeFileProtection])
    }

    private func loadFromDisk() {
        guard
            let data = try? Data(contentsOf: storageURL),
            let items = try? Self.decoder.decode([LoggedItem].self, from: data)
        else { return }
        allItems = items
    }

    // MARK: - Supabase Sync

    private func syncToSupabase(foodId: UUID, servings: Double, mealType: MealType, date: Date) async throws {
        guard let userId = try? await client.auth.session.user.id else { return }
        let insert = FoodLogInsert(
            userId: userId.uuidString,
            foodId: foodId.uuidString,
            mealType: mealType.rawValue,
            servings: servings,
            date: dateString(date),
            timestamp: date
        )
        try await client.from("food_log").insert(insert).execute()
    }

    // MARK: - Synthetic Food fallback

    /// Reconstruct a Food from a LoggedItem when the local JSON doesn't have it.
    private func syntheticFood(from item: LoggedItem, id: UUID) -> Food {
        Food(
            id: id,
            name: item.name,
            caloriesPerServing: item.calories,
            protein: item.protein,
            carbs: item.carbs,
            fat: item.fat,
            servingUnit: item.servingUnit,
            servingSize: 1.0,
            category: .outside,
            isCustom: false,
            createdBy: nil
        )
    }
}
