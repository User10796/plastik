import Foundation

enum Formatters {
    static let currency: NumberFormatter = {
        let f = NumberFormatter()
        f.numberStyle = .currency
        f.locale = Locale(identifier: "en_US")
        return f
    }()

    static let dateDisplay: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "MMM d, yyyy"
        return f
    }()

    static let dateISO: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        return f
    }()

    static func formatCurrency(_ amount: Double) -> String {
        currency.string(from: NSNumber(value: amount)) ?? "$0.00"
    }

    static func formatDate(_ dateStr: String) -> String {
        guard let date = dateISO.date(from: dateStr) else { return dateStr }
        return dateDisplay.string(from: date)
    }

    static func daysUntil(_ dateStr: String) -> Int? {
        guard let date = dateISO.date(from: dateStr) else { return nil }
        let diff = Calendar.current.dateComponents([.day], from: Date(), to: date)
        return diff.day
    }

    static func todayISO() -> String {
        dateISO.string(from: Date())
    }
}
