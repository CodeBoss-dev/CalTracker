import SwiftUI

// MARK: - ProgressDashboardView
//
// Tab 4 — the Progress screen.
// Shows weight tracking, logging streak, weekly calorie chart, and 30-day averages.
// Named ProgressDashboardView to avoid shadowing SwiftUI.ProgressView.

struct ProgressDashboardView: View {
    @StateObject private var progressVM = ProgressViewModel()
    @State private var showWeightEntry = false

    var body: some View {
        NavigationStack {
            ZStack {
                Color.appBg.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 18) {
                        // -- Weight --
                        sectionHeader("Weight")
                        weightCard

                        // -- Streak --
                        sectionHeader("Logging Streak")
                        StreakView(
                            currentStreak: progressVM.currentStreak,
                            longestStreak: progressVM.longestStreak30
                        )

                        // -- Weekly chart --
                        sectionHeader("This Week")
                        WeeklyTrendsChart(
                            data: progressVM.last7DaysCalories,
                            target: progressVM.calorieTarget
                        )

                        // -- 30-day summary --
                        sectionHeader("30-Day Stats")
                        MonthlyAverageView(
                            avgCalories: progressVM.avgCaloriesLast30,
                            avgProtein: progressVM.avgProteinLast30,
                            daysLogged: progressVM.daysLoggedLast30,
                            calorieTarget: progressVM.calorieTarget
                        )

                        Color.clear.frame(height: 20)
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 12)
                }
            }
            .navigationTitle("Progress")
            .navigationBarTitleDisplayMode(.inline)
        }
        .sheet(isPresented: $showWeightEntry) {
            WeightLogEntryView(currentWeight: progressVM.latestWeight?.weight) { kg in
                WeightLogService.shared.log(weight: kg)
            }
            .presentationDetents([.medium])
            .presentationDragIndicator(.hidden) // handled by our own handle bar
        }
    }

    // MARK: - Weight card

    private var weightCard: some View {
        VStack(spacing: 16) {
            // Header row with "Log" button
            HStack {
                Text("Current Weight")
                    .font(.headline)
                    .foregroundStyle(.white)
                Spacer()
                Button { showWeightEntry = true } label: {
                    Label("Log", systemImage: "plus")
                        .font(.subheadline.bold())
                        .foregroundStyle(.black)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 7)
                        .background(Color.appGreen)
                        .clipShape(Capsule())
                }
            }

            if let latest = progressVM.latestWeight {
                latestWeightRow(latest)
                recentWeightHistory
            } else {
                weightEmptyState
            }
        }
        .padding(16)
        .background(Color.appSurface, in: RoundedRectangle(cornerRadius: 16))
    }

    private func latestWeightRow(_ entry: WeightEntry) -> some View {
        HStack(alignment: .bottom, spacing: 8) {
            Text(String(format: "%.1f", entry.weight))
                .font(.system(size: 52, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
            Text("kg")
                .font(.title2)
                .foregroundStyle(.secondary)
                .padding(.bottom, 6)

            Spacer()

            if let change = progressVM.weightChange30Days {
                VStack(alignment: .trailing, spacing: 2) {
                    Text(String(format: "%+.1f kg", change))
                        .font(.system(size: 18, weight: .semibold, design: .rounded))
                        .foregroundStyle(change <= 0 ? Color.appGreen : Color.red.opacity(0.85))
                    Text("last 30 days")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    @ViewBuilder
    private var recentWeightHistory: some View {
        let recent = Array(progressVM.recentWeightEntries.suffix(5).reversed())
        if !recent.isEmpty {
            Divider().background(Color.white.opacity(0.08))
            ForEach(recent) { entry in
                HStack {
                    Text(formattedDate(entry.date))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text(String(format: "%.1f kg", entry.weight))
                        .font(.caption.bold())
                        .foregroundStyle(.white)
                }
            }
        }
    }

    private var weightEmptyState: some View {
        VStack(spacing: 10) {
            Image(systemName: "scalemass")
                .font(.system(size: 40))
                .foregroundStyle(Color.appGreen.opacity(0.45))
            Text("No weight logged yet")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Text("Tap + Log to start tracking")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
    }

    // MARK: - Helpers

    private func sectionHeader(_ title: String) -> some View {
        Text(title)
            .font(.headline)
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func formattedDate(_ dateStr: String) -> String {
        let parser = DateFormatter()
        parser.locale = Locale(identifier: "en_US_POSIX")
        parser.dateFormat = "yyyy-MM-dd"
        guard let date = parser.date(from: dateStr) else { return dateStr }
        let out = DateFormatter()
        out.dateFormat = "MMM d"
        return out.string(from: date)
    }
}
