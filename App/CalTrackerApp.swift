import SwiftUI

@main
struct CalTrackerApp: App {
    @StateObject private var authService = AuthService.shared

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(authService)
                .preferredColorScheme(.dark)
        }
    }
}

// MARK: - Root View (routes based on auth state)

struct RootView: View {
    @EnvironmentObject var authService: AuthService

    var body: some View {
        Group {
            if authService.isLoading {
                SplashView()
            } else if !authService.isAuthenticated {
                LoginView()
            } else if !authService.hasProfile {
                OnboardingView()
            } else {
                ContentView()
            }
        }
        .animation(.easeInOut(duration: 0.3), value: authService.isLoading)
        .animation(.easeInOut(duration: 0.3), value: authService.isAuthenticated)
        .animation(.easeInOut(duration: 0.3), value: authService.hasProfile)
    }
}

// MARK: - Splash Screen

struct SplashView: View {
    var body: some View {
        ZStack {
            Color.appBg.ignoresSafeArea()

            VStack(spacing: 20) {
                Image(systemName: "leaf.circle.fill")
                    .font(.system(size: 80))
                    .foregroundStyle(Color.appGreen)

                VStack(spacing: 6) {
                    Text("CalTracker")
                        .font(.largeTitle.bold())
                        .foregroundStyle(.white)
                    Text("Indian Diet Tracker")
                        .font(.subheadline)
                        .foregroundStyle(Color.appGreenLight)
                }

                ProgressView()
                    .tint(Color.appGreen)
                    .padding(.top, 12)
            }
        }
    }
}
