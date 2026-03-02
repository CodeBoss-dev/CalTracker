import SwiftUI

// MARK: - StreakView
//
// Displays the current logging streak and best streak within the last 30 days.
// Uses a flame icon that lights up when the streak is active.

struct StreakView: View {
    let currentStreak: Int
    let longestStreak: Int

    var body: some View {
        HStack(spacing: 16) {
            flameIcon
            infoText
            Spacer()
            if currentStreak > 0 {
                streakBadge
            }
        }
        .padding(16)
        .background(Color.appSurface, in: RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - Sub-views

    private var flameIcon: some View {
        ZStack {
            Circle()
                .fill(currentStreak > 0 ? Color.orange.opacity(0.18) : Color.gray.opacity(0.12))
                .frame(width: 52, height: 52)
            Image(systemName: "flame.fill")
                .font(.system(size: 26))
                .foregroundStyle(currentStreak > 0 ? Color.orange : Color.gray.opacity(0.5))
        }
    }

    private var infoText: some View {
        VStack(alignment: .leading, spacing: 4) {
            if currentStreak == 0 {
                Text("Start your streak!")
                    .font(.headline)
                    .foregroundStyle(.white)
                Text("Log food today to begin")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else {
                Text("\(currentStreak) day\(currentStreak == 1 ? "" : "s") streak")
                    .font(.headline)
                    .foregroundStyle(.white)
                Text("Best this month: \(longestStreak) day\(longestStreak == 1 ? "" : "s")")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var streakBadge: some View {
        Text("🔥 \(currentStreak)")
            .font(.system(size: 22, weight: .bold, design: .rounded))
            .foregroundStyle(Color.orange)
    }
}
