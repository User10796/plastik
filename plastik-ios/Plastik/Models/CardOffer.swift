import Foundation

struct CardOffer: Identifiable, Codable {
    let id: String
    let cardId: String
    let title: String
    let description: String
    let bonusPoints: Int?
    let bonusCurrency: String?
    let spendRequired: Int?
    let timeframeDays: Int?
    let expirationDate: Date?
    let isTargeted: Bool
    let source: String?

    var isExpired: Bool {
        guard let expDate = expirationDate else { return false }
        return expDate < Date()
    }

    var daysUntilExpiration: Int? {
        guard let expDate = expirationDate else { return nil }
        return Calendar.current.dateComponents([.day], from: Date(), to: expDate).day
    }
}
