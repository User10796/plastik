import Foundation
import UserNotifications

@Observable
class NotificationService {
    var isAuthorized = false

    private let center = UNUserNotificationCenter.current()

    // MARK: - Authorization

    func requestAuthorization() async -> Bool {
        do {
            let granted = try await center.requestAuthorization(options: [.alert, .badge, .sound])
            await MainActor.run { self.isAuthorized = granted }
            return granted
        } catch {
            return false
        }
    }

    func checkAuthorizationStatus() async {
        let settings = await center.notificationSettings()
        await MainActor.run {
            self.isAuthorized = settings.authorizationStatus == .authorized
        }
    }

    // MARK: - Schedule Benefit Reset Reminders

    func scheduleBenefitResetReminders(
        for userCards: [UserCard],
        cards: [CreditCard],
        feedService: DataFeedService
    ) {
        // Remove existing benefit reminders
        center.removePendingNotificationRequests(withIdentifiers:
            userCards.flatMap { uc in
                uc.benefitUsage.map { "benefit-reset-\(uc.id)-\($0.benefitId)" }
            }
        )

        for userCard in userCards where userCard.isActive {
            guard let card = feedService.card(for: userCard.cardId) else { continue }

            for benefit in card.benefits where benefit.resetPeriod != .none {
                // Find existing usage for this benefit
                let usage = userCard.benefitUsage.first { $0.benefitId == benefit.id }
                let usedAmount = usage?.usedAmount ?? 0

                // Only remind if benefit hasn't been fully used
                guard usedAmount < benefit.value else { continue }

                let resetDate = nextResetDate(for: benefit.resetPeriod)
                guard let reminderDate = Calendar.current.date(byAdding: .day, value: -7, to: resetDate),
                      reminderDate > Date() else { continue }

                let content = UNMutableNotificationContent()
                content.title = "Benefit Expiring Soon"
                content.body = "\(benefit.name) on \(card.name) resets in 7 days. You've used $\(Int(usedAmount)) of \(benefit.formattedValue)."
                content.sound = .default
                content.categoryIdentifier = "benefit-reset"

                let components = Calendar.current.dateComponents([.year, .month, .day, .hour], from: reminderDate)
                let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)

                let identifier = "benefit-reset-\(userCard.id)-\(benefit.id)"
                let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)

                center.add(request)
            }
        }
    }

    // MARK: - Schedule Offer Expiration Reminders

    func scheduleOfferExpirationReminders(
        for offers: [CardOffer],
        cards: [CreditCard]
    ) {
        // Remove existing offer reminders
        center.removePendingNotificationRequests(withIdentifiers:
            offers.map { "offer-expiry-\($0.id)" }
        )

        for offer in offers {
            guard let expDate = offer.expirationDate,
                  !offer.isExpired else { continue }

            let cardName = cards.first { $0.id == offer.cardId }?.name ?? "Credit Card"

            // 7-day warning
            if let reminderDate = Calendar.current.date(byAdding: .day, value: -7, to: expDate),
               reminderDate > Date() {
                let content = UNMutableNotificationContent()
                content.title = "Offer Expiring Soon"
                content.body = "\(offer.title) for \(cardName) expires in 7 days."
                content.sound = .default
                content.categoryIdentifier = "offer-expiry"

                let components = Calendar.current.dateComponents([.year, .month, .day, .hour], from: reminderDate)
                let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)

                let identifier = "offer-expiry-\(offer.id)"
                let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)

                center.add(request)
            }

            // 1-day warning
            if let urgentDate = Calendar.current.date(byAdding: .day, value: -1, to: expDate),
               urgentDate > Date() {
                let content = UNMutableNotificationContent()
                content.title = "Offer Expires Tomorrow"
                content.body = "\(offer.title) for \(cardName) expires tomorrow!"
                content.sound = .default
                content.categoryIdentifier = "offer-expiry-urgent"

                let components = Calendar.current.dateComponents([.year, .month, .day, .hour], from: urgentDate)
                let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)

                let identifier = "offer-expiry-urgent-\(offer.id)"
                let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)

                center.add(request)
            }
        }
    }

    // MARK: - Schedule Bonus Deadline Reminders

    func scheduleBonusDeadlineReminders(
        for userCards: [UserCard],
        cards: [CreditCard]
    ) {
        center.removePendingNotificationRequests(withIdentifiers:
            userCards.map { "bonus-deadline-\($0.id)" }
        )

        for userCard in userCards {
            guard let bonus = userCard.signupBonusProgress,
                  !bonus.completed, !bonus.isExpired else { continue }

            let cardName = cards.first { $0.id == userCard.cardId }?.name ?? "Card"
            let remaining = bonus.targetSpend - bonus.spentSoFar

            // 14-day warning
            if let reminderDate = Calendar.current.date(byAdding: .day, value: -14, to: bonus.deadline),
               reminderDate > Date() {
                let content = UNMutableNotificationContent()
                content.title = "Bonus Deadline Approaching"
                content.body = "\(cardName): $\(remaining) more needed in \(bonus.daysRemaining) days to earn your signup bonus."
                content.sound = .default
                content.categoryIdentifier = "bonus-deadline"

                let components = Calendar.current.dateComponents([.year, .month, .day, .hour], from: reminderDate)
                let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)

                let request = UNNotificationRequest(identifier: "bonus-deadline-\(userCard.id)", content: content, trigger: trigger)
                center.add(request)
            }
        }
    }

    // MARK: - Remove All

    func removeAllNotifications() {
        center.removeAllPendingNotificationRequests()
    }

    // MARK: - Helpers

    private func nextResetDate(for period: ResetPeriod) -> Date {
        let cal = Calendar.current
        let now = Date()

        switch period {
        case .monthly:
            var components = cal.dateComponents([.year, .month], from: now)
            components.month = (components.month ?? 1) + 1
            components.day = 1
            return cal.date(from: components) ?? now

        case .quarterly:
            let month = cal.component(.month, from: now)
            let nextQuarterMonth = ((month - 1) / 3 + 1) * 3 + 1
            var components = cal.dateComponents([.year], from: now)
            components.month = nextQuarterMonth > 12 ? 1 : nextQuarterMonth
            if nextQuarterMonth > 12 { components.year = (components.year ?? 2026) + 1 }
            components.day = 1
            return cal.date(from: components) ?? now

        case .annual:
            return cal.date(byAdding: .year, value: 1, to: now) ?? now

        case .calendarYear:
            var components = cal.dateComponents([.year], from: now)
            components.year = (components.year ?? 2026) + 1
            components.month = 1
            components.day = 1
            return cal.date(from: components) ?? now

        case .none:
            return now
        }
    }
}
