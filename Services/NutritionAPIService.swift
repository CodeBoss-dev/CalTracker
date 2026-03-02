import Foundation

// MARK: - USDA FoodData Central API Service
//
// Free public nutrition database. No attribution required (CC0 public domain).
// Rate limit: 1,000 requests/hour with free API key.
// Docs: https://fdc.nal.usda.gov/api-guide/

@MainActor
final class NutritionAPIService {
    static let shared = NutritionAPIService()

    // ⚠️ Replace with your free USDA API key
    // Get one instantly at: https://fdc.nal.usda.gov/api-key-signup/
    private let apiKey = "DEMO_KEY"
    private let baseURL = "https://api.nal.usda.gov/fdc/v1/foods/search"

    private init() {}

    /// Search USDA FoodData Central and return results mapped to the app's `Food` model.
    /// Data is per 100g serving (USDA standard). Returns up to 25 results.
    func searchFoods(query: String) async throws -> [Food] {
        guard !query.trimmingCharacters(in: .whitespaces).isEmpty else { return [] }

        var components = URLComponents(string: baseURL)!
        components.queryItems = [
            URLQueryItem(name: "api_key", value: apiKey),
            URLQueryItem(name: "query", value: query),
            URLQueryItem(name: "pageSize", value: "25")
        ]

        guard let url = components.url else { return [] }

        var request = URLRequest(url: url)
        request.timeoutInterval = 10

        let (data, response): (Data, URLResponse)
        do {
            (data, response) = try await URLSession.shared.data(for: request)
        } catch {
            throw NutritionAPIError.networkError
        }

        if let http = response as? HTTPURLResponse, http.statusCode != 200 {
            if http.statusCode == 429 {
                throw NutritionAPIError.rateLimited
            }
            throw NutritionAPIError.apiError("HTTP \(http.statusCode)")
        }

        let searchResponse = try JSONDecoder().decode(USDASearchResponse.self, from: data)
        return searchResponse.foods.compactMap { mapToFood($0) }
    }

    // MARK: - Mapping

    /// Maps a USDA food item to the app's `Food` model.
    /// Nutrition is per 100g (USDA standard basis).
    private func mapToFood(_ item: USDAFoodItem) -> Food? {
        let calories = nutrientValue(from: item.foodNutrients, nutrientId: 1008) // Energy (kcal)
        guard calories > 0 else { return nil }

        let protein = nutrientValue(from: item.foodNutrients, nutrientId: 1003)
        let carbs   = nutrientValue(from: item.foodNutrients, nutrientId: 1005)
        let fat     = nutrientValue(from: item.foodNutrients, nutrientId: 1004)

        // Generate a deterministic UUID from the USDA fdcId so the same food always gets the same ID
        let id = deterministicUUID(from: item.fdcId)

        // Clean up the name: USDA names are often ALL CAPS or have extra metadata
        let name = cleanFoodName(item.description)

        return Food(
            id: id,
            name: name,
            caloriesPerServing: round(calories * 10) / 10,
            protein: round(protein * 10) / 10,
            carbs: round(carbs * 10) / 10,
            fat: round(fat * 10) / 10,
            servingUnit: "g",
            servingSize: 100,
            category: .outside,
            isCustom: false,
            createdBy: nil,
            isFromAPI: true
        )
    }

    private func nutrientValue(from nutrients: [USDANutrient], nutrientId: Int) -> Double {
        nutrients.first { $0.nutrientId == nutrientId }?.value ?? 0
    }

    /// Generates a deterministic UUID from a USDA fdcId integer.
    /// Format: AAAAAAAA-BBBB-4CCC-8DDD-EEEEEEEEEEEE where the fdcId is encoded in the last segment.
    private func deterministicUUID(from fdcId: Int) -> UUID {
        // Use a fixed namespace prefix + the fdcId to generate a stable UUID
        let hex = String(format: "%012x", fdcId)
        let uuidString = "00000000-0000-4000-8000-\(hex)"
        return UUID(uuidString: uuidString) ?? UUID()
    }

    /// Cleans USDA food names: converts from ALL CAPS, removes trailing metadata like "UPC: ..."
    private func cleanFoodName(_ raw: String) -> String {
        var name = raw

        // Remove anything after a comma that looks like metadata (e.g. ", raw", ", cooked")
        // Keep it — those are useful descriptors

        // If entire name is uppercase, convert to title case
        if name == name.uppercased() && name.count > 3 {
            name = name.capitalized
        }

        // Trim excess whitespace
        name = name.trimmingCharacters(in: .whitespaces)

        return name
    }
}

// MARK: - USDA API Response Types

private struct USDASearchResponse: Decodable {
    let foods: [USDAFoodItem]
}

private struct USDAFoodItem: Decodable {
    let fdcId: Int
    let description: String
    let foodNutrients: [USDANutrient]
}

private struct USDANutrient: Decodable {
    let nutrientId: Int
    let value: Double
}

// MARK: - Errors

enum NutritionAPIError: LocalizedError {
    case networkError
    case rateLimited
    case apiError(String)

    var errorDescription: String? {
        switch self {
        case .networkError:  return "No internet connection."
        case .rateLimited:   return "Too many requests — try again in a moment."
        case .apiError(let m): return "API error: \(m)"
        }
    }
}
