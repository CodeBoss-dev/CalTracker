import SwiftUI

// MARK: - MealLogView
//
// Tab 2 — the primary food-logging screen.
// Shows a daily summary card, per-meal logged items, and entry points for:
//   • Mess Menu (MessMenuLogView via NavigationLink)
//   • Food Search (FoodSearchView sheet)
//   • Recent Foods (RecentFoodsView sheet)

struct MealLogView: View {

    @EnvironmentObject var logViewModel: FoodLogViewModel

    // Navigation / sheet state
    @State private var showMessMenuLog   = false
    @State private var showSearch        = false
    @State private var showRecent        = false
    @State private var activeMealType: MealType = .breakfast

    // Toast feedback after mess-menu logging
    @State private var showLoggedBanner  = false
    @State private var bannedCount       = 0
    @State private var bannedCalories    = 0

    private let allMeals: [MealType] = MealType.allCases

    var body: some View {
        NavigationStack {
            ZStack(alignment: .top) {
                Color.appBg.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 16) {
                        dailySummaryCard
                        messMenuShortcut
                        ForEach(allMeals, id: \.self) { meal in
                            mealSection(meal)
                        }
                        Color.clear.frame(height: 24)
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 12)
                }

                // Floating success banner
                if showLoggedBanner {
                    bannerView
                        .transition(.move(edge: .top).combined(with: .opacity))
                        .zIndex(10)
                }
            }
            .navigationTitle("Today's Log")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Text(todayLabel)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            // Mess Menu navigation destination
            .navigationDestination(isPresented: $showMessMenuLog) {
                MessMenuLogView(onItemsLogged: { pairs in
                    logViewModel.logMenuItems(pairs)
                    bannedCount    = pairs.count
                    bannedCalories = Int(pairs.reduce(0) { $0 + $1.item.calories })
                    showMessMenuLog = false
                    withAnimation(.spring()) { showLoggedBanner = true }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                        withAnimation { showLoggedBanner = false }
                    }
                })
            }
            // Food search sheet
            .sheet(isPresented: $showSearch) {
                FoodSearchView(mealType: activeMealType, onFoodLogged: { food, servings, meal in
                    logViewModel.logFood(food, servings: servings, mealType: meal)
                    showSearch = false
                })
            }
            // Recent foods sheet
            .sheet(isPresented: $showRecent) {
                RecentFoodsView(defaultMealType: activeMealType, onFoodLogged: { food, servings, meal in
                    logViewModel.logFood(food, servings: servings, mealType: meal)
                    showRecent = false
                })
                .environmentObject(logViewModel)
            }
        }
    }

    // MARK: - Daily Summary Card

    private var dailySummaryCard: some View {
        VStack(spacing: 14) {
            // Calorie progress row
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("\(Int(logViewModel.totalCalories)) kcal")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundStyle(Color.appGreen)
                    Text("of \(Int(logViewModel.calorieTarget)) target")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 2) {
                    Text("\(Int(logViewModel.remainingCalories)) kcal")
                        .font(.subheadline.bold())
                        .foregroundStyle(.white)
                    Text("remaining")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            // Calorie progress bar
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color.appGreen.opacity(0.15))
                        .frame(height: 8)
                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: [Color.appGreen, Color.appGreenLight],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geo.size.width * logViewModel.calorieProgress, height: 8)
                }
            }
            .frame(height: 8)

            // Macro pills
            HStack(spacing: 0) {
                macroPill(label: "Protein", value: logViewModel.totalProtein, target: logViewModel.proteinTarget, color: Color.appProtein)
                Divider().frame(height: 32).overlay(Color.white.opacity(0.1))
                macroPill(label: "Carbs", value: logViewModel.totalCarbs, target: logViewModel.carbsTarget, color: Color.appCarbs)
                Divider().frame(height: 32).overlay(Color.white.opacity(0.1))
                macroPill(label: "Fat", value: logViewModel.totalFat, target: logViewModel.fatTarget, color: Color.appFat)
            }
        }
        .padding(16)
        .background(Color.appSurface, in: RoundedRectangle(cornerRadius: 16))
    }

    private func macroPill(label: String, value: Double, target: Double, color: Color) -> some View {
        VStack(spacing: 3) {
            Text("\(Int(value))g")
                .font(.subheadline.bold())
                .foregroundStyle(.white)
            Text("\(label) / \(Int(target))g")
                .font(.system(size: 10))
                .foregroundStyle(.secondary)
            GeometryReader { geo in
                Capsule()
                    .fill(color.opacity(0.25))
                    .overlay(
                        Capsule()
                            .fill(color)
                            .frame(width: geo.size.width * min(value / target, 1.0)),
                        alignment: .leading
                    )
                    .frame(height: 4)
            }
            .frame(height: 4)
        }
        .padding(.vertical, 8)
        .frame(maxWidth: .infinity)
    }

    // MARK: - Mess Menu Shortcut

    private var messMenuShortcut: some View {
        Button {
            showMessMenuLog = true
        } label: {
            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color.appGreen.opacity(0.15))
                        .frame(width: 40, height: 40)
                    Image(systemName: "menucard.fill")
                        .font(.system(size: 18))
                        .foregroundStyle(Color.appGreen)
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text("Log from Today's Mess Menu")
                        .font(.subheadline.bold())
                        .foregroundStyle(.white)
                    Text("Royal Foods — tap to select items")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption.bold())
                    .foregroundStyle(.secondary)
            }
            .padding(14)
            .background(Color.appSurface, in: RoundedRectangle(cornerRadius: 14))
        }
        .buttonStyle(.plain)
    }

    // MARK: - Meal Section

    private func mealSection(_ meal: MealType) -> some View {
        let items = logViewModel.items(for: meal)
        let mealCalories = logViewModel.calories(for: meal)

        return VStack(alignment: .leading, spacing: 0) {
            // Section header
            HStack(spacing: 8) {
                Image(systemName: meal.icon)
                    .font(.subheadline.bold())
                    .foregroundStyle(Color.appGreen)
                Text(meal.displayName)
                    .font(.headline)
                    .foregroundStyle(.white)
                Spacer()
                Text("\(Int(mealCalories)) kcal")
                    .font(.caption.bold())
                    .foregroundStyle(mealCalories > 0 ? Color.appGreenLight : .secondary)
            }
            .padding(.horizontal, 14)
            .padding(.top, 14)
            .padding(.bottom, items.isEmpty ? 4 : 10)

            // Logged items
            if !items.isEmpty {
                VStack(spacing: 0) {
                    ForEach(items) { item in
                        loggedItemRow(item)
                        if item.id != items.last?.id {
                            Divider()
                                .overlay(Color.white.opacity(0.07))
                                .padding(.horizontal, 14)
                        }
                    }
                }
                .padding(.bottom, 8)
            }

            // Add buttons
            HStack(spacing: 8) {
                addButton(icon: "magnifyingglass", label: "Search") {
                    activeMealType = meal
                    showSearch = true
                }
                addButton(icon: "clock.arrow.circlepath", label: "Recent") {
                    activeMealType = meal
                    showRecent = true
                }
            }
            .padding(.horizontal, 14)
            .padding(.bottom, 14)
            .padding(.top, items.isEmpty ? 8 : 0)
        }
        .background(Color.appSurface, in: RoundedRectangle(cornerRadius: 14))
    }

    // MARK: - Logged Item Row

    private func loggedItemRow(_ item: LoggedItem) -> some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text(item.name)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                Text(item.servingDescription)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Text("\(Int(item.totalCalories)) kcal")
                .font(.subheadline.bold())
                .foregroundStyle(Color.appGreenLight)
            Button {
                withAnimation {
                    logViewModel.delete(item)
                }
            } label: {
                Image(systemName: "trash")
                    .font(.caption.bold())
                    .foregroundStyle(Color.red.opacity(0.6))
                    .frame(width: 32, height: 32)
                    .background(Color.red.opacity(0.08), in: RoundedRectangle(cornerRadius: 8))
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
    }

    // MARK: - Add Button

    private func addButton(icon: String, label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.caption.bold())
                Text(label)
                    .font(.caption.bold())
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .background(Color.appBg)
            .foregroundStyle(Color.appGreenLight)
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .strokeBorder(Color.appGreen.opacity(0.3), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Success Banner

    private var bannerView: some View {
        HStack(spacing: 10) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(Color.appGreen)
            Text("Logged \(bannedCount) item\(bannedCount == 1 ? "" : "s") — \(bannedCalories) kcal")
                .font(.subheadline.bold())
                .foregroundStyle(.white)
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color.appSurface, in: RoundedRectangle(cornerRadius: 12))
        .shadow(color: Color.appGreen.opacity(0.2), radius: 8, y: 4)
        .padding(.horizontal, 16)
        .padding(.top, 8)
    }

    // MARK: - Helpers

    private var todayLabel: String {
        let fmt = DateFormatter()
        fmt.dateFormat = "EEE, d MMM"
        return fmt.string(from: Date())
    }
}
