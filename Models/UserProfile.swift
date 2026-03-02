import Foundation

// MARK: - Enums

enum MealType: String, Codable, CaseIterable, Hashable {
    case breakfast = "breakfast"
    case lunch = "lunch"
    case dinner = "dinner"
    case snack = "snack"

    var displayName: String {
        switch self {
        case .breakfast: return "Breakfast"
        case .lunch: return "Lunch"
        case .dinner: return "Dinner"
        case .snack: return "Snack"
        }
    }

    var icon: String {
        switch self {
        case .breakfast: return "sunrise.fill"
        case .lunch: return "sun.max.fill"
        case .dinner: return "moon.fill"
        case .snack: return "leaf.fill"
        }
    }
}

enum FoodCategory: String, Codable, CaseIterable {
    case breakfast = "breakfast"
    case breads = "breads"
    case rice = "rice"
    case dal = "dal"
    case curry = "curry"
    case paneer = "paneer"
    case snacks = "snacks"
    case beverages = "beverages"
    case sweets = "sweets"
    case salads = "salads"
    case eggs = "eggs"
    case outside = "outside"

    var displayName: String {
        switch self {
        case .breakfast: return "Breakfast Items"
        case .breads: return "Breads"
        case .rice: return "Rice"
        case .dal: return "Dal"
        case .curry: return "Curries & Sabzi"
        case .paneer: return "Paneer"
        case .snacks: return "Snacks"
        case .beverages: return "Beverages"
        case .sweets: return "Sweets"
        case .salads: return "Salads & Sides"
        case .eggs: return "Eggs"
        case .outside: return "Outside Food"
        }
    }

    var icon: String {
        switch self {
        case .breakfast: return "sun.and.horizon.fill"
        case .breads: return "circle.fill"
        case .rice: return "fork.knife"
        case .dal: return "drop.fill"
        case .curry: return "flame.fill"
        case .paneer: return "square.fill"
        case .snacks: return "bag.fill"
        case .beverages: return "cup.and.saucer.fill"
        case .sweets: return "heart.fill"
        case .salads: return "leaf.fill"
        case .eggs: return "oval.fill"
        case .outside: return "building.2.fill"
        }
    }
}

enum ActivityLevel: String, Codable, CaseIterable {
    case sedentary = "sedentary"
    case lightlyActive = "lightly_active"
    case moderatelyActive = "moderately_active"
    case veryActive = "very_active"
    case extraActive = "extra_active"

    var displayName: String {
        switch self {
        case .sedentary: return "Sedentary (desk job, no exercise)"
        case .lightlyActive: return "Lightly Active (1-3 days/week)"
        case .moderatelyActive: return "Moderately Active (3-5 days/week)"
        case .veryActive: return "Very Active (6-7 days/week)"
        case .extraActive: return "Extra Active (twice/day)"
        }
    }

    var multiplier: Double {
        switch self {
        case .sedentary: return 1.2
        case .lightlyActive: return 1.375
        case .moderatelyActive: return 1.55
        case .veryActive: return 1.725
        case .extraActive: return 1.9
        }
    }
}

enum FitnessGoal: String, Codable, CaseIterable {
    case lose = "lose"
    case maintain = "maintain"
    case gain = "gain"

    var displayName: String {
        switch self {
        case .lose: return "Lose Weight"
        case .maintain: return "Maintain Weight"
        case .gain: return "Gain Muscle"
        }
    }

    var description: String {
        switch self {
        case .lose: return "500 kcal daily deficit"
        case .maintain: return "Maintain current weight"
        case .gain: return "300 kcal surplus"
        }
    }

    /// Calorie adjustment relative to TDEE
    var calorieAdjustment: Double {
        switch self {
        case .lose: return -500
        case .maintain: return 0
        case .gain: return 300
        }
    }
}

enum DayOfWeek: String, Codable, CaseIterable {
    case monday = "monday"
    case tuesday = "tuesday"
    case wednesday = "wednesday"
    case thursday = "thursday"
    case friday = "friday"
    case saturday = "saturday"
    case sunday = "sunday"

    var displayName: String { rawValue.capitalized }

    static func from(date: Date) -> DayOfWeek {
        let weekday = Calendar.current.component(.weekday, from: date)
        switch weekday {
        case 1: return .sunday
        case 2: return .monday
        case 3: return .tuesday
        case 4: return .wednesday
        case 5: return .thursday
        case 6: return .friday
        case 7: return .saturday
        default: return .monday
        }
    }
}

// MARK: - Models

struct UserProfile: Codable, Identifiable {
    let id: UUID
    let name: String
    let heightCm: Double
    let weightKg: Double
    let age: Int
    let activityLevel: ActivityLevel
    let goal: FitnessGoal

    enum CodingKeys: String, CodingKey {
        case id, name, age
        case heightCm = "height_cm"
        case weightKg = "weight_kg"
        case activityLevel = "activity_level"
        case goal
    }
}

struct UserGoals: Codable, Identifiable {
    let id: UUID
    let userId: UUID
    let dailyCalories: Int
    let proteinTarget: Int
    let carbsTarget: Int
    let fatTarget: Int

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case dailyCalories = "daily_calories"
        case proteinTarget = "protein_target"
        case carbsTarget = "carbs_target"
        case fatTarget = "fat_target"
    }
}

// MARK: - Insert structs (used for Supabase writes)

struct UserProfileInsert: Encodable {
    let id: String
    let name: String
    let heightCm: Double
    let weightKg: Double
    let age: Int
    let activityLevel: String
    let goal: String

    enum CodingKeys: String, CodingKey {
        case id, name, age
        case heightCm = "height_cm"
        case weightKg = "weight_kg"
        case activityLevel = "activity_level"
        case goal
    }
}

struct UserGoalsInsert: Encodable {
    let userId: String
    let dailyCalories: Int
    let proteinTarget: Int
    let carbsTarget: Int
    let fatTarget: Int

    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case dailyCalories = "daily_calories"
        case proteinTarget = "protein_target"
        case carbsTarget = "carbs_target"
        case fatTarget = "fat_target"
    }
}
