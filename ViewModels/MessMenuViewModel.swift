import SwiftUI
import Combine

@MainActor
final class MessMenuViewModel: ObservableObject {

    // MARK: - Published state

    @Published var selectedDate: Date = Date()
    @Published var browsingDay: DayOfWeek
    @Published var weekOverride: Int?

    // MARK: - Private

    private let service = MessMenuService.shared

    // MARK: - Init

    init() {
        browsingDay = WeekResolver.dayOfWeek(for: Date())
    }

    // MARK: - Derived properties

    var currentWeekNumber: Int {
        WeekResolver.weekNumber(for: selectedDate)
    }

    /// The week number used for browsing — manual override or auto-resolved.
    var activeWeekNumber: Int {
        weekOverride ?? currentWeekNumber
    }

    var todayWeekNumber: Int {
        WeekResolver.weekNumber(for: Date())
    }

    var currentDay: DayOfWeek {
        WeekResolver.dayOfWeek(for: selectedDate)
    }

    // MARK: - Today's menu

    /// Items for today's date grouped by meal type.
    func todaysItems(for mealType: MealType) -> [LocalMenuItem] {
        service.todaysItems(mealType: mealType, for: selectedDate)
    }

    // MARK: - Weekly browse

    /// Items for the browsing day (used in WeeklyMenuView tab browsing).
    func items(for day: DayOfWeek, mealType: MealType) -> [LocalMenuItem] {
        service.items(day: day, mealType: mealType, weekNumber: activeWeekNumber)
    }

    // MARK: - Calorie summary helpers

    func totalCalories(items: [LocalMenuItem]) -> Double {
        items.reduce(0) { $0 + $1.calories }
    }

    func mealCalories(for mealType: MealType) -> Double {
        totalCalories(items: todaysItems(for: mealType))
    }

    var totalDayCalories: Double {
        MealType.allCases
            .filter { $0 != .snack }
            .reduce(0) { $0 + mealCalories(for: $1) }
    }

    // MARK: - Week label

    var weekLabel: String {
        if weekOverride != nil {
            return "Week \(activeWeekNumber) (manual)"
        }
        return "Week \(currentWeekNumber)"
    }

    func resetToAutoWeek() {
        weekOverride = nil
    }

    // MARK: - Ordered days for weekly view

    let orderedDays: [DayOfWeek] = [
        .monday, .tuesday, .wednesday, .thursday,
        .friday, .saturday, .sunday
    ]
}
