import Foundation

/// Nutrition calculations using the Mifflin-St Jeor equation.
///
/// Usage:
/// ```swift
/// let bmr  = NutritionCalculator.bmr(weightKg: 74, heightCm: 175, age: 22)
/// let tdee = NutritionCalculator.tdee(weightKg: 74, heightCm: 175, age: 22,
///                                     activityMultiplier: 1.55)
/// let target = NutritionCalculator.dailyCalorieTarget(tdee: tdee, goal: .lose)
/// let macros = NutritionCalculator.macroTargets(dailyCalories: target, goal: .lose)
/// ```
enum NutritionCalculator {

    // MARK: - BMR

    /// Mifflin-St Jeor Basal Metabolic Rate.
    /// - Male:   10 × weight(kg) + 6.25 × height(cm) − 5 × age + 5
    /// - Female: 10 × weight(kg) + 6.25 × height(cm) − 5 × age − 161
    static func bmr(weightKg: Double, heightCm: Double, age: Int,
                    isMale: Bool = true) -> Double {
        let base = 10 * weightKg + 6.25 * heightCm - 5.0 * Double(age)
        return base + (isMale ? 5.0 : -161.0)
    }

    // MARK: - TDEE

    static func tdee(weightKg: Double, heightCm: Double, age: Int,
                     isMale: Bool = true, activityMultiplier: Double) -> Double {
        bmr(weightKg: weightKg, heightCm: heightCm, age: age, isMale: isMale)
            * activityMultiplier
    }

    // MARK: - Daily Calorie Target

    /// Applies goal-based calorie adjustment (e.g. −500 for .lose) and floors at 1200 kcal.
    static func dailyCalorieTarget(tdee: Double, goal: FitnessGoal) -> Int {
        max(1200, Int((tdee + goal.calorieAdjustment).rounded()))
    }

    // MARK: - Macro Targets

    /// Returns (protein, carbs, fat) in grams for a given calorie target and goal.
    ///
    /// Macro ratios:
    /// - `.lose`:     33 % protein / 42 % carbs / 25 % fat  (higher protein, preserves muscle)
    /// - `.maintain`: 30 % protein / 45 % carbs / 25 % fat
    /// - `.gain`:     30 % protein / 50 % carbs / 20 % fat  (extra carbs to fuel training)
    static func macroTargets(dailyCalories: Int,
                             goal: FitnessGoal) -> (protein: Int, carbs: Int, fat: Int) {
        let kcal = Double(dailyCalories)
        switch goal {
        case .lose:
            return (
                protein: Int((kcal * 0.33) / 4),   // 4 kcal/g
                carbs:   Int((kcal * 0.42) / 4),
                fat:     Int((kcal * 0.25) / 9)    // 9 kcal/g
            )
        case .maintain:
            return (
                protein: Int((kcal * 0.30) / 4),
                carbs:   Int((kcal * 0.45) / 4),
                fat:     Int((kcal * 0.25) / 9)
            )
        case .gain:
            return (
                protein: Int((kcal * 0.30) / 4),
                carbs:   Int((kcal * 0.50) / 4),
                fat:     Int((kcal * 0.20) / 9)
            )
        }
    }
}
