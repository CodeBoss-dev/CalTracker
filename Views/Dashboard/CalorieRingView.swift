import SwiftUI

// MARK: - CalorieRingView
//
// Animated circular progress ring.
// Green gradient arc on a dark track; consumed / target kcal in the center.

struct CalorieRingView: View {
    let consumed: Double
    let target: Double
    var ringSize: CGFloat = 200

    private var progress: Double { min(consumed / max(target, 1), 1.0) }
    private var ringWidth: CGFloat { ringSize * 0.095 }
    private var isOver: Bool { consumed > target }

    var body: some View {
        ZStack {
            // Track
            Circle()
                .stroke(Color.appGreen.opacity(0.12), lineWidth: ringWidth)
                .frame(width: ringSize, height: ringSize)

            // Progress arc
            Circle()
                .trim(from: 0, to: progress)
                .stroke(
                    AngularGradient(
                        gradient: Gradient(colors: [Color.appGreen, Color.appGreenLight, Color.appGreen]),
                        center: .center,
                        startAngle: .degrees(-90),
                        endAngle: .degrees(270)
                    ),
                    style: StrokeStyle(lineWidth: ringWidth, lineCap: .round)
                )
                .frame(width: ringSize, height: ringSize)
                .rotationEffect(.degrees(-90))
                .animation(.spring(response: 0.8, dampingFraction: 0.72), value: progress)

            // Center labels
            VStack(spacing: 3) {
                Text("\(Int(consumed))")
                    .font(.system(size: ringSize * 0.19, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .contentTransition(.numericText())
                Text("of \(Int(target)) kcal")
                    .font(.system(size: ringSize * 0.07))
                    .foregroundStyle(.secondary)
                Text(isOver ? "Over target" : "\(Int(target - consumed)) left")
                    .font(.system(size: ringSize * 0.065, weight: .semibold))
                    .foregroundStyle(isOver ? Color.red : Color.appGreenLight)
                    .padding(.top, 2)
            }
        }
    }
}
