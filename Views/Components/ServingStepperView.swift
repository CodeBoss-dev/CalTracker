import SwiftUI

/// Reusable +/- stepper for selecting a serving count in 0.5 increments.
/// Used in MealLogView and available for any future view that needs serving selection.
struct ServingStepperView: View {
    @Binding var servings: Double
    let unit: String
    var min: Double = 0.5
    var step: Double = 0.5

    var body: some View {
        HStack(spacing: 0) {
            stepButton(icon: "minus") {
                if servings > min {
                    servings = (servings - step).rounded(toPlaces: 1)
                }
            }

            Spacer()

            VStack(spacing: 2) {
                Text(servings.stepFormatted)
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                Text(unit + (servings == 1 ? "" : "s"))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            stepButton(icon: "plus") {
                servings = (servings + step).rounded(toPlaces: 1)
            }
        }
    }

    private func stepButton(icon: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.title2.bold())
                .frame(width: 44, height: 44)
                .background(Color.appGreen.opacity(0.15))
                .foregroundStyle(Color.appGreen)
                .clipShape(Circle())
        }
    }
}

// MARK: - Double helpers (private to this file — not visible outside)

private extension Double {
    func rounded(toPlaces places: Int) -> Double {
        let divisor = pow(10.0, Double(places))
        return (self * divisor).rounded() / divisor
    }

    var stepFormatted: String {
        truncatingRemainder(dividingBy: 1) == 0
            ? String(format: "%.0f", self)
            : String(format: "%.1f", self)
    }
}
