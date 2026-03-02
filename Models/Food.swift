import Foundation

struct Food: Codable, Identifiable, Hashable {
    let id: UUID
    let name: String
    let caloriesPerServing: Double
    let protein: Double
    let carbs: Double
    let fat: Double
    let servingUnit: String   // e.g. "piece", "katori", "plate", "glass", "g"
    let servingSize: Double   // e.g. 1.0, 0.5, 100.0 (USDA)
    let category: FoodCategory
    let isCustom: Bool
    let createdBy: UUID?

    /// Transient flag — true for foods fetched from USDA API. Not persisted.
    var isFromAPI: Bool = false

    enum CodingKeys: String, CodingKey {
        case id, name, protein, carbs, fat, category
        case caloriesPerServing = "calories_per_serving"
        case servingUnit = "serving_unit"
        case servingSize = "serving_size"
        case isCustom = "is_custom"
        case createdBy = "created_by"
        // isFromAPI intentionally excluded — transient, not stored
    }

    init(id: UUID, name: String, caloriesPerServing: Double, protein: Double, carbs: Double, fat: Double, servingUnit: String, servingSize: Double, category: FoodCategory, isCustom: Bool, createdBy: UUID?, isFromAPI: Bool = false) {
        self.id = id
        self.name = name
        self.caloriesPerServing = caloriesPerServing
        self.protein = protein
        self.carbs = carbs
        self.fat = fat
        self.servingUnit = servingUnit
        self.servingSize = servingSize
        self.category = category
        self.isCustom = isCustom
        self.createdBy = createdBy
        self.isFromAPI = isFromAPI
    }

    // MARK: - Computed helpers

    func calories(for servings: Double) -> Double {
        caloriesPerServing * servings
    }

    func protein(for servings: Double) -> Double {
        protein * servings
    }

    func carbs(for servings: Double) -> Double {
        carbs * servings
    }

    func fat(for servings: Double) -> Double {
        fat * servings
    }

    var servingDescription: String {
        let count = servingSize == 1.0 ? "1" : String(servingSize)
        return "\(count) \(servingUnit)"
    }
}
