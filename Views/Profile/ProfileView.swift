import SwiftUI

// MARK: - ProfileViewModel

@MainActor
final class ProfileViewModel: ObservableObject {
    @Published var profile: UserProfile?
    @Published var isLoading = false

    private let client = SupabaseManager.shared.client

    func load() async {
        isLoading = true
        defer { isLoading = false }
        do {
            let session = try await client.auth.session
            let rows: [UserProfile] = try await client
                .from("users")
                .select()
                .eq("id", value: session.user.id.uuidString)
                .limit(1)
                .execute()
                .value
            profile = rows.first
        } catch {
            // No session or network error — profile stays nil, UI shows "User"
        }
    }
}

// MARK: - ProfileView

struct ProfileView: View {
    @EnvironmentObject var authService: AuthService
    @StateObject private var vm = ProfileViewModel()
    @ObservedObject private var goalsService = GoalsService.shared
    @State private var showGoalEditor = false

    var body: some View {
        NavigationStack {
            ZStack {
                Color.appBg.ignoresSafeArea()

                if vm.isLoading {
                    loadingView
                } else {
                    scrollContent
                }
            }
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.large)
            .task { await vm.load() }
            .sheet(isPresented: $showGoalEditor) {
                GoalEditorView()
            }
        }
    }

    // MARK: - Loading

    private var loadingView: some View {
        VStack(spacing: 12) {
            ProgressView()
                .tint(Color.appGreen)
            Text("Loading profile…")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }

    // MARK: - Scrollable content

    private var scrollContent: some View {
        ScrollView {
            VStack(spacing: 20) {
                profileHeader
                goalsSection
                nutritionInsightCard
                accountSection
                Color.clear.frame(height: 24)
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)
        }
    }

    // MARK: - Profile Header

    private var profileHeader: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(Color.appGreen.opacity(0.2))
                    .frame(width: 72, height: 72)
                Text(initials)
                    .font(.title.bold())
                    .foregroundStyle(Color.appGreen)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(vm.profile?.name ?? "User")
                    .font(.title2.bold())
                    .foregroundStyle(.white)

                if let p = vm.profile {
                    Text("\(Int(p.heightCm)) cm · \(String(format: "%.1f", p.weightKg)) kg · \(p.age) yrs")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Text(p.goal.displayName)
                        .font(.caption.bold())
                        .foregroundStyle(Color.appGreen)
                }
            }
            Spacer()
        }
        .padding(16)
        .background(Color.appSurface, in: RoundedRectangle(cornerRadius: 20))
    }

    private var initials: String {
        guard let name = vm.profile?.name, !name.isEmpty else { return "?" }
        return name.split(separator: " ")
            .prefix(2)
            .compactMap { $0.first.map(String.init) }
            .joined()
            .uppercased()
    }

    // MARK: - Goals Section

    private var goalsSection: some View {
        VStack(spacing: 14) {
            HStack {
                Label("Daily Goals", systemImage: "target")
                    .font(.headline)
                    .foregroundStyle(.white)
                Spacer()
                Button {
                    showGoalEditor = true
                } label: {
                    Label("Edit", systemImage: "pencil")
                        .font(.subheadline)
                        .foregroundStyle(Color.appGreen)
                }
            }

            HStack(spacing: 0) {
                goalChip(
                    label: "Calories",
                    value: "\(goalsService.goals.dailyCalories)",
                    unit: "kcal",
                    color: Color.appGreen
                )
                goalChip(
                    label: "Protein",
                    value: "\(goalsService.goals.proteinTarget)",
                    unit: "g",
                    color: Color.appProtein
                )
                goalChip(
                    label: "Carbs",
                    value: "\(goalsService.goals.carbsTarget)",
                    unit: "g",
                    color: Color.appCarbs
                )
                goalChip(
                    label: "Fat",
                    value: "\(goalsService.goals.fatTarget)",
                    unit: "g",
                    color: Color.appFat
                )
            }
        }
        .padding(16)
        .background(Color.appSurface, in: RoundedRectangle(cornerRadius: 16))
    }

    private func goalChip(label: String, value: String, unit: String, color: Color) -> some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundStyle(color)
                .monospacedDigit()
            Text(unit)
                .font(.caption2)
                .foregroundStyle(.secondary)
            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 4)
    }

    // MARK: - Nutrition Insight Card

    private var nutritionInsightCard: some View {
        let profile = vm.profile
        let g = goalsService.goals

        return VStack(alignment: .leading, spacing: 10) {
            Label("Nutrition Insight", systemImage: "lightbulb.fill")
                .font(.headline)
                .foregroundStyle(.white)

            if let p = profile {
                let tdee = NutritionCalculator.tdee(
                    weightKg: p.weightKg,
                    heightCm: p.heightCm,
                    age: p.age,
                    activityMultiplier: p.activityLevel.multiplier
                )
                let suggestedTarget = NutritionCalculator.dailyCalorieTarget(tdee: tdee, goal: p.goal)
                let macros = NutritionCalculator.macroTargets(dailyCalories: suggestedTarget, goal: p.goal)

                VStack(spacing: 6) {
                    insightRow(
                        label: "Estimated TDEE",
                        value: "\(Int(tdee)) kcal",
                        icon: "flame.fill",
                        color: .orange
                    )
                    insightRow(
                        label: "Suggested calorie target",
                        value: "\(suggestedTarget) kcal",
                        icon: "target",
                        color: Color.appGreen
                    )
                    insightRow(
                        label: "Suggested macros (P / C / F)",
                        value: "\(macros.protein)g / \(macros.carbs)g / \(macros.fat)g",
                        icon: "chart.bar.fill",
                        color: Color.appProtein
                    )
                }

                if abs(suggestedTarget - g.dailyCalories) > 150 {
                    HStack(spacing: 6) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.caption)
                            .foregroundStyle(.orange)
                        Text("Your current calorie goal (\(g.dailyCalories) kcal) differs from the suggested target. Tap Edit to align.")
                            .font(.caption2)
                            .foregroundStyle(.orange)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(.top, 4)
                }
            } else {
                Text("Profile data unavailable — log in to see your personalised nutrition insight.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(16)
        .background(Color.appSurface, in: RoundedRectangle(cornerRadius: 16))
    }

    private func insightRow(label: String, value: String, icon: String, color: Color) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundStyle(color)
                .frame(width: 18)
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .font(.caption.bold())
                .foregroundStyle(.white)
        }
    }

    // MARK: - Account Section

    private var accountSection: some View {
        VStack(spacing: 0) {
            HStack {
                Label("Account", systemImage: "person.circle")
                    .font(.headline)
                    .foregroundStyle(.white)
                Spacer()
            }
            .padding(.bottom, 12)

            Button {
                Task { try? await authService.signOut() }
            } label: {
                HStack {
                    Image(systemName: "rectangle.portrait.and.arrow.right")
                        .foregroundStyle(.red)
                    Text("Sign Out")
                        .foregroundStyle(.red)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(14)
                .background(Color.appBg, in: RoundedRectangle(cornerRadius: 12))
            }
            .buttonStyle(.plain)
        }
        .padding(16)
        .background(Color.appSurface, in: RoundedRectangle(cornerRadius: 16))
    }
}
