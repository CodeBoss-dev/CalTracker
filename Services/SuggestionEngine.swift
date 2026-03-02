import Foundation

// MARK: - SuggestionEngine
//
// Pure, stateless logic layer for generating meal suggestions.
// Given a snapshot of the user's nutrition state and today's mess menu items,
// returns a human-readable suggestion string.
//
// Rules:
//  • Nothing logged → prompt to start
//  • Over/at target → congratulate, warn about extras
//  • Budget < 120 kcal → light snack tip
//  • Menu items available → build an actual combo from today's mess menu
//  • No menu data → fall back to generic chapati/dal advice
//
// Combo builder:
//  • Prioritises high-protein items (≥ 8g protein for suggested qty)
//  • Skips calorie-dense items (> 300 kcal for suggested qty) when budget is tight
//  • Suggests 2 pieces for "piece" unit items (chapati, paratha), 1 for everything else
//  • Caps combo at 4 items to keep the suggestion readable

struct SuggestionEngine {

    // MARK: - Input

    struct Input {
        /// Total kcal consumed today.
        let totalCalories: Double
        /// kcal remaining before daily target (already clamped to ≥ 0 by FoodLogViewModel).
        let remainingCalories: Double
        /// User's daily calorie target.
        let calorieTarget: Double
        /// Protein still needed today (positive = need more, negative = exceeded).
        let remainingProtein: Double
        /// The next upcoming meal type, derived from current hour.
        let upcomingMeal: MealType
        /// Today's mess menu items for that meal.
        let menuItems: [LocalMenuItem]
        /// Current hour of day (0–23).
        let hour: Int
    }

    // MARK: - Generate

    func generateSuggestion(_ input: Input) -> String {
        // Nothing logged yet today
        guard input.totalCalories > 0 else {
            return startOfDayTip(meal: input.upcomingMeal, menuItems: input.menuItems)
        }

        // Over or exactly at target
        if input.remainingCalories <= 0 {
            return "You've hit your calorie target for today — great discipline! Avoid extra snacking."
        }

        // Very little budget left
        if input.remainingCalories < 120 {
            return "Only \(Int(input.remainingCalories)) kcal left — a cucumber salad or light fruit will wrap up your day perfectly."
        }

        // No menu data for this meal
        guard !input.menuItems.isEmpty else {
            return genericTip(for: input)
        }

        return menuBasedSuggestion(for: input)
    }

    // MARK: - Menu-based combo builder

    private func menuBasedSuggestion(for input: Input) -> String {
        let budget = min(input.remainingCalories, mealBudget(for: input.upcomingMeal))
        let items  = input.menuItems

        // Tag items by calorie load for the suggested serving quantity
        let calorieDenseIds = Set(
            items.filter { totalItemCalories($0) > 300 }.map { $0.id }
        )
        let highProteinIds = Set(
            items.filter { $0.protein * suggestedQty($0) >= 8 }.map { $0.id }
        )
        let isCalorieTight = budget < 380

        // Sort: high-protein first → normal → calorie-dense last
        let sorted = items.sorted { a, b in
            let aScore = highProteinIds.contains(a.id) ? 0 : (calorieDenseIds.contains(a.id) ? 2 : 1)
            let bScore = highProteinIds.contains(b.id) ? 0 : (calorieDenseIds.contains(b.id) ? 2 : 1)
            return aScore < bScore
        }

        var combo: [(item: LocalMenuItem, qty: Double)] = []
        var comboCal: Double = 0

        for item in sorted {
            if calorieDenseIds.contains(item.id) && isCalorieTight { continue }
            let qty = suggestedQty(item)
            let cal = item.calories * qty
            if comboCal + cal <= budget {
                combo.append((item: item, qty: qty))
                comboCal += cal
            }
            if combo.count >= 4 { break }
        }

        guard !combo.isEmpty else {
            return "The \(input.upcomingMeal.displayName) menu is heavy today — eat mindfully to stay within \(Int(input.remainingCalories)) kcal."
        }

        // Build suggestion text
        let parts     = combo.map { itemLabel(item: $0.item, qty: $0.qty) }
        let comboText = parts.joined(separator: " + ")
        let totalCal  = combo.reduce(0.0) { $0 + $1.item.calories * $1.qty }
        let totalProt = combo.reduce(0.0) { $0 + $1.item.protein * $1.qty }

        var text = "For \(input.upcomingMeal.displayName), try \(comboText) (~\(Int(totalCal)) kcal, \(Int(totalProt))g protein)."

        // Warn about dense items that were left out of the combo
        let comboIds      = Set(combo.map { $0.item.id })
        let skippedDense  = items.filter { calorieDenseIds.contains($0.id) && !comboIds.contains($0.id) }
        if !skippedDense.isEmpty {
            let names = skippedDense.prefix(2).map { $0.name }.joined(separator: " and ")
            text += " Go easy on \(names) — they're calorie-dense."
        }

        // Nudge if protein is still very low
        if input.remainingProtein > 35 {
            text += " Protein is low — add paneer or an egg if available."
        }

        return text
    }

    // MARK: - Helpers

    /// Number of default servings to suggest for typical eating behaviour.
    /// Breads (chapati, paratha, poori) → 2 pieces; everything else → 1.
    private func suggestedQty(_ item: LocalMenuItem) -> Double {
        item.servingUnit.lowercased() == "piece" ? 2.0 : 1.0
    }

    /// Total kcal for one suggested serving.
    private func totalItemCalories(_ item: LocalMenuItem) -> Double {
        item.calories * suggestedQty(item)
    }

    /// Ideal calorie budget for each meal type.
    private func mealBudget(for meal: MealType) -> Double {
        switch meal {
        case .breakfast: return 400
        case .lunch:     return 580
        case .dinner:    return 520
        case .snack:     return 200
        }
    }

    /// Human-readable label: "2 Chapati / Roti" or "1 katori Dal Tadka".
    private func itemLabel(item: LocalMenuItem, qty: Double) -> String {
        let qtyStr = qty == Double(Int(qty)) ? String(Int(qty)) : String(format: "%.1g", qty)
        let unit   = item.servingUnit.lowercased()
        return unit == "piece"
            ? "\(qtyStr) \(item.name)"
            : "\(qtyStr) \(unit) \(item.name)"
    }

    private func startOfDayTip(meal: MealType, menuItems: [LocalMenuItem]) -> String {
        if let first = menuItems.first {
            return "Start your day! Try \(first.name) for \(meal.displayName.lowercased()) — log it to begin tracking."
        }
        return "Start your day! Log your \(meal.displayName.lowercased()) to begin tracking your calories."
    }

    private func genericTip(for input: Input) -> String {
        switch input.upcomingMeal {
        case .breakfast:
            return "For breakfast, try 2 chapati with dal or an egg for a protein-rich start (~400 kcal)."
        case .lunch:
            return "For lunch, try 2 chapati + 1 katori dal + salad (~480 kcal, 25g protein)."
        case .dinner:
            if input.remainingCalories < 400 {
                return "Keep dinner light — 1 chapati + sabzi to close the day in deficit."
            }
            return "For dinner, try 2 chapati + 1 katori dal + 1 katori sabzi (~520 kcal)."
        case .snack:
            return "Snack smart — try sprouts, a fruit, or buttermilk (~100–150 kcal)."
        }
    }
}
