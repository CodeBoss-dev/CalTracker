import Foundation

// MARK: - DashboardViewModel
//
// Dashboard-specific logic: greeting text, date display, and smart suggestion generation.
// Nutritional data is read from FoodLogViewModel (injected as @EnvironmentObject in DashboardView).

@MainActor
final class DashboardViewModel: ObservableObject {

    // MARK: - Greeting

    var greeting: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<12: return "Good morning"
        case 12..<17: return "Good afternoon"
        default:     return "Good evening"
        }
    }

    var dateString: String {
        let fmt = DateFormatter()
        fmt.dateFormat = "EEE, d MMM"
        return fmt.string(from: Date())
    }

    // MARK: - Smart Suggestion

    /// Generate a contextual meal suggestion based on remaining budget and time of day.
    func suggestion(
        remainingCalories: Double,
        totalCalories: Double,
        calorieTarget: Double,
        remainingProtein: Double
    ) -> String {
        let hour = Calendar.current.component(.hour, from: Date())

        guard totalCalories > 0 else {
            return "Start your day! Log your breakfast to keep track of your calories."
        }

        guard remainingCalories > 0 else {
            return "You've hit your calorie target for today — great discipline!"
        }

        let pct = totalCalories / calorieTarget

        if hour < 12 {
            // Morning — lunch coming up
            if remainingCalories < 450 {
                return "Only \(Int(remainingCalories)) kcal left. Keep lunch light — 1 katori dal + salad (~300 kcal)."
            }
            if remainingProtein > 40 {
                return "Protein is low. For lunch, try 2 chapati + 1 katori dal + 1 egg (~500 kcal, ~30g protein)."
            }
            return "For lunch, try 2 chapati + 1 katori dal + salad (~480 kcal) to stay on target."
        } else if hour < 17 {
            // Afternoon — dinner planning
            if remainingCalories < 400 {
                return "Only \(Int(remainingCalories)) kcal left for dinner. Go light — 1 chapati + sabzi."
            }
            if pct > 0.85 {
                return "You're at \(Int(pct * 100))% of target. Keep dinner light — skip the rice, opt for chapati + dal."
            }
            return "For dinner, try 2 chapati + 1 katori dal + 1 katori sabzi (~520 kcal)."
        } else {
            // Evening
            if remainingCalories > 400 {
                return "You have \(Int(remainingCalories)) kcal left. A balanced dinner will keep you on track."
            } else if remainingCalories > 150 {
                return "\(Int(remainingCalories)) kcal left — a light snack like sprouts or fruit salad works."
            }
            return "Almost at target! Avoid heavy snacks this late to stay in deficit."
        }
    }
}
