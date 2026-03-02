import SwiftUI

// MARK: - SuggestionBannerView
//
// Green-accented card that surfaces a smart meal suggestion from DashboardViewModel.

struct SuggestionBannerView: View {
    let suggestion: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            ZStack {
                Circle()
                    .fill(Color.appGreen.opacity(0.15))
                    .frame(width: 42, height: 42)
                Image(systemName: "lightbulb.fill")
                    .font(.system(size: 18))
                    .foregroundStyle(Color.appGreen)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text("Smart Suggestion")
                    .font(.caption.bold())
                    .foregroundStyle(Color.appGreenLight)
                Text(suggestion)
                    .font(.subheadline)
                    .foregroundStyle(.white)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 0)
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color.appSurface)
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .strokeBorder(Color.appGreen.opacity(0.25), lineWidth: 1)
                )
        )
    }
}
