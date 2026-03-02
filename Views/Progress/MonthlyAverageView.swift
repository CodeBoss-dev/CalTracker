import SwiftUI

// MARK: - MonthlyAverageView
//
// Card showing three 30-day summary stats: average calories, average protein, days logged.
// The average-calories value turns red when it exceeds the calorie target.

struct MonthlyAverageView: View {
    let avgCalories: Double
    let avgProtein: Double
    let daysLogged: Int
    let calorieTarget: Double

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("30-Day Summary")
                .font(.headline)
                .foregroundStyle(.white)

            HStack(spacing: 0) {
                statItem(
                    value: avgCalories > 0 ? "\(Int(avgCalories))" : "—",
                    unit: "kcal/day",
                    label: "Avg Calories",
                    color: colorForCalories
                )
                divider
                statItem(
                    value: avgProtein > 0 ? "\(Int(avgProtein))g" : "—",
                    unit: "per day",
                    label: "Avg Protein",
                    color: Color.appProtein
                )
                divider
                statItem(
                    value: "\(daysLogged)",
                    unit: "/ 30",
                    label: "Days Logged",
                    color: Color.appGreenLight
                )
            }
        }
        .padding(16)
        .background(Color.appSurface, in: RoundedRectangle(cornerRadius: 16))
    }

    private var colorForCalories: Color {
        guard avgCalories > 0 else { return .secondary }
        return avgCalories <= calorieTarget ? Color.appGreen : Color.red.opacity(0.85)
    }

    private func statItem(value: String, unit: String, label: String, color: Color) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .foregroundStyle(color)
            Text(unit)
                .font(.system(size: 10))
                .foregroundStyle(.secondary)
            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }

    private var divider: some View {
        Rectangle()
            .fill(Color.white.opacity(0.08))
            .frame(width: 1, height: 44)
    }
}
