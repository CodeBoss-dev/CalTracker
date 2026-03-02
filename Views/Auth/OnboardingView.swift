import SwiftUI

struct OnboardingView: View {
    @EnvironmentObject var authService: AuthService

    @State private var step = 0
    @State private var isLoading = false
    @State private var errorMessage: String?

    // Step 1 – Identity
    @State private var name = ""

    // Step 2 – Body measurements
    @State private var heightCm: Double = 170
    @State private var weightKg: Double = 70
    @State private var age: Int = 20

    // Step 3 – Lifestyle
    @State private var activityLevel: ActivityLevel = .moderatelyActive
    @State private var goal: FitnessGoal = .lose

    private let totalSteps = 4

    var body: some View {
        ZStack {
            Color.appBg.ignoresSafeArea()

            VStack(spacing: 0) {
                // Progress bar
                ProgressBar(current: step + 1, total: totalSteps)
                    .padding(.horizontal, 24)
                    .padding(.top, 16)

                // Step content
                TabView(selection: $step) {
                    StepNameView(name: $name)
                        .tag(0)

                    StepMeasurementsView(
                        heightCm: $heightCm,
                        weightKg: $weightKg,
                        age: $age
                    )
                    .tag(1)

                    StepLifestyleView(
                        activityLevel: $activityLevel,
                        goal: $goal
                    )
                    .tag(2)

                    StepReviewView(
                        name: name,
                        heightCm: heightCm,
                        weightKg: weightKg,
                        age: age,
                        activityLevel: activityLevel,
                        goal: goal
                    )
                    .tag(3)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(.easeInOut, value: step)

                // Navigation buttons
                HStack(spacing: 16) {
                    if step > 0 {
                        Button {
                            withAnimation { step -= 1 }
                        } label: {
                            Text("Back")
                                .font(.headline)
                                .frame(maxWidth: .infinity)
                                .frame(height: 52)
                                .background(Color.appSurface)
                                .foregroundStyle(Color.appGreenLight)
                                .clipShape(RoundedRectangle(cornerRadius: 14))
                        }
                    }

                    Button {
                        if step < totalSteps - 1 {
                            withAnimation { step += 1 }
                        } else {
                            Task { await finish() }
                        }
                    } label: {
                        Group {
                            if isLoading {
                                ProgressView().tint(.white)
                            } else {
                                Text(step < totalSteps - 1 ? "Continue" : "Get Started")
                                    .font(.headline)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 52)
                        .background(canContinue ? Color.appGreen : Color.appGreen.opacity(0.4))
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                    }
                    .disabled(!canContinue || isLoading)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 40)

                if let error = errorMessage {
                    Text(error)
                        .font(.footnote)
                        .foregroundStyle(.red)
                        .padding(.horizontal, 24)
                        .padding(.bottom, 8)
                }
            }
        }
    }

    private var canContinue: Bool {
        switch step {
        case 0: return !name.trimmingCharacters(in: .whitespaces).isEmpty
        case 1: return heightCm > 0 && weightKg > 0 && age > 0
        default: return true
        }
    }

    private func finish() async {
        isLoading = true
        errorMessage = nil
        let calculated = calculateGoals()
        do {
            try await authService.createProfile(
                name: name.trimmingCharacters(in: .whitespaces),
                heightCm: heightCm,
                weightKg: weightKg,
                age: age,
                activityLevel: activityLevel,
                goal: goal,
                goals: calculated
            )
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    /// Mifflin-St Jeor BMR → TDEE → goal-adjusted calories + macros
    private func calculateGoals() -> UserGoalsInput {
        // Assuming male (app can be extended with gender field later)
        let bmr = 10 * weightKg + 6.25 * heightCm - 5 * Double(age) + 5
        let tdee = bmr * activityLevel.multiplier
        let targetCalories = max(1200, tdee + goal.calorieAdjustment)

        // Macro splits: protein 30%, carbs 45%, fat 25% — adjusted for deficit
        let proteinCalories = targetCalories * 0.30
        let carbsCalories = targetCalories * 0.45
        let fatCalories = targetCalories * 0.25

        return UserGoalsInput(
            dailyCalories: Int(targetCalories.rounded()),
            proteinTarget: Int((proteinCalories / 4).rounded()),   // 4 kcal/g
            carbsTarget: Int((carbsCalories / 4).rounded()),       // 4 kcal/g
            fatTarget: Int((fatCalories / 9).rounded())            // 9 kcal/g
        )
    }
}

// MARK: - Step 1: Name

private struct StepNameView: View {
    @Binding var name: String

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 32) {
                StepHeader(
                    emoji: "👋",
                    title: "What's your name?",
                    subtitle: "Let's personalise your experience"
                )

                AuthTextField(
                    placeholder: "Your name",
                    text: $name,
                    icon: "person.fill"
                )
                .padding(.horizontal, 24)

                Spacer()
            }
            .padding(.top, 40)
        }
    }
}

// MARK: - Step 2: Measurements

private struct StepMeasurementsView: View {
    @Binding var heightCm: Double
    @Binding var weightKg: Double
    @Binding var age: Int

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 32) {
                StepHeader(
                    emoji: "📏",
                    title: "Body Measurements",
                    subtitle: "Used to calculate your calorie targets"
                )

                VStack(spacing: 20) {
                    NumericInputRow(
                        label: "Height",
                        unit: "cm",
                        value: $heightCm,
                        range: 140...220,
                        step: 1
                    )

                    NumericInputRow(
                        label: "Weight",
                        unit: "kg",
                        value: $weightKg,
                        range: 35...200,
                        step: 0.5
                    )

                    IntInputRow(
                        label: "Age",
                        unit: "years",
                        value: $age,
                        range: 15...80
                    )
                }
                .padding(.horizontal, 24)
            }
            .padding(.top, 40)
        }
    }
}

// MARK: - Step 3: Lifestyle

private struct StepLifestyleView: View {
    @Binding var activityLevel: ActivityLevel
    @Binding var goal: FitnessGoal

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 32) {
                StepHeader(
                    emoji: "🏃",
                    title: "Your Lifestyle",
                    subtitle: "Helps us set the right calorie target"
                )

                VStack(alignment: .leading, spacing: 20) {
                    Text("Activity Level")
                        .font(.headline)
                        .foregroundStyle(.white)
                        .padding(.horizontal, 24)

                    ForEach(ActivityLevel.allCases, id: \.rawValue) { level in
                        SelectionRow(
                            title: level.displayName,
                            isSelected: activityLevel == level
                        ) {
                            activityLevel = level
                        }
                    }

                    Text("Your Goal")
                        .font(.headline)
                        .foregroundStyle(.white)
                        .padding(.horizontal, 24)
                        .padding(.top, 8)

                    ForEach(FitnessGoal.allCases, id: \.rawValue) { g in
                        SelectionRow(
                            title: g.displayName,
                            subtitle: g.description,
                            isSelected: goal == g
                        ) {
                            goal = g
                        }
                    }
                }
            }
            .padding(.top, 40)
        }
    }
}

// MARK: - Step 4: Review targets

private struct StepReviewView: View {
    let name: String
    let heightCm: Double
    let weightKg: Double
    let age: Int
    let activityLevel: ActivityLevel
    let goal: FitnessGoal

    private var calculated: (calories: Int, protein: Int, carbs: Int, fat: Int) {
        let bmr = 10 * weightKg + 6.25 * heightCm - 5 * Double(age) + 5
        let tdee = bmr * activityLevel.multiplier
        let cals = max(1200, tdee + goal.calorieAdjustment)
        return (
            Int(cals.rounded()),
            Int((cals * 0.30 / 4).rounded()),
            Int((cals * 0.45 / 4).rounded()),
            Int((cals * 0.25 / 9).rounded())
        )
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 32) {
                StepHeader(
                    emoji: "🎯",
                    title: "Your Daily Targets",
                    subtitle: "Calculated based on your profile"
                )

                VStack(spacing: 16) {
                    TargetCard(
                        label: "Daily Calories",
                        value: "\(calculated.calories) kcal",
                        color: Color.appGreen
                    )
                    TargetCard(
                        label: "Protein",
                        value: "\(calculated.protein)g",
                        color: Color.appProtein
                    )
                    TargetCard(
                        label: "Carbohydrates",
                        value: "\(calculated.carbs)g",
                        color: Color.appCarbs
                    )
                    TargetCard(
                        label: "Fat",
                        value: "\(calculated.fat)g",
                        color: Color.appFat
                    )
                }
                .padding(.horizontal, 24)

                Text("You can edit these targets anytime from your Profile.")
                    .font(.footnote)
                    .foregroundStyle(Color(white: 0.5))
                    .padding(.horizontal, 24)
            }
            .padding(.top, 40)
        }
    }
}

// MARK: - Sub-components

private struct StepHeader: View {
    let emoji: String
    let title: String
    let subtitle: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(emoji)
                .font(.system(size: 48))
            Text(title)
                .font(.title2.bold())
                .foregroundStyle(.white)
            Text(subtitle)
                .font(.subheadline)
                .foregroundStyle(Color(white: 0.6))
        }
        .padding(.horizontal, 24)
    }
}

private struct ProgressBar: View {
    let current: Int
    let total: Int

    var body: some View {
        HStack(spacing: 6) {
            ForEach(1...total, id: \.self) { i in
                Capsule()
                    .fill(i <= current ? Color.appGreen : Color.appSurface)
                    .frame(height: 4)
                    .animation(.easeInOut, value: current)
            }
        }
    }
}

private struct NumericInputRow: View {
    let label: String
    let unit: String
    @Binding var value: Double
    let range: ClosedRange<Double>
    let step: Double

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.subheadline)
                    .foregroundStyle(Color(white: 0.6))
                Text("\(value, specifier: step < 1 ? "%.1f" : "%.0f") \(unit)")
                    .font(.title3.bold())
                    .foregroundStyle(.white)
            }
            Spacer()
            HStack(spacing: 0) {
                Button {
                    if value - step >= range.lowerBound {
                        value -= step
                    }
                } label: {
                    Image(systemName: "minus")
                        .frame(width: 44, height: 44)
                        .background(Color.appSurface)
                        .foregroundStyle(Color.appGreen)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                }

                Button {
                    if value + step <= range.upperBound {
                        value += step
                    }
                } label: {
                    Image(systemName: "plus")
                        .frame(width: 44, height: 44)
                        .background(Color.appSurface)
                        .foregroundStyle(Color.appGreen)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                }
                .padding(.leading, 8)
            }
        }
        .padding(16)
        .background(Color.appSurface)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

private struct IntInputRow: View {
    let label: String
    let unit: String
    @Binding var value: Int
    let range: ClosedRange<Int>

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.subheadline)
                    .foregroundStyle(Color(white: 0.6))
                Text("\(value) \(unit)")
                    .font(.title3.bold())
                    .foregroundStyle(.white)
            }
            Spacer()
            HStack(spacing: 0) {
                Button {
                    if value - 1 >= range.lowerBound { value -= 1 }
                } label: {
                    Image(systemName: "minus")
                        .frame(width: 44, height: 44)
                        .background(Color.appSurface)
                        .foregroundStyle(Color.appGreen)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                }

                Button {
                    if value + 1 <= range.upperBound { value += 1 }
                } label: {
                    Image(systemName: "plus")
                        .frame(width: 44, height: 44)
                        .background(Color.appSurface)
                        .foregroundStyle(Color.appGreen)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                }
                .padding(.leading, 8)
            }
        }
        .padding(16)
        .background(Color.appSurface)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

private struct SelectionRow: View {
    let title: String
    var subtitle: String? = nil
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.white)
                        .multilineTextAlignment(.leading)
                    if let subtitle {
                        Text(subtitle)
                            .font(.caption)
                            .foregroundStyle(Color(white: 0.5))
                    }
                }
                Spacer()
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(isSelected ? Color.appGreen : Color(white: 0.3))
                    .font(.system(size: 20))
            }
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? Color.appGreen.opacity(0.15) : Color.appSurface)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.appGreen.opacity(0.5) : Color.clear, lineWidth: 1)
            )
        }
        .padding(.horizontal, 24)
    }
}

private struct TargetCard: View {
    let label: String
    let value: String
    let color: Color

    var body: some View {
        HStack {
            HStack(spacing: 10) {
                Circle()
                    .fill(color)
                    .frame(width: 10, height: 10)
                Text(label)
                    .font(.subheadline)
                    .foregroundStyle(Color(white: 0.7))
            }
            Spacer()
            Text(value)
                .font(.title3.bold())
                .foregroundStyle(.white)
        }
        .padding(16)
        .background(Color.appSurface)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}
