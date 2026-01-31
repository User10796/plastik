import Foundation

struct CompanionPass: Codable, Identifiable {
    var id: String { "\(type)-\(holder ?? "")" }

    var type: String
    var earned: Bool
    var expiresDate: String?
    var progress: Double?
    var target: Double?
    var holder: String?
    var usedCount: Int?

    enum CodingKeys: String, CodingKey {
        case type
        case earned
        case expiresDate
        case progress
        case target
        case holder
        case usedCount
    }

    init(
        type: String = "",
        earned: Bool = false,
        expiresDate: String? = nil,
        progress: Double? = nil,
        target: Double? = nil,
        holder: String? = nil,
        usedCount: Int? = nil
    ) {
        self.type = type
        self.earned = earned
        self.expiresDate = expiresDate
        self.progress = progress
        self.target = target
        self.holder = holder
        self.usedCount = usedCount
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        type = try container.decodeIfPresent(String.self, forKey: .type) ?? ""
        earned = try container.decodeIfPresent(Bool.self, forKey: .earned) ?? false
        expiresDate = try container.decodeIfPresent(String.self, forKey: .expiresDate)
        progress = try container.decodeIfPresent(Double.self, forKey: .progress)
        target = try container.decodeIfPresent(Double.self, forKey: .target)
        holder = try container.decodeIfPresent(String.self, forKey: .holder)
        usedCount = try container.decodeIfPresent(Int.self, forKey: .usedCount)
    }
}
