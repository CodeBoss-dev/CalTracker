import SwiftUI

struct GoalEditorView: View {
    @Environment(\.dismiss) private var dismiss

    @State private var calories: Int
    @State private var protein:  Int
    @State private var carbs:    Int
    @State private var fat:      Int

    init() {
        let g = GoalsService.shared.goals
        _calories = State(initialValue: g.dailyCalories)
        _protein  = State(initialValue: g.proteinTarget)
        _carbs    = State(initialValue: g.carbsTarget)
        _fat      = State(initialValue: g.fatTarget)
    }

    private var macroCalories: Int { protein * 4 + carbs * 4 + fat * 9 }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.appBg.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 16) {
                        infoCard

                        goalRow(
                            title: "Daily Calories", value: $calories,
                            unit: "kcal", color: Color.appGreen,
                            step: 50, range: 1000...4000
                        )
                        goalRow(
                            title: "Protein", value: $protein,
                            unit: "g", color: Color.appProtein,
                            step: 5, range: 40...300
                        )
                        goalRow(
                            title: "Carbohydrates", value: $carbs,
                            unit: "g", color: Color.appCarbs,
                            step: 5, range: 50...500
                        )
                        goalRow(
                            title: "Fat", value: $fat,
                            unit: "g", color: Color.appFat,
                            step: 5, range: 20...200
                        )

                        macroSummary

                        Color.clear.frame(height: 24)
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 16)
                }
            }
            .navigationTitle("Edit Goals")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(.secondary)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        GoalsService.shared.update(
                            calories: calories,
                            protein:  protein,
                            carbs:    carbs,
                            fat:      fat
                        )
                        dismiss()
                    }
                    .fontWeight(.semibold)
                    .foregroundStyle(Color.appGreen)
                }
            }
        }
    }

    // MARK: - Info Card

    private var infoCard: some View {
        HStack(spacing: 10) {
            Image(systemName: "info.circle.fill")
                .foregroundStyle(Color.appGreen)
            Text("Adjust your daily targets. Changes apply immediately to the Dashboard and Log.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(12)
        .background(Color.appSurface, in: RoundedRectangle(cornerRadius: 12))
    }

    // MARK: - Goal Row (slider + stepper buttons)

    private func goalRow(
        title: String,
        value: Binding<Int>,
        unit: String,
        color: Color,
        step: Int,
        range: ClosedRange<Int>
    ) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.white)
                Spacer()
                Text("\(value.wrappedValue) \(unit)")
                    .font(.subheadline.bold())
                    .foregroundStyle(color)
                    .monospacedDigit()
            }
            HStack(spacing: 14) {
                Button {
                    if value.wrappedValue - step >= range.lowerBound {
                        value.wrappedValue -= step
                    }
                } label: {
                    Image(systemName: "minus.circle.fill")
                        .font(.title2)
                        .foregroundStyle(color.opacity(0.6))
                }
                .buttonStyle(.plain)

                Slider(
                    value: Binding(
                        get: { Double(value.wrappedValue) },
                        set: { value.wrappedValue = Int($0) }
                    ),
                    in: Double(range.lowerBound)...Double(range.upperBound),
                    step: Double(step)
                )
                .tint(color)

                Button {
                    if value.wrappedValue + step <= range.upperBound {
                        value.wrappedValue += step
                    }
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.title2)
                        .foregroundStyle(color)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(16)
        .background(Color.appSurface, in: RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - Macro Calorie Breakdown

    private var macroSummary: some View {
        VStack(spacing: 10) {
            Text("Macro Calorie Breakdown")
                .font(.caption)
                .foregroundStyle(.secondary)

            HStack(spacing: 0) {
                macroSlice(label: "P", kcal: protein * 4, total: macroCalories, color: Color.appProtein)
                macroSlice(label: "C", kcal: carbs * 4,   total: macroCalories, color: Color.appCarbs)
                macroSlice(label: "F", kcal: fat * 9,     total: macroCalories, color: Color.appFat)
            }
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .frame(height: 38)

            let diff = abs(macroCalories - calories)
            if diff > 100 {
                HStack(spacing: 6) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.caption)
                        .foregroundStyle(.orange)
                    Text("Macro total (\(macroCalories) kcal) differs from calorie target by \(diff) kcal")
                        .font(.caption2)
                        .foregroundStyle(.orange)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
        .padding(16)
        .background(Color.appSurface, in: RoundedRectangle(cornerRadius: 16))
    }

    private func macroSlice(label: String, kcal: Int, total: Int, color: Color) -> some View {
        let pct = total > 0 ? Double(kcal) / Double(total) : 0.0
        return VStack(spacing: 1) {
            Text(label)
                .font(.caption.bold())
            Text("\(Int(pct * 100))%")
                .font(.system(size: 9))
        }
        .foregroundStyle(.black)
        .frame(maxWidth: .infinity)
        .frame(height: 38)
        .background(color.opacity(pct > 0 ? 1.0 : 0.25))
    }
}
