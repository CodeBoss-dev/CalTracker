import SwiftUI

// MARK: - MessMenuLogView
//
// Displays today's mess menu items grouped by breakfast / lunch / dinner.
// Users tap items to select them (checkbox style) and tap "Log Selected"
// to log the whole batch. Phase 4 wires in the actual FoodLogService call
// via the `onItemsLogged` closure.

struct MessMenuLogView: View {

    @StateObject private var viewModel = MessMenuViewModel()

    // Phase 4 will inject a real handler here.
    var onItemsLogged: ([(item: LocalMenuItem, mealType: MealType)] -> Void)?

    // Key = "\(mealType.rawValue)_\(item.id)" → Bool
    @State private var selected: [String: Bool] = [:]
    @State private var showConfirmation = false

    private let messMeals: [MealType] = [.breakfast, .lunch, .dinner]

    // MARK: - Computed

    private func key(_ meal: MealType, _ item: LocalMenuItem) -> String {
        "\(meal.rawValue)_\(item.id)"
    }

    private func isSelected(_ meal: MealType, _ item: LocalMenuItem) -> Bool {
        selected[key(meal, item)] == true
    }

    private var selectedPairs: [(item: LocalMenuItem, mealType: MealType)] {
        messMeals.flatMap { meal in
            viewModel.todaysItems(for: meal).compactMap { item in
                isSelected(meal, item) ? (item: item, mealType: meal) : nil
            }
        }
    }

    private var selectedCaloriesTotal: Double {
        selectedPairs.reduce(0) { $0 + $1.item.calories }
    }

    private var selectedCount: Int { selectedPairs.count }

    // MARK: - Body

    var body: some View {
        ZStack(alignment: .bottom) {
            Color.appBg.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 16) {
                    headerBanner
                    ForEach(messMeals, id: \.self) { meal in
                        let items = viewModel.todaysItems(for: meal)
                        if !items.isEmpty {
                            mealSection(meal: meal, items: items)
                        }
                    }
                    // Bottom spacer so content is not hidden behind the sticky button
                    Color.clear.frame(height: 90)
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
            }

            if selectedCount > 0 {
                logButton
                    .padding(.horizontal, 16)
                    .padding(.bottom, 16)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .navigationTitle("Today's Menu")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Clear") { selected.removeAll() }
                    .foregroundStyle(Color.appGreenLight)
                    .opacity(selectedCount > 0 ? 1 : 0)
            }
        }
        .alert("Logged!", isPresented: $showConfirmation) {
            Button("Great") { selected.removeAll() }
        } message: {
            Text("\(selectedCount) items • \(Int(selectedCaloriesTotal)) kcal added to today's log.")
        }
        .animation(.easeInOut(duration: 0.2), value: selectedCount)
    }

    // MARK: - Header Banner

    private var headerBanner: some View {
        HStack(spacing: 12) {
            Image(systemName: "menucard.fill")
                .font(.title2)
                .foregroundStyle(Color.appGreen)
            VStack(alignment: .leading, spacing: 2) {
                Text("Royal Foods — \(viewModel.weekLabel)")
                    .font(.headline)
                    .foregroundStyle(.white)
                Text(formattedDate(Date()))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            Spacer()
        }
        .padding(14)
        .background(Color.appSurface, in: RoundedRectangle(cornerRadius: 14))
    }

    // MARK: - Meal Section

    private func mealSection(meal: MealType, items: [LocalMenuItem]) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            // Section header
            HStack(spacing: 8) {
                Image(systemName: meal.icon)
                    .font(.subheadline.bold())
                    .foregroundStyle(Color.appGreen)
                Text(meal.displayName)
                    .font(.headline)
                    .foregroundStyle(.white)
                Spacer()
                let mealTotal = items.reduce(0.0) { $0 + $1.calories }
                Text("~\(Int(mealTotal)) kcal total")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            // Item rows
            ForEach(items) { item in
                menuItemRow(item: item, meal: meal)
            }
        }
        .padding(14)
        .background(Color.appSurface, in: RoundedRectangle(cornerRadius: 14))
    }

    // MARK: - Menu Item Row

    private func menuItemRow(item: LocalMenuItem, meal: MealType) -> some View {
        let sel = isSelected(meal, item)
        return Button {
            withAnimation(.easeInOut(duration: 0.15)) {
                selected[key(meal, item)] = !sel
            }
        } label: {
            HStack(spacing: 12) {
                // Checkbox
                ZStack {
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(sel ? Color.appGreen : Color.gray.opacity(0.4), lineWidth: 1.5)
                        .frame(width: 24, height: 24)
                        .background(
                            RoundedRectangle(cornerRadius: 6)
                                .fill(sel ? Color.appGreen : Color.clear)
                        )
                    if sel {
                        Image(systemName: "checkmark")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(.white)
                    }
                }

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

                VStack(alignment: .trailing, spacing: 2) {
                    Text("\(Int(item.calories)) kcal")
                        .font(.subheadline.bold())
                        .foregroundStyle(sel ? Color.appGreen : .white)
                    HStack(spacing: 4) {
                        Text("P:\(Int(item.protein))g")
                        Text("C:\(Int(item.carbs))g")
                        Text("F:\(Int(item.fat))g")
                    }
                    .font(.system(size: 10))
                    .foregroundStyle(.secondary)
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    // MARK: - Log Button

    private var logButton: some View {
        Button {
            if let handler = onItemsLogged {
                handler(selectedPairs)
                selected.removeAll()
            } else {
                showConfirmation = true
            }
        } label: {
            HStack {
                Image(systemName: "checkmark.circle.fill")
                    .font(.title3)
                Text("Log \(selectedCount) item\(selectedCount == 1 ? "" : "s")")
                    .fontWeight(.bold)
                Spacer()
                Text("\(Int(selectedCaloriesTotal)) kcal")
                    .fontWeight(.semibold)
            }
            .padding(16)
            .background(Color.appGreen, in: RoundedRectangle(cornerRadius: 14))
            .foregroundStyle(.white)
            .shadow(color: Color.appGreen.opacity(0.4), radius: 8, y: 4)
        }
    }

    // MARK: - Helpers

    private func formattedDate(_ date: Date) -> String {
        let fmt = DateFormatter()
        fmt.dateFormat = "EEEE, d MMMM yyyy"
        return fmt.string(from: date)
    }
}
