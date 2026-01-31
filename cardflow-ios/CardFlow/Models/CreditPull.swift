import Foundation

struct CreditPull: Codable, Identifiable {
    var id: Int
    var bureau: String
    var creditor: String
    var date: String
    var type: String
    var source: String?

    enum CodingKeys: String, CodingKey {
        case id
        case bureau
        case creditor
        case date
        case type
        case source
    }

    init(
        id: Int = Int(Date().timeIntervalSince1970 * 1000),
        bureau: String = "Experian",
        creditor: String = "",
        date: String = "",
        type: String = "",
        source: String? = nil
    ) {
        self.id = id
        self.bureau = bureau
        self.creditor = creditor
        self.date = date
        self.type = type
        self.source = source
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decodeIfPresent(Int.self, forKey: .id) ?? Int(Date().timeIntervalSince1970 * 1000)
        bureau = try container.decodeIfPresent(String.self, forKey: .bureau) ?? "Experian"
        creditor = try container.decodeIfPresent(String.self, forKey: .creditor) ?? ""
        date = try container.decodeIfPresent(String.self, forKey: .date) ?? ""
        type = try container.decodeIfPresent(String.self, forKey: .type) ?? ""
        source = try container.decodeIfPresent(String.self, forKey: .source)
    }
}
