import SwiftUI
import Charts

// MARK: - WeeklyTrendsChart
//
// Bar chart showing calorie intake for each of the last 7 days.
// Bars over the daily target are coloured red; a dashed RuleMark shows the target line.

struct WeeklyTrendsChart: View {
    let data: [DayCalorieData]
    let target: Double

    private var hasData: Bool { data.contains { $0.calories > 0 } }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            headerRow

            if hasData {
                chart
            } else {
                emptyState
            }
        }
        .padding(16)
        .background(Color.appSurface, in: RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - Sub-views

    private var headerRow: some View {
        HStack {
            Text("Weekly Calories")
                .font(.headline)
                .foregroundStyle(.white)
            Spacer()
            HStack(spacing: 6) {
                Capsule()
                    .fill(Color.red.opacity(0.7))
                    .frame(width: 16, height: 2)
                Text("Target")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var chart: some View {
        Chart {
            ForEach(data) { day in
                BarMark(
                    x: .value("Day", day.dayLabel),
                    y: .value("kcal", day.calories)
                )
                .foregroundStyle(
                    day.calories > target
                    ? AnyShapeStyle(Color.red.opacity(0.75))
                    : AnyShapeStyle(Color.appGreen.gradient)
                )
                .cornerRadius(6)
            }

            RuleMark(y: .value("Target", target))
                .foregroundStyle(Color.red.opacity(0.7))
                .lineStyle(StrokeStyle(lineWidth: 1.5, dash: [5, 3]))
                .annotation(position: .trailing, alignment: .leading) {
                    Text("\(Int(target))")
                        .font(.system(size: 9, weight: .medium))
                        .foregroundStyle(Color.red.opacity(0.7))
                }
        }
        .chartYAxis {
            AxisMarks(values: .stride(by: 500)) { _ in
                AxisGridLine()
                    .foregroundStyle(Color.white.opacity(0.08))
                AxisValueLabel()
                    .foregroundStyle(Color.secondary)
            }
        }
        .chartXAxis {
            AxisMarks { _ in
                AxisValueLabel()
                    .foregroundStyle(Color.secondary)
            }
        }
        .chartYScale(domain: 0...(max(data.map(\.calories).max() ?? 0, target) * 1.15))
        .frame(height: 160)
    }

    private var emptyState: some View {
        VStack(spacing: 10) {
            Image(systemName: "chart.bar.xaxis")
                .font(.system(size: 36))
                .foregroundStyle(Color.appGreen.opacity(0.35))
            Text("No food logged this week")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 120)
    }
}
