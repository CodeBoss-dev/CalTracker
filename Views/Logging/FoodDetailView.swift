import SwiftUI

struct FoodDetailView: View {
    let food: Food
    @State var mealType: MealType
    /// Closure called when "Add to Log" is tapped. Wired up fully in Phase 4.
    var onAdd: ((Food, Double, MealType) -> Void)?

    @State private var servings: Double = 1.0
    @State private var showAddedAlert = false
    @Environment(\.dismiss) private var dismiss

    // MARK: - Computed Nutrition

    private var calories: Double { food.caloriesPerServing * servings }
    private var protein: Double  { food.protein * servings }
    private var carbs: Double    { food.carbs * servings }
    private var fat: Double      { food.fat * servings }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.appBg.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {
                        headerCard
                        nutritionCard
                        servingPickerCard
                        mealPickerCard
                        addButton
                    }
                    .padding(16)
                }
            }
            .navigationTitle(food.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") { dismiss() }
                        .foregroundStyle(Color.appGreenLight)
                }
            }
            .alert("Added to \(mealType.displayName)!", isPresented: $showAddedAlert) {
                Button("OK") { dismiss() }
            } message: {
                Text("\(food.name) — \(Int(calories)) kcal")
            }
        }
    }

    // MARK: - Header Card

    private var headerCard: some View {
        HStack(spacing: 16) {
            ZStack {
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color.appGreen.opacity(0.15))
                    .frame(width: 60, height: 60)
                Image(systemName: food.category.icon)
                    .font(.system(size: 26))
                    .foregroundStyle(Color.appGreen)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(food.name)
                    .font(.title3.bold())
                    .foregroundStyle(.white)
                Text(food.category.displayName)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Text("Per \(food.servingDescription)")
                    .font(.caption)
                    .foregroundStyle(Color.appGreenLight.opacity(0.8))
            }

            Spacer()
        }
        .padding(16)
        .background(Color.appSurface, in: RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - Nutrition Card

    private var nutritionCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Nutrition")
                .font(.headline)
                .foregroundStyle(.white)

            // Calories big display
            HStack {
                Text("\(Int(calories))")
                    .font(.system(size: 48, weight: .bold, design: .rounded))
                    .foregroundStyle(Color.appGreen)
                Text("kcal")
                    .font(.title3)
                    .foregroundStyle(.secondary)
                    .padding(.top, 12)
                Spacer()
            }

            // Macro bars
            VStack(spacing: 10) {
                MacroRow(label: "Protein", value: protein, unit: "g", color: Color.appProtein, total: 120)
                MacroRow(label: "Carbs",   value: carbs,   unit: "g", color: Color.appCarbs,   total: 200)
                MacroRow(label: "Fat",     value: fat,     unit: "g", color: Color.appFat,      total: 55)
            }
        }
        .padding(16)
        .background(Color.appSurface, in: RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - Serving Picker Card

    private var servingPickerCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Servings")
                .font(.headline)
                .foregroundStyle(.white)

            HStack(spacing: 0) {
                // Minus
                StepButton(icon: "minus") {
                    if servings > 0.5 { servings = (servings - 0.5).rounded(toPlaces: 1) }
                }

                Spacer()

                VStack(spacing: 2) {
                    Text(servings.formatted())
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                    Text(food.servingUnit + (servings == 1 ? "" : "s"))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                // Plus
                StepButton(icon: "plus") {
                    servings = (servings + 0.5).rounded(toPlaces: 1)
                }
            }
            .padding(.horizontal, 8)

            // Quick presets
            HStack(spacing: 8) {
                ForEach([0.5, 1.0, 1.5, 2.0, 3.0], id: \.self) { preset in
                    Button {
                        servings = preset
                    } label: {
                        Text(preset.formatted())
                            .font(.caption.bold())
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 6)
                            .background(servings == preset ? Color.appGreen : Color.appBg)
                            .foregroundStyle(servings == preset ? .white : Color.appGreenLight)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                }
            }
        }
        .padding(16)
        .background(Color.appSurface, in: RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - Meal Picker Card

    private var mealPickerCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Meal")
                .font(.headline)
                .foregroundStyle(.white)

            HStack(spacing: 8) {
                ForEach(MealType.allCases, id: \.self) { meal in
                    Button {
                        mealType = meal
                    } label: {
                        VStack(spacing: 4) {
                            Image(systemName: meal.icon)
                                .font(.system(size: 18))
                            Text(meal.displayName)
                                .font(.caption.bold())
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(mealType == meal ? Color.appGreen : Color.appBg)
                        .foregroundStyle(mealType == meal ? .white : Color.appGreenLight)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                    }
                }
            }
        }
        .padding(16)
        .background(Color.appSurface, in: RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - Add Button

    private var addButton: some View {
        Button {
            if let onAdd {
                onAdd(food, servings, mealType)
            } else {
                // Phase 4 will inject the real handler; show confirmation for now
                showAddedAlert = true
            }
        } label: {
            HStack {
                Image(systemName: "plus.circle.fill")
                Text("Add to \(mealType.displayName)")
                    .fontWeight(.bold)
                Spacer()
                Text("\(Int(calories)) kcal")
                    .fontWeight(.semibold)
            }
            .padding(16)
            .background(Color.appGreen, in: RoundedRectangle(cornerRadius: 14))
            .foregroundStyle(.white)
        }
    }
}

// MARK: - MacroRow

private struct MacroRow: View {
    let label: String
    let value: Double
    let unit: String
    let color: Color
    let total: Double

    private var fraction: Double { min(value / total, 1.0) }

    var body: some View {
        VStack(spacing: 4) {
            HStack {
                Text(label)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
                Text("\(value, specifier: "%.1f") \(unit)")
                    .font(.caption.bold())
                    .foregroundStyle(.white)
            }
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(color.opacity(0.15))
                        .frame(height: 6)
                    Capsule()
                        .fill(color)
                        .frame(width: geo.size.width * fraction, height: 6)
                }
            }
            .frame(height: 6)
        }
    }
}

// MARK: - Step Button

private struct StepButton: View {
    let icon: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.title2.bold())
                .frame(width: 44, height: 44)
                .background(Color.appGreen.opacity(0.15))
                .foregroundStyle(Color.appGreen)
                .clipShape(Circle())
        }
    }
}

// MARK: - Double helper

private extension Double {
    func rounded(toPlaces places: Int) -> Double {
        let divisor = pow(10.0, Double(places))
        return (self * divisor).rounded() / divisor
    }

    func formatted() -> String {
        truncatingRemainder(dividingBy: 1) == 0
            ? String(format: "%.0f", self)
            : String(format: "%.1f", self)
    }
}
