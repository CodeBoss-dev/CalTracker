import SwiftUI

struct FoodSearchView: View {
    // Passed in from the parent (e.g. MealLogView in Phase 4)
    let mealType: MealType
    /// Called when user finishes selecting a food + servings
    var onFoodLogged: ((Food, Double, MealType) -> Void)?

    @StateObject private var foodService = FoodService.shared
    @State private var searchText = ""
    @State private var selectedCategory: FoodCategory? = nil
    @State private var results: [Food] = []
    @State private var apiResults: [Food] = []
    @State private var isSearching = false
    @State private var isSearchingAPI = false
    @State private var selectedFood: Food? = nil
    @State private var showCustomEntry = false
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                Color.appBg.ignoresSafeArea()

                VStack(spacing: 0) {
                    // Category filter chips
                    categoryFilterStrip

                    // Results list
                    if isSearching {
                        Spacer()
                        ProgressView()
                            .tint(Color.appGreen)
                        Spacer()
                    } else if results.isEmpty && apiResults.isEmpty && !isSearchingAPI {
                        emptyState
                    } else {
                        resultsList
                    }
                }
            }
            .navigationTitle("Search Food")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(Color.appGreenLight)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showCustomEntry = true
                    } label: {
                        Label("Add Custom", systemImage: "plus")
                            .foregroundStyle(Color.appGreen)
                    }
                }
            }
            .searchable(
                text: $searchText,
                placement: .navigationBarDrawer(displayMode: .always),
                prompt: "Search chapati, dal, biryani…"
            )
            .onChange(of: searchText) { performSearch() }
            .onChange(of: selectedCategory) { performSearch() }
            .onAppear { performSearch() }
            .sheet(item: $selectedFood) { food in
                FoodDetailView(food: food, mealType: mealType) { food, servings, meal in
                    onFoodLogged?(food, servings, meal)
                    dismiss()
                }
            }
            .sheet(isPresented: $showCustomEntry) {
                CustomFoodEntryView(prefillName: searchText) { newFood in
                    selectedFood = newFood
                }
            }
        }
    }

    // MARK: - Subviews

    private var categoryFilterStrip: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                // "All" chip
                CategoryChip(
                    label: "All",
                    icon: "square.grid.2x2.fill",
                    isSelected: selectedCategory == nil
                ) {
                    selectedCategory = nil
                }

                ForEach(FoodCategory.allCases, id: \.self) { cat in
                    CategoryChip(
                        label: cat.displayName,
                        icon: cat.icon,
                        isSelected: selectedCategory == cat
                    ) {
                        selectedCategory = selectedCategory == cat ? nil : cat
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
        }
        .background(Color.appSurface)
    }

    private var resultsList: some View {
        List {
            // Local / Supabase results
            if !results.isEmpty {
                ForEach(results) { food in
                    FoodRow(food: food)
                        .listRowBackground(Color.appSurface)
                        .listRowSeparatorTint(Color.white.opacity(0.08))
                        .contentShape(Rectangle())
                        .onTapGesture {
                            selectedFood = food
                        }
                }
            }

            // USDA API results
            if !apiResults.isEmpty {
                Section {
                    ForEach(apiResults) { food in
                        FoodRow(food: food)
                            .listRowBackground(Color.appSurface)
                            .listRowSeparatorTint(Color.white.opacity(0.08))
                            .contentShape(Rectangle())
                            .onTapGesture {
                                selectedFood = food
                            }
                    }
                } header: {
                    HStack(spacing: 6) {
                        Image(systemName: "globe")
                            .font(.caption2)
                        Text("USDA Food Database")
                            .font(.caption.bold())
                    }
                    .foregroundStyle(Color.appGreenLight)
                    .textCase(nil)
                }
            }

            // Loading indicator for USDA search
            if isSearchingAPI {
                HStack(spacing: 8) {
                    ProgressView()
                        .tint(Color.appGreenLight)
                        .scaleEffect(0.8)
                    Text("Searching online database…")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .listRowBackground(Color.appSurface)
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.vertical, 8)
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: searchText.isEmpty ? "fork.knife" : "magnifyingglass")
                .font(.system(size: 48))
                .foregroundStyle(Color.appGreenLight.opacity(0.5))
            Text(searchText.isEmpty ? "Start typing to search" : "No results for "\(searchText)"")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            if !searchText.isEmpty {
                Button("Add "\(searchText)" as custom food") {
                    showCustomEntry = true
                }
                .font(.subheadline.bold())
                .foregroundStyle(Color.appGreen)
            }
            Spacer()
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Search Logic

    private func performSearch() {
        isSearching = true
        apiResults = []
        isSearchingAPI = false

        Task {
            let foods = (try? await FoodService.shared.searchFoods(
                query: searchText,
                category: selectedCategory
            )) ?? FoodService.shared.searchLocal(query: searchText, category: selectedCategory)
            results = foods
            isSearching = false

            // Auto-search USDA when local results are insufficient
            if foods.count < 3 && searchText.count >= 3 && selectedCategory == nil {
                isSearchingAPI = true
                let usdaFoods = await FoodService.shared.searchUSDA(query: searchText)
                // Filter out USDA results that duplicate local results (by name similarity)
                let localNames = Set(foods.map { $0.name.lowercased() })
                apiResults = usdaFoods.filter { usda in
                    !localNames.contains(where: { usda.name.lowercased().contains($0) || $0.contains(usda.name.lowercased()) })
                }
                isSearchingAPI = false
            }
        }
    }
}

// MARK: - Category Chip

private struct CategoryChip: View {
    let label: String
    let icon: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.caption)
                Text(label)
                    .font(.caption.bold())
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(isSelected ? Color.appGreen : Color.appBg)
            .foregroundStyle(isSelected ? .white : Color.appGreenLight)
            .clipShape(Capsule())
            .overlay(
                Capsule()
                    .strokeBorder(
                        isSelected ? Color.clear : Color.appGreenLight.opacity(0.3),
                        lineWidth: 1
                    )
            )
        }
    }
}

// MARK: - Food Row

struct FoodRow: View {
    let food: Food

    var body: some View {
        HStack(spacing: 12) {
            // Category icon circle
            ZStack {
                Circle()
                    .fill(Color.appGreen.opacity(0.15))
                    .frame(width: 40, height: 40)
                Image(systemName: food.isFromAPI ? "globe" : food.category.icon)
                    .font(.system(size: 16))
                    .foregroundStyle(Color.appGreen)
            }

            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text(food.name)
                        .font(.subheadline.bold())
                        .foregroundStyle(.white)
                        .lineLimit(2)
                    if food.isFromAPI {
                        Text("USDA")
                            .font(.system(size: 9, weight: .semibold))
                            .padding(.horizontal, 5)
                            .padding(.vertical, 2)
                            .background(Color.appGreen.opacity(0.2))
                            .foregroundStyle(Color.appGreen)
                            .clipShape(Capsule())
                    }
                }
                Text(food.isFromAPI ? "per 100g" : food.category.displayName)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Text("\(Int(food.caloriesPerServing)) kcal")
                    .font(.subheadline.bold())
                    .foregroundStyle(Color.appGreen)
                Text(food.servingDescription)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}
