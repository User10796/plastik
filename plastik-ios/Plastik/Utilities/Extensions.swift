import Foundation
import SwiftUI

extension Date {
    var relativeDescription: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: self, relativeTo: Date())
    }

    var shortFormatted: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: self)
    }

    var monthYear: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM yyyy"
        return formatter.string(from: self)
    }

    func daysFrom(_ date: Date = Date()) -> Int {
        Calendar.current.dateComponents([.day], from: date, to: self).day ?? 0
    }

    func monthsFrom(_ date: Date = Date()) -> Int {
        Calendar.current.dateComponents([.month], from: date, to: self).month ?? 0
    }
}

extension Int {
    var currencyFormatted: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: self)) ?? "$\(self)"
    }

    var commaFormatted: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        return formatter.string(from: NSNumber(value: self)) ?? "\(self)"
    }
}

extension Double {
    var multiplierFormatted: String {
        if self == floor(self) {
            return "\(Int(self))x"
        }
        return String(format: "%.1fx", self)
    }
}

extension View {
    func cardStyle() -> some View {
        self
            .padding()
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}
