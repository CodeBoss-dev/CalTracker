import SwiftUI

// MARK: - MealSectionCard
//
// Expandable card showing logged items for one meal type.
// Tap the header to collapse / expand the item list.

struct MealSectionCard: View {
    let mealType: MealType
    let items: [LoggedItem]
    let mealCalories: Double

    @State private var isExpanded: Bool = true

    var body: some View {
        VStack(spacing: 0) {
            // Header — always visible
            Button {
                withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                    isExpanded.toggle()
                }
            } label: {
                HStack(spacing: 10) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.appGreen.opacity(0.15))
                            .frame(width: 34, height: 34)
                        Image(systemName: mealType.icon)
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(Color.appGreen)
                    }

                    Text(mealType.displayName)
                        .font(.headline)
                        .foregroundStyle(.white)

                    Spacer()

                    if mealCalories > 0 {
                        Text("\(Int(mealCalories)) kcal")
                            .font(.subheadline.bold())
                            .foregroundStyle(Color.appGreenLight)
                    } else {
                        Text("Nothing logged")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.caption.bold())
                        .foregroundStyle(.secondary)
                        .padding(.leading, 2)
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 13)
            }
            .buttonStyle(.plain)

            // Item list
            if isExpanded && !items.isEmpty {
                Divider()
                    .overlay(Color.white.opacity(0.07))
                    .padding(.horizontal, 14)

                VStack(spacing: 0) {
                    ForEach(items) { item in
                        itemRow(item)
                        if item.id != items.last?.id {
                            Divider()
                                .overlay(Color.white.opacity(0.07))
                                .padding(.horizontal, 14)
                        }
                    }
                }
                .padding(.bottom, 6)
            }
        }
        .background(Color.appSurface, in: RoundedRectangle(cornerRadius: 14))
    }

    // MARK: - Item Row

    private func itemRow(_ item: LoggedItem) -> some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text(item.name)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                Text(item.servingDescription)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 2) {
                Text("\(Int(item.totalCalories)) kcal")
                    .font(.subheadline.bold())
                    .foregroundStyle(Color.appGreenLight)
                HStack(spacing: 6) {
                    macroTag("P", value: item.totalProtein, color: Color.appProtein)
                    macroTag("C", value: item.totalCarbs, color: Color.appCarbs)
                    macroTag("F", value: item.totalFat, color: Color.appFat)
                }
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
    }

    private func macroTag(_ letter: String, value: Double, color: Color) -> some View {
        Text("\(letter):\(Int(value))g")
            .font(.system(size: 10, weight: .medium))
            .foregroundStyle(color.opacity(0.85))
    }
}
