import Foundation

struct MessMenuEntry: Codable, Identifiable {
    let id: UUID
    let userId: UUID
    let weekNumber: Int        // 1, 2, or 3
    let dayOfWeek: DayOfWeek
    let mealType: MealType
    let foodIds: [UUID]

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case weekNumber = "week_number"
        case dayOfWeek = "day_of_week"
        case mealType = "meal_type"
        case foodIds = "food_ids"
    }
}

// MARK: - Local menu model (used with bundled JSON, no Supabase)

struct LocalMenuEntry: Codable {
    let weekNumber: Int
    let dayOfWeek: String
    let mealType: String
    let items: [LocalMenuItem]

    enum CodingKeys: String, CodingKey {
        case items
        case weekNumber = "week_number"
        case dayOfWeek = "day_of_week"
        case mealType = "meal_type"
    }
}

struct LocalMenuItem: Codable, Identifiable, Hashable {
    let id: String          // slug, e.g. "dal_tadka"
    let name: String        // display name, e.g. "Dal Tadka"
    let calories: Double
    let protein: Double
    let carbs: Double
    let fat: Double
    let servingUnit: String
    let servingSize: Double

    enum CodingKeys: String, CodingKey {
        case id, name, calories, protein, carbs, fat
        case servingUnit = "serving_unit"
        case servingSize = "serving_size"
    }

    var servingDescription: String {
        let count = servingSize == 1.0 ? "1" : String(servingSize)
        return "\(count) \(servingUnit)"
    }
}
