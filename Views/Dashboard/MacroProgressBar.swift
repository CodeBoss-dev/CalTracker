import SwiftUI

// MARK: - MacroProgressBar
//
// Horizontal progress bar for a single macro nutrient.
// Shows label, current value, target, and an animated fill bar.

struct MacroProgressBar: View {
    let label: String
    let value: Double
    let target: Double
    let color: Color
    var unit: String = "g"

    private var progress: Double { min(value / max(target, 1), 1.0) }
    private var isOver: Bool { value > target }

    var body: some View {
        VStack(alignment: .leading, spacing: 7) {
            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text(label)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.white)
                Spacer()
                Text("\(Int(value))\(unit)")
                    .font(.subheadline.bold())
                    .foregroundStyle(isOver ? Color.red : color)
                Text("/ \(Int(target))\(unit)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(color.opacity(0.15))
                        .frame(height: 8)
                    Capsule()
                        .fill(isOver ? Color.red : color)
                        .frame(width: geo.size.width * progress, height: 8)
                        .animation(.spring(response: 0.6, dampingFraction: 0.75), value: progress)
                }
            }
            .frame(height: 8)
        }
    }
}
