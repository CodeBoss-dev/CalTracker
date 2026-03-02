import Foundation
import Supabase

@MainActor
final class AuthService: ObservableObject {
    static let shared = AuthService()

    // MARK: - Published State

    @Published var isLoading = true
    @Published var isAuthenticated = false
    @Published var hasProfile = false
    @Published var currentUserId: UUID?
    @Published var errorMessage: String?

    private let client = SupabaseManager.shared.client

    private init() {
        Task { await checkInitialSession() }
    }

    // MARK: - Session Check

    func checkInitialSession() async {
        do {
            let session = try await client.auth.session
            currentUserId = session.user.id
            isAuthenticated = true
            await checkProfile(userId: session.user.id)
        } catch {
            isAuthenticated = false
            hasProfile = false
        }
        isLoading = false
    }

    private func checkProfile(userId: UUID) async {
        do {
            let profiles: [UserProfile] = try await client
                .from("users")
                .select()
                .eq("id", value: userId.uuidString)
                .execute()
                .value
            hasProfile = !profiles.isEmpty
        } catch {
            hasProfile = false
        }
    }

    // MARK: - Sign Up

    func signUp(email: String, password: String) async throws {
        errorMessage = nil
        let response = try await client.auth.signUp(email: email, password: password)
        if let session = response.session {
            currentUserId = session.user.id
            isAuthenticated = true
            hasProfile = false
        }
        // If session is nil, Supabase requires email confirmation.
        // Show appropriate message in the UI.
    }

    // MARK: - Sign In

    func signIn(email: String, password: String) async throws {
        errorMessage = nil
        let session = try await client.auth.signIn(email: email, password: password)
        currentUserId = session.user.id
        isAuthenticated = true
        await checkProfile(userId: session.user.id)
    }

    // MARK: - Sign Out

    func signOut() async throws {
        try await client.auth.signOut()
        isAuthenticated = false
        hasProfile = false
        currentUserId = nil
    }

    // MARK: - Create Profile (called at end of onboarding)

    func createProfile(name: String, heightCm: Double, weightKg: Double, age: Int,
                        activityLevel: ActivityLevel, goal: FitnessGoal,
                        goals: UserGoalsInput) async throws {
        guard let userId = currentUserId else {
            throw AuthError.notAuthenticated
        }

        let profileInsert = UserProfileInsert(
            id: userId.uuidString,
            name: name,
            heightCm: heightCm,
            weightKg: weightKg,
            age: age,
            activityLevel: activityLevel.rawValue,
            goal: goal.rawValue
        )
        try await client.from("users").insert(profileInsert).execute()

        let goalsInsert = UserGoalsInsert(
            userId: userId.uuidString,
            dailyCalories: goals.dailyCalories,
            proteinTarget: goals.proteinTarget,
            carbsTarget: goals.carbsTarget,
            fatTarget: goals.fatTarget
        )
        try await client.from("user_goals").insert(goalsInsert).execute()

        hasProfile = true
    }

    // MARK: - Errors

    enum AuthError: LocalizedError {
        case notAuthenticated

        var errorDescription: String? {
            switch self {
            case .notAuthenticated:
                return "You must be logged in to perform this action."
            }
        }
    }
}

// MARK: - Input DTO (used only during onboarding flow)

struct UserGoalsInput {
    var dailyCalories: Int
    var proteinTarget: Int
    var carbsTarget: Int
    var fatTarget: Int
}
