import SwiftUI

struct SettingsView: View {
    @Environment(DataFeedService.self) private var feedService
    @Environment(CardViewModel.self) private var cardViewModel
    @Environment(NotificationService.self) private var notificationService

    var body: some View {
        List {
            dataSyncSection
            dataFeedSection
            notificationsSection
            referralLinksSection
            toolsSection
            #if DEBUG
            debugSection
            #endif
            aboutSection
        }
        .navigationTitle("Settings")
    }

    @ViewBuilder
    private var dataSyncSection: some View {
        Section("iCloud Sync") {
            HStack {
                Image(systemName: "icloud")
                    .foregroundStyle(.blue)
                Text("CloudKit Sync")
                Spacer()
                Text("Enabled")
                    .font(.caption)
                    .foregroundStyle(.green)
            }

            HStack {
                Text("Cards in Wallet")
                Spacer()
                Text("\(cardViewModel.userCards.count)")
                    .foregroundStyle(.secondary)
            }

            if let lastSync = cardViewModel.lastSyncDate {
                HStack {
                    Text("Last Synced")
                    Spacer()
                    Text(lastSync.relativeDescription)
                        .foregroundStyle(.secondary)
                }
            }

            Button {
                Task {
                    await cardViewModel.manualSync()
                }
            } label: {
                HStack {
                    Label("Sync Now", systemImage: "arrow.triangle.2.circlepath")
                    Spacer()
                    if cardViewModel.isSyncing {
                        ProgressView()
                            .controlSize(.small)
                    }
                }
            }
            .disabled(cardViewModel.isSyncing)

            if let error = cardViewModel.lastSyncError {
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(.orange)
                    Text(error)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    @ViewBuilder
    private var dataFeedSection: some View {
        Section("Card Data Feed") {
            HStack {
                Text("Cards in Catalog")
                Spacer()
                Text("\(feedService.cards.count)")
                    .foregroundStyle(.secondary)
            }

            if let lastUpdated = feedService.lastUpdated {
                HStack {
                    Text("Last Updated")
                    Spacer()
                    Text(lastUpdated.relativeDescription)
                        .foregroundStyle(.secondary)
                }
            }

            Button("Refresh Card Data") {
                Task {
                    try? await feedService.fetchLatestData()
                }
            }

            if feedService.isLoading {
                HStack {
                    ProgressView()
                        .controlSize(.small)
                    Text("Updating...")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    @ViewBuilder
    private var notificationsSection: some View {
        Section("Notifications") {
            HStack {
                Image(systemName: notificationService.isAuthorized ? "bell.fill" : "bell.slash.fill")
                    .foregroundStyle(notificationService.isAuthorized ? .blue : .secondary)
                Text("Push Notifications")
                Spacer()
                Text(notificationService.isAuthorized ? "Enabled" : "Disabled")
                    .font(.caption)
                    .foregroundStyle(notificationService.isAuthorized ? .green : .red)
            }

            if !notificationService.isAuthorized {
                Button("Enable Notifications") {
                    Task {
                        let granted = await notificationService.requestAuthorization()
                        if granted {
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
                }
            } else {
                VStack(alignment: .leading, spacing: 4) {
                    Text("You'll be notified about:")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text("  - Benefit credit resets (7 days before)")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    Text("  - Offer expirations (7 days + 1 day before)")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    Text("  - Bonus spend deadlines (14 days before)")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    @ViewBuilder
    private var referralLinksSection: some View {
        let cardsWithReferrals = cardViewModel.userCards.filter { uc in
            feedService.card(for: uc.cardId)?.referralLink != nil
        }

        if !cardsWithReferrals.isEmpty {
            Section("Referral Links") {
                ForEach(cardsWithReferrals) { userCard in
                    if let card = feedService.card(for: userCard.cardId),
                       let referralLink = card.referralLink,
                       let url = URL(string: referralLink) {
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(userCard.nickname ?? card.name)
                                    .font(.body)
                                Text(card.issuer.displayName)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            ShareLink(item: url) {
                                Image(systemName: "square.and.arrow.up")
                                    .foregroundStyle(.blue)
                            }
                        }
                    }
                }
            }
        }
    }

    @ViewBuilder
    private var toolsSection: some View {
        Section("Tools") {
            NavigationLink(destination: TransferPartnerMapView()) {
                Label("Transfer Partner Map", systemImage: "arrow.triangle.swap")
            }
            NavigationLink(destination: DataImportView()) {
                Label("Import Statement (PDF)", systemImage: "doc.fill")
            }
        }
    }

    #if DEBUG
    @ViewBuilder
    private var debugSection: some View {
        Section("Developer") {
            NavigationLink(destination: DebugTestView()) {
                Label("Debug Tests", systemImage: "ant.fill")
            }
            HStack {
                Text("Memory")
                Spacer()
                Text("\(MemoryMonitor.shared.currentUsageMB) MB")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }
    #endif

    @ViewBuilder
    private var aboutSection: some View {
        Section("About") {
            LabeledContent("App", value: Constants.appName)
            LabeledContent("Version", value: "1.0.0")
            LabeledContent("Build", value: "1")
        }
    }
}
