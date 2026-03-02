import Foundation

struct FoodLogEntry: Codable, Identifiable {
    let id: UUID
    let userId: UUID
    let foodId: UUID
    let mealType: MealType
    let servings: Double
    let date: String        // "YYYY-MM-DD"
    let timestamp: Date
    var food: Food?          // populated via join when fetching

    enum CodingKeys: String, CodingKey {
        case id, servings, date, timestamp, food
        case userId = "user_id"
        case foodId = "food_id"
        case mealType = "meal_type"
    }

    // MARK: - Computed nutrition

    var totalCalories: Double {
        (food?.caloriesPerServing ?? 0) * servings
    }

    var totalProtein: Double {
        (food?.protein ?? 0) * servings
    }

    var totalCarbs: Double {
        (food?.carbs ?? 0) * servings
    }

    var totalFat: Double {
        (food?.fat ?? 0) * servings
    }
}

// MARK: - Insert struct

struct FoodLogInsert: Encodable {
    let userId: String
    let foodId: String
    let mealType: String
    let servings: Double
    let date: String
    let timestamp: Date

    enum CodingKeys: String, CodingKey {
        case servings, date, timestamp
        case userId = "user_id"
        case foodId = "food_id"
        case mealType = "meal_type"
    }
}
