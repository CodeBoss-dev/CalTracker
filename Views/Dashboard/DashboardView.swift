import SwiftUI

// MARK: - DashboardView
//
// Tab 1 — the home screen.
// Shows a greeting, calorie ring, macro bars, a smart suggestion, and per-meal summaries.
// All nutritional data flows from FoodLogViewModel (shared @EnvironmentObject from ContentView).

struct DashboardView: View {
    @EnvironmentObject var logViewModel: FoodLogViewModel
    @StateObject private var dashVM = DashboardViewModel()
    @StateObject private var suggestionVM = SuggestionViewModel()

    var body: some View {
        NavigationStack {
            ZStack {
                Color.appBg.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 18) {
                        greetingHeader
                        calorieRingCard
                        macroCard
                        SuggestionBannerView(
                            suggestion: suggestionVM.suggestion(from: logViewModel)
                        )

                        SectionHeader(title: "Today's Meals")

                        ForEach(MealType.allCases, id: \.self) { meal in
                            MealSectionCard(
                                mealType: meal,
                                items: logViewModel.items(for: meal),
                                mealCalories: logViewModel.calories(for: meal)
                            )
                        }

                        Color.clear.frame(height: 20)
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 12)
                }
            }
            .navigationTitle("Dashboard")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Text(dashVM.dateString)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    // MARK: - Greeting Header

    private var greetingHeader: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 4) {
                Text(dashVM.greeting)
                    .font(.title2.bold())
                    .foregroundStyle(.white)
                Text(
                    logViewModel.totalCalories == 0
                    ? "Nothing logged yet today."
                    : "\(Int(logViewModel.totalCalories)) kcal consumed so far"
                )
                .font(.subheadline)
                .foregroundStyle(.secondary)
            }
            Spacer()
            // Mini ring to show quick % progress
            miniRing
        }
    }

    private var miniRing: some View {
        ZStack {
            Circle()
                .stroke(Color.appGreen.opacity(0.15), lineWidth: 5)
            Circle()
                .trim(from: 0, to: logViewModel.calorieProgress)
                .stroke(Color.appGreen, style: StrokeStyle(lineWidth: 5, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .animation(.spring(response: 0.8), value: logViewModel.calorieProgress)
            Text("\(Int(logViewModel.calorieProgress * 100))%")
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(.white)
        }
        .frame(width: 52, height: 52)
    }

    // MARK: - Calorie Ring Card

    private var calorieRingCard: some View {
        VStack(spacing: 18) {
            CalorieRingView(
                consumed: logViewModel.totalCalories,
                target: logViewModel.calorieTarget,
                ringSize: 190
            )

            // Stats row below the ring
            HStack(spacing: 0) {
                statColumn(label: "Consumed", value: "\(Int(logViewModel.totalCalories))", unit: "kcal", color: Color.appGreen)
                dividerLine
                statColumn(label: "Target", value: "\(Int(logViewModel.calorieTarget))", unit: "kcal", color: .secondary)
                dividerLine
                statColumn(label: "Remaining", value: "\(Int(logViewModel.remainingCalories))", unit: "kcal", color: Color.appGreenLight)
            }
        }
        .padding(20)
        .background(Color.appSurface, in: RoundedRectangle(cornerRadius: 20))
    }

    private func statColumn(label: String, value: String, unit: String, color: Color) -> some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .foregroundStyle(color)
            Text(unit)
                .font(.system(size: 10))
                .foregroundStyle(.secondary)
            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }

    private var dividerLine: some View {
        Rectangle()
            .fill(Color.white.opacity(0.08))
            .frame(width: 1, height: 44)
    }

    // MARK: - Macro Card

    private var macroCard: some View {
        VStack(spacing: 14) {
            Text("Macros")
                .font(.headline)
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity, alignment: .leading)

            MacroProgressBar(
                label: "Protein",
                value: logViewModel.totalProtein,
                target: logViewModel.proteinTarget,
                color: Color.appProtein
            )
            MacroProgressBar(
                label: "Carbs",
                value: logViewModel.totalCarbs,
                target: logViewModel.carbsTarget,
                color: Color.appCarbs
            )
            MacroProgressBar(
                label: "Fat",
                value: logViewModel.totalFat,
                target: logViewModel.fatTarget,
                color: Color.appFat
            )
        }
        .padding(16)
        .background(Color.appSurface, in: RoundedRectangle(cornerRadius: 16))
    }
}

// MARK: - SectionHeader

private struct SectionHeader: View {
    let title: String
    var body: some View {
        Text(title)
            .font(.headline)
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity, alignment: .leading)
    }
}
