import Foundation
import Combine

// MARK: - StoredGoals

struct StoredGoals: Codable {
    var dailyCalories: Int
    var proteinTarget: Int
    var carbsTarget:   Int
    var fatTarget:     Int

    static let defaults = StoredGoals(
        dailyCalories: 1800,
        proteinTarget: 120,
        carbsTarget:   200,
        fatTarget:     55
    )
}

// MARK: - GoalsService

/// Persists daily calorie / macro targets to UserDefaults and syncs with Supabase.
/// `FoodLogViewModel` subscribes to `$goals` so the dashboard refreshes instantly
/// when the user edits their targets in `GoalEditorView`.
@MainActor
final class GoalsService: ObservableObject {

    static let shared = GoalsService()

    private let udKey  = "caltracker_user_goals_v1"
    private let client = SupabaseManager.shared.client

    @Published private(set) var goals: StoredGoals

    private init() {
        if let data   = UserDefaults.standard.data(forKey: "caltracker_user_goals_v1"),
           let stored = try? JSONDecoder().decode(StoredGoals.self, from: data) {
            goals = stored
        } else {
            goals = .defaults
        }
        Task { await fetchFromSupabase() }
    }

    // MARK: - Update

    func update(calories: Int, protein: Int, carbs: Int, fat: Int) {
        goals = StoredGoals(
            dailyCalories: calories,
            proteinTarget: protein,
            carbsTarget:   carbs,
            fatTarget:     fat
        )
        persist()
        Task { await saveToSupabase() }
    }

    // MARK: - Local persistence

    private func persist() {
        if let data = try? JSONEncoder().encode(goals) {
            UserDefaults.standard.set(data, forKey: udKey)
        }
    }

    // MARK: - Supabase sync

    private func fetchFromSupabase() async {
        do {
            let session = try await client.auth.session
            let rows: [UserGoals] = try await client
                .from("user_goals")
                .select()
                .eq("user_id", value: session.user.id.uuidString)
                .limit(1)
                .execute()
                .value
            if let first = rows.first {
                goals = StoredGoals(
                    dailyCalories: first.dailyCalories,
                    proteinTarget: first.proteinTarget,
                    carbsTarget:   first.carbsTarget,
                    fatTarget:     first.fatTarget
                )
                persist()
            }
        } catch {
            // No session or network error — local defaults remain
        }
    }

    private func saveToSupabase() async {
        do {
            let session = try await client.auth.session
            // Delete then re-insert (simple upsert; schema has no unique constraint on user_id alone)
            try await client
                .from("user_goals")
                .delete()
                .eq("user_id", value: session.user.id.uuidString)
                .execute()
            let insert = UserGoalsInsert(
                userId:        session.user.id.uuidString,
                dailyCalories: goals.dailyCalories,
                proteinTarget: goals.proteinTarget,
                carbsTarget:   goals.carbsTarget,
                fatTarget:     goals.fatTarget
            )
            try await client.from("user_goals").insert(insert).execute()
        } catch {
            // Network error — change is already persisted locally
        }
    }
}
