import SwiftUI

// MARK: - WeeklyMenuView
//
// Main view for the Mess Menu tab.
// Shows the full 7-day week menu with a day picker at the top.
// "Log Today" button navigates to MessMenuLogView.

struct WeeklyMenuView: View {

    @StateObject private var viewModel = MessMenuViewModel()
    @State private var showLogView   = false
    @State private var showConfigView = false

    private let messMeals: [MealType] = [.breakfast, .lunch, .dinner]

    // MARK: - Body

    var body: some View {
        NavigationStack {
            ZStack {
                Color.appBg.ignoresSafeArea()

                VStack(spacing: 0) {
                    weekHeader
                    dayPicker
                    Divider().overlay(Color.appGreen.opacity(0.3))

                    ScrollView {
                        VStack(spacing: 14) {
                            ForEach(messMeals, id: \.self) { meal in
                                let items = viewModel.items(
                                    for: viewModel.browsingDay,
                                    mealType: meal
                                )
                                if !items.isEmpty {
                                    mealCard(meal: meal, items: items)
                                }
                            }
                            Color.clear.frame(height: 12)
                        }
                        .padding(.horizontal, 16)
                        .padding(.top, 14)
                    }
                }
            }
            .navigationTitle("Mess Menu")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        showConfigView = true
                    } label: {
                        Image(systemName: "square.and.pencil")
                            .foregroundStyle(Color.appGreenLight)
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showLogView = true
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "plus.circle.fill")
                            Text("Log Today")
                                .fontWeight(.semibold)
                        }
                        .foregroundStyle(Color.appGreen)
                        .font(.subheadline)
                    }
                }
            }
            .navigationDestination(isPresented: $showLogView) {
                MessMenuLogView(onItemsLogged: { pairs in
                    for pair in pairs {
                        FoodLogService.shared.log(menuItem: pair.item, mealType: pair.mealType)
                    }
                    showLogView = false
                })
            }
            .sheet(isPresented: $showConfigView) {
                MessMenuConfigView(viewModel: viewModel)
            }
        }
    }

    // MARK: - Week Header

    private var weekHeader: some View {
        HStack(spacing: 10) {
            Image(systemName: "calendar")
                .foregroundStyle(Color.appGreen)
            Text("Royal Foods — \(viewModel.weekLabel)")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.white)
            Spacer()
            Text(todayLabel)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(Color.appSurface)
    }

    private var todayLabel: String {
        let fmt = DateFormatter()
        fmt.dateFormat = "EEE, d MMM"
        return fmt.string(from: Date())
    }

    // MARK: - Day Picker (horizontal scroll)

    private var dayPicker: some View {
        ScrollViewReader { proxy in
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 6) {
                    ForEach(viewModel.orderedDays, id: \.self) { day in
                        dayChip(day: day)
                            .id(day)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
            }
            .background(Color.appSurface)
            .onAppear {
                proxy.scrollTo(viewModel.browsingDay, anchor: .center)
            }
        }
    }

    private func dayChip(day: DayOfWeek) -> some View {
        let isToday    = day == viewModel.currentDay
        let isSelected = day == viewModel.browsingDay

        return Button {
            withAnimation(.easeInOut(duration: 0.15)) {
                viewModel.browsingDay = day
            }
        } label: {
            VStack(spacing: 2) {
                Text(day.displayName.prefix(3))
                    .font(.caption.bold())
                if isToday {
                    Circle()
                        .fill(Color.appGreen)
                        .frame(width: 5, height: 5)
                }
            }
            .frame(width: 52, height: 40)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(isSelected ? Color.appGreen : Color.appBg)
            )
            .foregroundStyle(isSelected ? .white : (isToday ? Color.appGreen : .secondary))
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(isToday && !isSelected ? Color.appGreen.opacity(0.5) : Color.clear, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Meal Card

    private func mealCard(meal: MealType, items: [LocalMenuItem]) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            // Meal header
            HStack(spacing: 8) {
                Image(systemName: meal.icon)
                    .font(.subheadline.bold())
                    .foregroundStyle(Color.appGreen)
                Text(meal.displayName)
                    .font(.headline)
                    .foregroundStyle(.white)
                Spacer()
                let total = items.reduce(0.0) { $0 + $1.calories }
                Text("~\(Int(total)) kcal")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Divider().overlay(Color.appGreen.opacity(0.2))

            // Item list
            ForEach(items) { item in
                menuItemRow(item: item)
            }
        }
        .padding(14)
        .background(Color.appSurface, in: RoundedRectangle(cornerRadius: 14))
    }

    // MARK: - Item Row

    private func menuItemRow(item: LocalMenuItem) -> some View {
        HStack(spacing: 10) {
            Circle()
                .fill(Color.appGreen.opacity(0.25))
                .frame(width: 8, height: 8)

            VStack(alignment: .leading, spacing: 1) {
                Text(item.name)
                    .font(.subheadline)
                    .foregroundStyle(.white)
                    .lineLimit(1)
                Text(item.servingDescription)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 1) {
                Text("\(Int(item.calories)) kcal")
                    .font(.caption.bold())
                    .foregroundStyle(Color.appGreenLight)
                HStack(spacing: 4) {
                    Text("P:\(Int(item.protein))g")
                    Text("C:\(Int(item.carbs))g")
                    Text("F:\(Int(item.fat))g")
                }
                .font(.system(size: 10))
                .foregroundStyle(.secondary)
            }
        }
    }
}
