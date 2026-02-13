import SwiftUI
import CloudKit
#if canImport(UIKit)
import UIKit
#endif
#if canImport(AppKit)
import AppKit
#endif

// MARK: - App Delegate for Remote Notification Handling

#if canImport(UIKit)
class PlastikAppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Register for remote notifications (needed for CloudKit silent push)
        application.registerForRemoteNotifications()
        return true
    }

    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable: Any], fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        // Forward CloudKit notifications
        let notification = CKNotification(fromRemoteNotificationDictionary: userInfo)
        if notification?.notificationType == .database {
            NotificationCenter.default.post(name: Notification.Name("CKDatabaseDidReceiveRemoteNotification"), object: nil)
        }
        completionHandler(.newData)
    }
}
#endif

#if canImport(AppKit)
class PlastikAppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Register for remote notifications (needed for CloudKit silent push)
        NSApplication.shared.registerForRemoteNotifications()
    }

    func application(_ application: NSApplication, didReceiveRemoteNotification userInfo: [String: Any]) {
        // Forward CloudKit notifications
        let ckNotification = CKNotification(fromRemoteNotificationDictionary: userInfo)
        if ckNotification?.notificationType == .database {
            NotificationCenter.default.post(name: Notification.Name("CKDatabaseDidReceiveRemoteNotification"), object: nil)
        }
    }
}
#endif

// MARK: - Main App

@main
struct PlastikApp: App {
    #if canImport(UIKit)
    @UIApplicationDelegateAdaptor(PlastikAppDelegate.self) var appDelegate
    #endif
    #if canImport(AppKit)
    @NSApplicationDelegateAdaptor(PlastikAppDelegate.self) var appDelegate
    #endif

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
