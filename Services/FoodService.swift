import Foundation
import Supabase

// MARK: - Custom Food Insert DTO

struct CustomFoodInsert: Encodable {
    let name: String
    let caloriesPerServing: Double
    let protein: Double
    let carbs: Double
    let fat: Double
    let servingUnit: String
    let servingSize: Double
    let category: String
    let isCustom: Bool
    let createdBy: String

    enum CodingKeys: String, CodingKey {
        case name, protein, carbs, fat, category
        case caloriesPerServing = "calories_per_serving"
        case servingUnit = "serving_unit"
        case servingSize = "serving_size"
        case isCustom = "is_custom"
        case createdBy = "created_by"
    }
}

// MARK: - FoodService

@MainActor
final class FoodService: ObservableObject {
    static let shared = FoodService()

    private let client = SupabaseManager.shared.client

    /// In-memory cache of the bundled JSON (loaded once at init)
    private(set) var localFoods: [Food] = []

    private init() {
        loadLocalFoods()
    }

    // MARK: - Local JSON Loading

    private func loadLocalFoods() {
        guard
            let url = Bundle.main.url(forResource: "IndianFoodSeed", withExtension: "json"),
            let data = try? Data(contentsOf: url)
        else { return }

        let decoder = JSONDecoder()
        if let foods = try? decoder.decode([Food].self, from: data) {
            localFoods = foods
        }
    }

    // MARK: - Search

    /// Search foods. Tries Supabase first; falls back to local JSON on error.
    /// Does NOT include USDA results — call `searchUSDA(query:)` separately for that.
    func searchFoods(query: String, category: FoodCategory? = nil) async throws -> [Food] {
        do {
            var request = client.from("foods").select()

            if !query.isEmpty {
                request = request.ilike("name", value: "%\(query)%")
            }
            if let category {
                request = request.eq("category", value: category.rawValue)
            }

            let foods: [Food] = try await request.execute().value
            if !foods.isEmpty { return foods }
        } catch {
            // Supabase unavailable or not seeded — use local
        }

        return searchLocal(query: query, category: category)
    }

    /// Synchronous local search against the bundled JSON.
    func searchLocal(query: String, category: FoodCategory? = nil) -> [Food] {
        var results = localFoods
        if !query.isEmpty {
            results = results.filter {
                $0.name.localizedCaseInsensitiveContains(query)
            }
        }
        if let category {
            results = results.filter { $0.category == category }
        }
        return results
    }

    /// Search USDA FoodData Central for foods not in the local database.
    /// Returns results with `isFromAPI = true`. Category filter is not applied
    /// (USDA doesn't use our categories).
    func searchUSDA(query: String) async -> [Food] {
        guard query.count >= 3 else { return [] }
        return (try? await NutritionAPIService.shared.searchFoods(query: query)) ?? []
    }

    /// Fetch a single food by ID from Supabase, or from local JSON as fallback.
    func fetchFood(id: UUID) async throws -> Food? {
        do {
            let foods: [Food] = try await client
                .from("foods")
                .select()
                .eq("id", value: id.uuidString)
                .execute()
                .value
            return foods.first
        } catch {
            return localFoods.first { $0.id == id }
        }
    }

    // MARK: - Custom Food

    /// Save a user-created food to Supabase and return the inserted record.
    func addCustomFood(
        name: String,
        caloriesPerServing: Double,
        protein: Double,
        carbs: Double,
        fat: Double,
        servingUnit: String,
        servingSize: Double,
        category: FoodCategory
    ) async throws -> Food {
        guard let userId = try? await client.auth.session.user.id else {
            throw FoodServiceError.notAuthenticated
        }

        let insert = CustomFoodInsert(
            name: name,
            caloriesPerServing: caloriesPerServing,
            protein: protein,
            carbs: carbs,
            fat: fat,
            servingUnit: servingUnit,
            servingSize: servingSize,
            category: category.rawValue,
            isCustom: true,
            createdBy: userId.uuidString
        )

        let result: Food = try await client
            .from("foods")
            .insert(insert)
            .select()
            .single()
            .execute()
            .value

        return result
    }

    // MARK: - Seeding

    /// Seed the bundled JSON into the Supabase `foods` table (upsert by ID).
    /// Call this once from an admin/dev build or a first-launch check.
    func seedToSupabase() async throws {
        guard !localFoods.isEmpty else { return }
        try await client.from("foods").upsert(localFoods).execute()
    }

    // MARK: - Errors

    enum FoodServiceError: LocalizedError {
        case notAuthenticated

        var errorDescription: String? {
            switch self {
            case .notAuthenticated:
                return "You must be logged in to add a custom food."
            }
        }
    }
}
