import SwiftUI

// MARK: - MessMenuConfigView
//
// Allows the user to manually select which week cycle (1, 2, or 3)
// the Mess Menu tab should display, or use auto-resolve from today's date.

struct MessMenuConfigView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var viewModel: MessMenuViewModel

    private let autoWeek: Int = WeekResolver.weekNumber(for: Date())

    var body: some View {
        NavigationStack {
            ZStack {
                Color.appBg.ignoresSafeArea()

                VStack(spacing: 20) {
                    headerSection
                    weekSelectionCard
                    Spacer()
                }
                .padding(16)
            }
            .navigationTitle("Menu Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundStyle(Color.appGreenLight)
                }
            }
        }
    }

    // MARK: - Header

    private var headerSection: some View {
        VStack(spacing: 8) {
            Image(systemName: "calendar.badge.clock")
                .font(.system(size: 48))
                .foregroundStyle(Color.appGreen)

            Text("Select Week Cycle")
                .font(.title3.bold())
                .foregroundStyle(.white)

            Text("Choose which week's menu to browse, or let the app auto-detect based on today's date.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 16)
        }
    }

    // MARK: - Week Selection Card

    private var weekSelectionCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("3-Week Cycle")
                .font(.headline)
                .foregroundStyle(.white)

            // Auto option
            autoRow

            Divider().overlay(Color.appGreen.opacity(0.2))

            // Week rows
            weekRow(week: 1, dateRange: "Mar 2–8, then every 3rd week")
            weekRow(week: 2, dateRange: "Feb 23–Mar 1, then every 3rd week")
            weekRow(week: 3, dateRange: "Feb 16–22, then every 3rd week")
        }
        .padding(16)
        .background(Color.appSurface, in: RoundedRectangle(cornerRadius: 14))
    }

    // MARK: - Auto Row

    private var autoRow: some View {
        let isSelected = viewModel.weekOverride == nil

        return Button {
            withAnimation(.easeInOut(duration: 0.15)) {
                viewModel.resetToAutoWeek()
            }
        } label: {
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(isSelected ? Color.appGreen : Color.appBg)
                        .frame(width: 36, height: 36)
                    Image(systemName: "arrow.triangle.2.circlepath")
                        .font(.caption.bold())
                        .foregroundStyle(isSelected ? .white : .secondary)
                }

                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 6) {
                        Text("Auto")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.white)
                        Text("Week \(autoWeek)")
                            .font(.caption)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.appGreen.opacity(0.2))
                            .foregroundStyle(Color.appGreen)
                            .clipShape(Capsule())
                    }
                    Text("Automatically follows the current week cycle")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(Color.appGreen)
                }
            }
        }
        .buttonStyle(.plain)
    }

    // MARK: - Week Row

    private func weekRow(week: Int, dateRange: String) -> some View {
        let isSelected = viewModel.weekOverride == week
        let isCurrent  = autoWeek == week

        return Button {
            withAnimation(.easeInOut(duration: 0.15)) {
                viewModel.weekOverride = week
            }
        } label: {
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(isSelected ? Color.appGreen : Color.appBg)
                        .frame(width: 36, height: 36)
                    Text("W\(week)")
                        .font(.caption.bold())
                        .foregroundStyle(isSelected ? .white : .secondary)
                }

                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 6) {
                        Text("Week \(week)")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.white)
                        if isCurrent {
                            Text("Current")
                                .font(.caption.bold())
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.appGreen.opacity(0.2))
                                .foregroundStyle(Color.appGreen)
                                .clipShape(Capsule())
                        }
                    }
                    Text(dateRange)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(Color.appGreen)
                }
            }
        }
        .buttonStyle(.plain)
    }
}
