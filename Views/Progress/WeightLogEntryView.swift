import SwiftUI

// MARK: - WeightLogEntryView
//
// Bottom sheet for logging today's weight.
// Uses a stepper-style UI (±0.1 kg) so the keyboard never appears.
// Pre-populated with the most recent logged weight (or 74 kg as default).

struct WeightLogEntryView: View {
    @Environment(\.dismiss) private var dismiss
    let onSave: (Double) -> Void

    @State private var weight: Double

    init(currentWeight: Double?, onSave: @escaping (Double) -> Void) {
        self._weight = State(initialValue: currentWeight ?? 74.0)
        self.onSave = onSave
    }

    var body: some View {
        ZStack {
            Color.appBg.ignoresSafeArea()

            VStack(spacing: 0) {
                handleBar
                    .padding(.top, 12)

                Text("Log Weight")
                    .font(.title2.bold())
                    .foregroundStyle(.white)
                    .padding(.top, 20)

                weightDisplay
                    .padding(.top, 28)

                stepperButtons
                    .padding(.top, 24)

                quickAdjustButtons
                    .padding(.top, 16)

                Spacer()

                saveButton
                    .padding(.horizontal, 24)
                    .padding(.bottom, 32)
            }
        }
    }

    // MARK: - Sub-views

    private var handleBar: some View {
        Capsule()
            .fill(Color.white.opacity(0.2))
            .frame(width: 40, height: 4)
    }

    private var weightDisplay: some View {
        VStack(spacing: 6) {
            Text(String(format: "%.1f", weight))
                .font(.system(size: 64, weight: .bold, design: .rounded))
                .foregroundStyle(Color.appGreen)
                .contentTransition(.numericText())
                .animation(.spring(response: 0.3), value: weight)
            Text("kg")
                .font(.title3)
                .foregroundStyle(.secondary)
        }
    }

    private var stepperButtons: some View {
        HStack(spacing: 32) {
            Button {
                adjust(by: -0.1)
            } label: {
                Image(systemName: "minus.circle.fill")
                    .font(.system(size: 50))
                    .foregroundStyle(Color.appGreen.opacity(0.8))
            }
            Button {
                adjust(by: 0.1)
            } label: {
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 50))
                    .foregroundStyle(Color.appGreen)
            }
        }
    }

    private var quickAdjustButtons: some View {
        HStack(spacing: 10) {
            ForEach([-1.0, -0.5, 0.5, 1.0], id: \.self) { delta in
                Button {
                    adjust(by: delta)
                } label: {
                    Text(delta > 0 ? "+\(String(format: "%g", delta))" : "\(String(format: "%g", delta))")
                        .font(.caption.bold())
                        .foregroundStyle(.white)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(Color.appSurface)
                        .clipShape(Capsule())
                }
            }
        }
    }

    private var saveButton: some View {
        Button {
            onSave(weight)
            dismiss()
        } label: {
            Text("Save Weight")
                .font(.headline)
                .foregroundStyle(.black)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(Color.appGreen)
                .clipShape(RoundedRectangle(cornerRadius: 16))
        }
    }

    // MARK: - Helpers

    private func adjust(by delta: Double) {
        let newWeight = (weight + delta).rounded(toPlaces: 1)
        weight = min(max(newWeight, 30), 200)
    }
}

// MARK: - Double rounding helper

private extension Double {
    func rounded(toPlaces places: Int) -> Double {
        let multiplier = pow(10.0, Double(places))
        return (self * multiplier).rounded() / multiplier
    }
}
