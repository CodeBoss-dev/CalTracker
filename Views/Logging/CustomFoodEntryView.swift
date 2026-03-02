import SwiftUI

struct CustomFoodEntryView: View {
    /// Called with the newly created Food after a successful save
    var onSave: ((Food) -> Void)?

    @State private var name: String
    @State private var caloriesText = ""
    @State private var proteinText = ""
    @State private var carbsText = ""
    @State private var fatText = ""
    @State private var servingSizeText = "1"
    @State private var servingUnit = "piece"
    @State private var category: FoodCategory = .snacks

    @State private var isSaving = false
    @State private var errorMessage: String?
    @State private var showError = false

    @Environment(\.dismiss) private var dismiss

    private let servingUnits = ["piece", "katori", "plate", "glass", "bowl", "cup", "tsp", "tbsp", "g", "ml"]

    // Parsed numeric helpers
    private var calories: Double { Double(caloriesText) ?? 0 }
    private var protein: Double  { Double(proteinText) ?? 0 }
    private var carbs: Double    { Double(carbsText) ?? 0 }
    private var fat: Double      { Double(fatText) ?? 0 }
    private var servingSize: Double { Double(servingSizeText) ?? 1 }

    private var isValid: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty && calories > 0
    }

    /// Pre-fills the food name (e.g. from search text). Defaults to empty.
    init(prefillName: String = "", onSave: ((Food) -> Void)? = nil) {
        self._name = State(initialValue: prefillName)
        self.onSave = onSave
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.appBg.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 16) {
                        nameSection
                        nutritionSection
                        servingSection
                        categorySection
                        previewCard
                    }
                    .padding(16)
                }
            }
            .navigationTitle("Custom Food")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(Color.appGreenLight)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") { save() }
                        .fontWeight(.bold)
                        .foregroundStyle(isValid ? Color.appGreen : Color.appGreenLight.opacity(0.4))
                        .disabled(!isValid || isSaving)
                }
            }
            .alert("Error", isPresented: $showError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(errorMessage ?? "Something went wrong.")
            }
        }
    }

    // MARK: - Sections

    private var nameSection: some View {
        SectionCard(title: "Food Name") {
            CustomTextField(placeholder: "e.g. Homemade Khichdi", text: $name)
        }
    }

    private var nutritionSection: some View {
        SectionCard(title: "Nutrition (per serving)") {
            VStack(spacing: 10) {
                NutritionField(label: "Calories *", unit: "kcal", color: Color.appGreen, text: $caloriesText)
                NutritionField(label: "Protein",   unit: "g",    color: Color.appProtein, text: $proteinText)
                NutritionField(label: "Carbs",     unit: "g",    color: Color.appCarbs,   text: $carbsText)
                NutritionField(label: "Fat",       unit: "g",    color: Color.appFat,     text: $fatText)
            }
        }
    }

    private var servingSection: some View {
        SectionCard(title: "Serving Info") {
            VStack(spacing: 10) {
                HStack {
                    Text("Size")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Spacer()
                    TextField("1", text: $servingSizeText)
                        .keyboardType(.decimalPad)
                        .multilineTextAlignment(.trailing)
                        .font(.subheadline.bold())
                        .foregroundStyle(.white)
                        .frame(width: 60)
                }

                Divider().background(Color.white.opacity(0.1))

                HStack {
                    Text("Unit")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Picker("Unit", selection: $servingUnit) {
                        ForEach(servingUnits, id: \.self) { unit in
                            Text(unit).tag(unit)
                        }
                    }
                    .pickerStyle(.menu)
                    .tint(Color.appGreen)
                }
            }
        }
    }

    private var categorySection: some View {
        SectionCard(title: "Category") {
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 3), spacing: 8) {
                ForEach(FoodCategory.allCases, id: \.self) { cat in
                    Button {
                        category = cat
                    } label: {
                        VStack(spacing: 4) {
                            Image(systemName: cat.icon)
                                .font(.system(size: 16))
                            Text(cat.displayName)
                                .font(.system(size: 10, weight: .medium))
                                .multilineTextAlignment(.center)
                                .lineLimit(2)
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(category == cat ? Color.appGreen : Color.appBg)
                        .foregroundStyle(category == cat ? .white : Color.appGreenLight)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                    }
                }
            }
        }
    }

    private var previewCard: some View {
        SectionCard(title: "Preview") {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(name.isEmpty ? "Food Name" : name)
                        .font(.subheadline.bold())
                        .foregroundStyle(name.isEmpty ? .secondary : .white)
                    Text("\(servingSize.formatted()) \(servingUnit)  ·  \(category.displayName)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 2) {
                    Text("\(Int(calories)) kcal")
                        .font(.subheadline.bold())
                        .foregroundStyle(Color.appGreen)
                    Text("P \(Int(protein))g  C \(Int(carbs))g  F \(Int(fat))g")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    // MARK: - Save

    private func save() {
        isSaving = true
        Task {
            do {
                let food = try await FoodService.shared.addCustomFood(
                    name: name.trimmingCharacters(in: .whitespaces),
                    caloriesPerServing: calories,
                    protein: protein,
                    carbs: carbs,
                    fat: fat,
                    servingUnit: servingUnit,
                    servingSize: servingSize,
                    category: category
                )
                onSave?(food)
                dismiss()
            } catch {
                errorMessage = error.localizedDescription
                showError = true
            }
            isSaving = false
        }
    }
}

// MARK: - Section Card

private struct SectionCard<Content: View>: View {
    let title: String
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.headline)
                .foregroundStyle(.white)
            content
        }
        .padding(16)
        .background(Color.appSurface, in: RoundedRectangle(cornerRadius: 16))
    }
}

// MARK: - Custom TextField

private struct CustomTextField: View {
    let placeholder: String
    @Binding var text: String

    var body: some View {
        TextField(placeholder, text: $text)
            .font(.subheadline)
            .foregroundStyle(.white)
            .padding(12)
            .background(Color.appBg, in: RoundedRectangle(cornerRadius: 10))
    }
}

// MARK: - Nutrition Field

private struct NutritionField: View {
    let label: String
    let unit: String
    let color: Color
    @Binding var text: String

    var body: some View {
        HStack {
            Circle()
                .fill(color.opacity(0.25))
                .frame(width: 8, height: 8)
            Text(label)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Spacer()
            HStack(spacing: 4) {
                TextField("0", text: $text)
                    .keyboardType(.decimalPad)
                    .multilineTextAlignment(.trailing)
                    .font(.subheadline.bold())
                    .foregroundStyle(.white)
                    .frame(width: 70)
                Text(unit)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .frame(width: 28, alignment: .leading)
            }
        }
    }
}

// MARK: - Double formatted helper (same as FoodDetailView)

private extension Double {
    func formatted() -> String {
        truncatingRemainder(dividingBy: 1) == 0
            ? String(format: "%.0f", self)
            : String(format: "%.1f", self)
    }
}
