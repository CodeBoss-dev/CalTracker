import Foundation

struct WeightEntry: Codable, Identifiable {
    let id: UUID
    let userId: UUID
    let weight: Double      // in kg
    let date: String        // "YYYY-MM-DD"

    enum CodingKeys: String, CodingKey {
        case id, weight, date
        case userId = "user_id"
    }
}

// MARK: - Insert struct

struct WeightEntryInsert: Encodable {
    let userId: String
    let weight: Double
    let date: String

    enum CodingKeys: String, CodingKey {
        case weight, date
        case userId = "user_id"
    }
}
