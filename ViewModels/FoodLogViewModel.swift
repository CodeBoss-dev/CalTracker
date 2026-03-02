import Foundation
import Combine

@MainActor
final class FoodLogViewModel: ObservableObject {

    private let service = FoodLogService.shared
    private var cancellables = Set<AnyCancellable>()

    /// Mirror of FoodLogService.todaysItems — triggers SwiftUI refresh.
    @Published private(set) var todaysItems: [LoggedItem] = []

    // Daily targets — driven by GoalsService (live updates when user edits goals)
    @Published private(set) var calorieTarget: Double
    @Published private(set) var proteinTarget: Double
    @Published private(set) var carbsTarget:   Double
    @Published private(set) var fatTarget:     Double

    init() {
        let g = GoalsService.shared.goals
        calorieTarget = Double(g.dailyCalories)
        proteinTarget = Double(g.proteinTarget)
        carbsTarget   = Double(g.carbsTarget)
        fatTarget     = Double(g.fatTarget)

        // Mirror today's logged items
        service.$todaysItems
            .sink { [weak self] items in self?.todaysItems = items }
            .store(in: &cancellables)
        todaysItems = service.todaysItems

        // Refresh targets whenever the user saves changes in GoalEditorView
        GoalsService.shared.$goals
            .sink { [weak self] goals in
                self?.calorieTarget = Double(goals.dailyCalories)
                self?.proteinTarget = Double(goals.proteinTarget)
                self?.carbsTarget   = Double(goals.carbsTarget)
                self?.fatTarget     = Double(goals.fatTarget)
            }
            .store(in: &cancellables)
    }

    // MARK: - Computed daily totals

    var totalCalories: Double { todaysItems.reduce(0) { $0 + $1.totalCalories } }
    var totalProtein: Double  { todaysItems.reduce(0) { $0 + $1.totalProtein } }
    var totalCarbs: Double    { todaysItems.reduce(0) { $0 + $1.totalCarbs } }
    var totalFat: Double      { todaysItems.reduce(0) { $0 + $1.totalFat } }
    var remainingCalories: Double { max(0, calorieTarget - totalCalories) }
    var calorieProgress: Double   { min(totalCalories / calorieTarget, 1.0) }

    // MARK: - Per-meal helpers

    func items(for mealType: MealType) -> [LoggedItem] {
        todaysItems.filter { $0.mealType == mealType }
    }

    func calories(for mealType: MealType) -> Double {
        items(for: mealType).reduce(0) { $0 + $1.totalCalories }
    }

    // MARK: - Logging actions (delegates to service)

    func logFood(_ food: Food, servings: Double, mealType: MealType) {
        service.log(food: food, servings: servings, mealType: mealType)
    }

    func logMenuItems(_ pairs: [(item: LocalMenuItem, mealType: MealType)]) {
        pairs.forEach { service.log(menuItem: $0.item, mealType: $0.mealType) }
    }

    func delete(_ item: LoggedItem) {
        service.delete(item)
    }

    // MARK: - Recent foods (for RecentFoodsView)

    var recentFoods: [Food] { service.recentFoods }
}
