import SwiftUI

@main
struct PlastikApp: App {
    @State private var feedService = DataFeedService()
    @State private var cardViewModel = CardViewModel()
    @State private var notificationService = NotificationService()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(feedService)
                .environment(cardViewModel)
                .environment(notificationService)
                .onAppear {
                    feedService.loadData()
                    cardViewModel.loadCards()
                    setupNotifications()
                }
        }
    }

    private func setupNotifications() {
        Task {
            await notificationService.checkAuthorizationStatus()
            if notificationService.isAuthorized {
                scheduleAllNotifications()
            }
        }
    }

    private func scheduleAllNotifications() {
        notificationService.scheduleBenefitResetReminders(
            for: cardViewModel.userCards,
            cards: feedService.cards,
            feedService: feedService
        )
        notificationService.scheduleOfferExpirationReminders(
            for: feedService.offers,
            cards: feedService.cards
        )
        notificationService.scheduleBonusDeadlineReminders(
            for: cardViewModel.userCards,
            cards: feedService.cards
        )
    }
}
