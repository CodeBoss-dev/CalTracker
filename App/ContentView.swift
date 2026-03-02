import SwiftUI

struct ContentView: View {
    @State private var selectedTab = 0
    @EnvironmentObject var authService: AuthService
    @StateObject private var logViewModel = FoodLogViewModel()

    var body: some View {
        TabView(selection: $selectedTab) {
            // Tab 1: Dashboard ✅ Phase 5
            DashboardView()
                .environmentObject(logViewModel)
                .tabItem { Label("Dashboard", systemImage: "house.fill") }
                .tag(0)

            // Tab 2: Quick Log ✅ Phase 4
            MealLogView()
                .environmentObject(logViewModel)
                .tabItem { Label("Log", systemImage: "plus.circle.fill") }
                .tag(1)

            // Tab 3: Mess Menu ✅ Phase 3
            WeeklyMenuView()
                .tabItem { Label("Menu", systemImage: "menucard.fill") }
                .tag(2)

            // Tab 4: Progress ✅ Phase 7
            ProgressDashboardView()
                .tabItem { Label("Progress", systemImage: "chart.line.uptrend.xyaxis") }
                .tag(3)

            // Tab 5: Profile ✅ Phase 8
            ProfileView()
                .environmentObject(authService)
                .tabItem { Label("Profile", systemImage: "person.fill") }
                .tag(4)
        }
        .tint(Color.appGreen)
    }
}
