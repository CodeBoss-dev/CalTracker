import Foundation

// MARK: - SuggestionViewModel
//
// Bridges SuggestionEngine and the Dashboard UI.
//
// Design: `suggestion(from:)` is a regular method (not @Published) so it re-evaluates
// automatically every time the SwiftUI view body re-renders due to FoodLogViewModel changes.
// This avoids needing .onChange / .task boilerplate in DashboardView.
//
// Wiring:
//   DashboardView holds a @StateObject of this class.
//   Calls suggestionVM.suggestion(from: logViewModel) inline in the view body.

@MainActor
final class SuggestionViewModel: ObservableObject {

    private let engine = SuggestionEngine()

    // MARK: - Public API

    /// Returns a contextual meal suggestion based on the current log state and today's mess menu.
    /// Safe to call every render — pure computation, no side effects.
    func suggestion(from logViewModel: FoodLogViewModel, date: Date = Date()) -> String {
        let hour = Calendar.current.component(.hour, from: date)
        let meal = upcomingMeal(for: hour)
        let menuItems = MessMenuService.shared.todaysItems(mealType: meal, for: date)

        let input = SuggestionEngine.Input(
            totalCalories:    logViewModel.totalCalories,
            remainingCalories: logViewModel.remainingCalories,
            calorieTarget:    logViewModel.calorieTarget,
            remainingProtein: logViewModel.proteinTarget - logViewModel.totalProtein,
            upcomingMeal:     meal,
            menuItems:        menuItems,
            hour:             hour
        )

        return engine.generateSuggestion(input)
    }

    // MARK: - Private

    /// Determines which meal to suggest based on the current hour.
    ///  • Before 10:00 → Breakfast
    ///  • 10:00–14:59 → Lunch
    ///  • 15:00 onwards → Dinner
    private func upcomingMeal(for hour: Int) -> MealType {
        if hour < 10 { return .breakfast }
        if hour < 15 { return .lunch }
        return .dinner
    }
}
