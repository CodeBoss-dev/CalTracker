import SwiftUI

// MARK: - RecentFoodsView
//
// Shows the last 20 unique database foods the user has logged.
// Tapping a food opens FoodDetailView as a sheet to re-log with any serving count.

struct RecentFoodsView: View {
    @EnvironmentObject var logViewModel: FoodLogViewModel
    var onFoodLogged: ((Food, Double, MealType) -> Void)?

    @State private var selectedFood: Food? = nil
    @State private var defaultMealType: MealType
    @Environment(\.dismiss) private var dismiss

    init(defaultMealType: MealType = .breakfast, onFoodLogged: ((Food, Double, MealType) -> Void)? = nil) {
        _defaultMealType = State(initialValue: defaultMealType)
        self.onFoodLogged = onFoodLogged
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.appBg.ignoresSafeArea()

                let foods = logViewModel.recentFoods
                if foods.isEmpty {
                    emptyState
                } else {
                    List(foods) { food in
                        FoodRow(food: food)
                            .listRowBackground(Color.appSurface)
                            .listRowSeparatorTint(Color.white.opacity(0.08))
                            .contentShape(Rectangle())
                            .onTapGesture { selectedFood = food }
                    }
                    .listStyle(.plain)
                    .scrollContentBackground(.hidden)
                }
            }
            .navigationTitle("Recent Foods")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(Color.appGreenLight)
                }
            }
            .sheet(item: $selectedFood) { food in
                FoodDetailView(food: food, mealType: defaultMealType) { food, servings, meal in
                    onFoodLogged?(food, servings, meal)
                    dismiss()
                }
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: "clock.arrow.circlepath")
                .font(.system(size: 48))
                .foregroundStyle(Color.appGreenLight.opacity(0.4))
            Text("No recent foods yet")
                .font(.headline)
                .foregroundStyle(.white)
            Text("Foods you log from the database\nwill appear here for quick re-logging.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            Spacer()
        }
        .padding(24)
    }
}
