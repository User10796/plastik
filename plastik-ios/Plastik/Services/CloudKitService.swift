import Foundation
import CloudKit
#if canImport(UIKit)
import UIKit
#endif
#if canImport(AppKit)
import AppKit
#endif

@Observable
class CloudKitService {
    var isSyncing = false
    var lastSyncDate: Date?
    var syncError: String?

    private let container = CKContainer(identifier: "iCloud.com.plastikapp.ios")

    // Old zone where existing data is stored
    private let legacyZoneName = "PlastikZone"
    private var legacyZoneID: CKRecordZone.ID {
        CKRecordZone.ID(zoneName: legacyZoneName, ownerName: CKCurrentUserDefaultName)
    }

    // Change token for incremental sync
    private let changeTokenKey = "cloudKitZoneChangeToken"
    private var serverChangeToken: CKServerChangeToken? {
        get {
            guard let data = UserDefaults.standard.data(forKey: changeTokenKey) else { return nil }
            return try? NSKeyedUnarchiver.unarchivedObject(ofClass: CKServerChangeToken.self, from: data)
        }
        set {
            if let token = newValue,
               let data = try? NSKeyedArchiver.archivedData(withRootObject: token, requiringSecureCoding: true) {
                UserDefaults.standard.set(data, forKey: changeTokenKey)
            } else {
                UserDefaults.standard.removeObject(forKey: changeTokenKey)
            }
        }
    }

    // Callback for when remote changes are detected
    var onRemoteChange: (() -> Void)?

    // Periodic sync timer for when the app is active
    private var periodicSyncTimer: Timer?
    private let periodicSyncInterval: TimeInterval = 30 // Check every 30 seconds

    // MARK: - Initialization

    init() {
        setupRemoteChangeObserver()
    }

    deinit {
        periodicSyncTimer?.invalidate()
    }

    // MARK: - Remote Change Notifications

    private func setupRemoteChangeObserver() {
        // Listen for remote CloudKit changes (works on both iOS and macOS)
        NotificationCenter.default.addObserver(
            forName: NSNotification.Name.CKAccountChanged,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            print("CloudKit: Account changed, triggering sync")
            self?.onRemoteChange?()
        }

        // Listen for CloudKit remote notifications (silent push from subscription)
        NotificationCenter.default.addObserver(
            forName: Notification.Name("CKDatabaseDidReceiveRemoteNotification"),
            object: nil,
            queue: .main
        ) { [weak self] _ in
            print("CloudKit: Received remote database notification, triggering sync")
            self?.onRemoteChange?()
        }

        // Listen for app becoming active to sync
        #if canImport(UIKit)
        NotificationCenter.default.addObserver(
            forName: UIApplication.willEnterForegroundNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            print("CloudKit: App entering foreground, triggering sync")
            self?.onRemoteChange?()
        }
        #endif

        #if canImport(AppKit)
        NotificationCenter.default.addObserver(
            forName: NSApplication.willBecomeActiveNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            print("CloudKit: App becoming active, triggering sync")
            self?.onRemoteChange?()
        }

        // macOS: Also sync when app is already active (it may stay focused)
        NotificationCenter.default.addObserver(
            forName: NSApplication.didBecomeActiveNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.startPeriodicSync()
        }

        NotificationCenter.default.addObserver(
            forName: NSApplication.didResignActiveNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.stopPeriodicSync()
        }
        #endif
    }

    // MARK: - Periodic Sync (macOS)

    /// Start periodic sync polling when the app is active.
    /// This ensures macOS picks up iOS changes even when already focused.
    func startPeriodicSync() {
        guard periodicSyncTimer == nil else { return }
        print("CloudKit: Starting periodic sync (every \(Int(periodicSyncInterval))s)")
        periodicSyncTimer = Timer.scheduledTimer(withTimeInterval: periodicSyncInterval, repeats: true) { [weak self] _ in
            print("CloudKit: Periodic sync tick")
            self?.onRemoteChange?()
        }
    }

    func stopPeriodicSync() {
        periodicSyncTimer?.invalidate()
        periodicSyncTimer = nil
        print("CloudKit: Stopped periodic sync")
    }

    // MARK: - Zone Setup

    func setupZone() async throws {
        // Try to create the legacy zone if it doesn't exist
        let zone = CKRecordZone(zoneID: legacyZoneID)
        do {
            _ = try await container.privateCloudDatabase.save(zone)
        } catch let error as CKError where error.code == .serverRecordChanged {
            // Zone already exists - that's fine
        } catch let error as CKError where error.code == .zoneNotFound {
            // Zone doesn't exist, create it
            _ = try await container.privateCloudDatabase.save(zone)
        }

        // Setup subscription for remote changes
        await setupSubscription()
    }

    // MARK: - Subscription for Remote Changes

    private func setupSubscription() async {
        let subscriptionID = "plastik-zone-changes"

        // Check if subscription already exists
        do {
            _ = try await container.privateCloudDatabase.subscription(for: subscriptionID)
            print("CloudKit: Subscription already exists")
            return
        } catch {
            // Subscription doesn't exist, create it
        }

        // Create a subscription for all changes in our zone
        let subscription = CKDatabaseSubscription(subscriptionID: subscriptionID)

        let notificationInfo = CKSubscription.NotificationInfo()
        notificationInfo.shouldSendContentAvailable = true  // Silent push for background refresh

        subscription.notificationInfo = notificationInfo

        do {
            _ = try await container.privateCloudDatabase.save(subscription)
            print("CloudKit: Created subscription for remote changes")
        } catch {
            print("CloudKit: Failed to create subscription: \(error)")
        }
    }

    // MARK: - User Cards

    func fetchUserCards() async throws -> [UserCard] {
        isSyncing = true
        defer { isSyncing = false }

        // Use CKFetchRecordZoneChangesOperation to fetch all records
        // This doesn't require queryable indexes
        return try await fetchAllRecordsFromZone(fullFetch: true)
    }

    /// Fetch only changes since last sync (incremental sync)
    func fetchChanges() async throws -> (changed: [UserCard], deletedRecordIDs: [String]) {
        isSyncing = true
        defer { isSyncing = false }

        // First, check if the zone exists
        let zones = try await container.privateCloudDatabase.allRecordZones()

        guard zones.contains(where: { $0.zoneID.zoneName == legacyZoneName }) else {
            print("CloudKit: Legacy zone '\(legacyZoneName)' not found")
            return ([], [])
        }

        // Fetch only changes since last sync
        let config = CKFetchRecordZoneChangesOperation.ZoneConfiguration()
        config.previousServerChangeToken = serverChangeToken

        return try await withCheckedThrowingContinuation { continuation in
            var changedCards: [UserCard] = []
            var deletedIDs: [String] = []

            let operation = CKFetchRecordZoneChangesOperation(
                recordZoneIDs: [self.legacyZoneID],
                configurationsByRecordZoneID: [self.legacyZoneID: config]
            )

            operation.recordWasChangedBlock = { recordID, result in
                switch result {
                case .success(let record):
                    if record.recordType == "UserCard",
                       let card = self.userCard(from: record) {
                        changedCards.append(card)
                        print("CloudKit: Changed card - \(card.cardId)")
                    }
                case .failure(let error):
                    print("CloudKit: Error fetching changed record \(recordID): \(error)")
                }
            }

            operation.recordWithIDWasDeletedBlock = { recordID, recordType in
                if recordType == "UserCard" {
                    deletedIDs.append(recordID.recordName)
                    print("CloudKit: Deleted card - \(recordID.recordName)")
                }
            }

            operation.recordZoneChangeTokensUpdatedBlock = { zoneID, token, _ in
                if zoneID == self.legacyZoneID {
                    self.serverChangeToken = token
                    print("CloudKit: Updated change token")
                }
            }

            operation.recordZoneFetchResultBlock = { zoneID, result in
                switch result {
                case .success(let (token, _, _)):
                    if zoneID == self.legacyZoneID {
                        self.serverChangeToken = token
                    }
                    print("CloudKit: Incremental fetch complete for \(zoneID.zoneName)")
                case .failure(let error):
                    print("CloudKit: Incremental fetch failed for \(zoneID.zoneName): \(error)")
                }
            }

            operation.fetchRecordZoneChangesResultBlock = { result in
                switch result {
                case .success:
                    self.lastSyncDate = Date()
                    continuation.resume(returning: (changedCards, deletedIDs))
                case .failure(let error):
                    // If change token is invalid, clear it so next sync does full fetch
                    if let ckError = error as? CKError, ckError.code == .changeTokenExpired {
                        self.serverChangeToken = nil
                        print("CloudKit: Change token expired, will do full fetch next time")
                    }
                    continuation.resume(throwing: error)
                }
            }

            self.container.privateCloudDatabase.add(operation)
        }
    }

    private func fetchAllRecordsFromZone(fullFetch: Bool = false) async throws -> [UserCard] {
        // First, check if the zone exists
        let zones = try await container.privateCloudDatabase.allRecordZones()

        print("CloudKit: Found \(zones.count) zones")
        for zone in zones {
            print("  - Zone: \(zone.zoneID.zoneName)")
        }

        guard zones.contains(where: { $0.zoneID.zoneName == legacyZoneName }) else {
            print("CloudKit: Legacy zone '\(legacyZoneName)' not found")
            return []
        }

        // Fetch changes from the zone (gets all records without needing queryable indexes)
        let config = CKFetchRecordZoneChangesOperation.ZoneConfiguration()
        // For full fetch, ignore the change token
        config.previousServerChangeToken = fullFetch ? nil : serverChangeToken

        return try await withCheckedThrowingContinuation { continuation in
            var fetchedCards: [UserCard] = []

            let operation = CKFetchRecordZoneChangesOperation(
                recordZoneIDs: [legacyZoneID],
                configurationsByRecordZoneID: [legacyZoneID: config]
            )

            operation.recordWasChangedBlock = { recordID, result in
                switch result {
                case .success(let record):
                    if record.recordType == "UserCard",
                       let card = self.userCard(from: record) {
                        fetchedCards.append(card)
                        print("CloudKit: Found card - \(card.cardId)")
                    }
                case .failure(let error):
                    print("CloudKit: Error fetching record \(recordID): \(error)")
                }
            }

            operation.recordZoneChangeTokensUpdatedBlock = { zoneID, token, _ in
                if zoneID == self.legacyZoneID {
                    self.serverChangeToken = token
                }
            }

            operation.recordZoneFetchResultBlock = { zoneID, result in
                switch result {
                case .success(let (token, _, _)):
                    if zoneID == self.legacyZoneID {
                        self.serverChangeToken = token
                    }
                    print("CloudKit: Zone fetch complete for \(zoneID.zoneName)")
                case .failure(let error):
                    print("CloudKit: Zone fetch failed for \(zoneID.zoneName): \(error)")
                }
            }

            operation.fetchRecordZoneChangesResultBlock = { result in
                switch result {
                case .success:
                    fetchedCards.sort { $0.openDate > $1.openDate }
                    self.lastSyncDate = Date()
                    continuation.resume(returning: fetchedCards)
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }

            self.container.privateCloudDatabase.add(operation)
        }
    }

    func saveUserCard(_ card: UserCard) async throws {
        isSyncing = true
        defer { isSyncing = false }

        // Save to legacy zone for compatibility
        let recordID = CKRecord.ID(
            recordName: card.ckRecordID ?? card.id.uuidString,
            zoneID: legacyZoneID
        )

        // Try to fetch existing record first to get proper recordChangeTag
        // This prevents "record to insert already exists" errors
        let record: CKRecord
        do {
            record = try await container.privateCloudDatabase.record(for: recordID)
            print("CloudKit: Updating existing record for \(card.cardId)")
        } catch let error as CKError where error.code == .unknownItem {
            // Record doesn't exist yet, create new one
            record = CKRecord(recordType: "UserCard", recordID: recordID)
            print("CloudKit: Creating new record for \(card.cardId)")
        }

        // Update all fields on the record
        populateRecord(record, from: card)

        _ = try await container.privateCloudDatabase.save(record)
        lastSyncDate = Date()
        syncError = nil
        print("CloudKit: Saved card \(card.cardId) with all fields")
    }

    private func populateRecord(_ record: CKRecord, from card: UserCard) {
        // Core fields
        record["cardId"] = card.cardId as CKRecordValue
        record["nickname"] = card.nickname as CKRecordValue?
        record["lastFour"] = card.lastFourDigits as CKRecordValue?
        record["openDate"] = card.openDate as CKRecordValue
        record["isActive"] = (card.isActive ? 1 : 0) as CKRecordValue
        record["notes"] = card.notes as CKRecordValue?
        record["lastModified"] = card.lastModified as CKRecordValue

        // Date fields
        record["annualFeeDate"] = card.annualFeeDate as CKRecordValue?
        record["closedDate"] = card.closedDate as CKRecordValue?
        record["signupBonusReceivedDate"] = card.signupBonusReceivedDate as CKRecordValue?

        // Churn tracking fields
        record["productFamily"] = card.productFamily as CKRecordValue?
        record["isBusinessCard"] = (card.isBusinessCard ? 1 : 0) as CKRecordValue
        record["wasProductChanged"] = (card.wasProductChanged ? 1 : 0) as CKRecordValue
        record["productChangedFrom"] = card.productChangedFrom as CKRecordValue?

        // Signup bonus progress
        if let bonus = card.signupBonusProgress {
            record["bonusSpent"] = bonus.spentSoFar as CKRecordValue
            record["bonusTarget"] = bonus.targetSpend as CKRecordValue
            record["bonusDeadline"] = bonus.deadline as CKRecordValue
            record["bonusCompleted"] = (bonus.completed ? 1 : 0) as CKRecordValue
        } else {
            // Clear bonus fields if no progress
            record["bonusSpent"] = nil
            record["bonusTarget"] = nil
            record["bonusDeadline"] = nil
            record["bonusCompleted"] = nil
        }

        // Benefit usage (encoded as JSON for complex array)
        if !card.benefitUsage.isEmpty,
           let benefitData = try? JSONEncoder().encode(card.benefitUsage),
           let benefitString = String(data: benefitData, encoding: .utf8) {
            record["benefitUsageJSON"] = benefitString as CKRecordValue
        } else {
            record["benefitUsageJSON"] = nil
        }

        // New statement import fields
        if let balance = card.currentBalance {
            record["currentBalance"] = balance as CKRecordValue
        } else {
            record["currentBalance"] = nil
        }
        record["lastStatementDate"] = card.lastStatementDate as CKRecordValue?
        record["lastStatementFileName"] = card.lastStatementFileName as CKRecordValue?

        // Override fields (encode as JSON for complex types)
        record["issuerOverride"] = card.issuerOverride as CKRecordValue?
        record["productNameOverride"] = card.productNameOverride as CKRecordValue?
        record["networkOverride"] = card.networkOverride as CKRecordValue?
        if let fee = card.annualFeeOverride {
            record["annualFeeOverride"] = fee as CKRecordValue
        } else {
            record["annualFeeOverride"] = nil
        }
        if let ftf = card.foreignTransactionFeeOverride {
            record["foreignTransactionFeeOverride"] = ftf as CKRecordValue
        } else {
            record["foreignTransactionFeeOverride"] = nil
        }

        // Signup bonus override (encode as JSON)
        if let bonusOverride = card.signupBonusOverride,
           let bonusData = try? JSONEncoder().encode(bonusOverride),
           let bonusString = String(data: bonusData, encoding: .utf8) {
            record["signupBonusOverrideJSON"] = bonusString as CKRecordValue
        } else {
            record["signupBonusOverrideJSON"] = nil
        }

        // Reward categories override (encode as JSON)
        if let categories = card.rewardCategoriesOverride, !categories.isEmpty,
           let categoriesData = try? JSONEncoder().encode(categories),
           let categoriesString = String(data: categoriesData, encoding: .utf8) {
            record["rewardCategoriesOverrideJSON"] = categoriesString as CKRecordValue
        } else {
            record["rewardCategoriesOverrideJSON"] = nil
        }

        // Card icon color
        record["cardIconColor"] = card.cardIconColor as CKRecordValue?

        // Card status
        record["cardStatus"] = card.cardStatus.rawValue as CKRecordValue

        // Sort order and date added
        if let sortOrder = card.sortOrder {
            record["sortOrder"] = sortOrder as CKRecordValue
        } else {
            record["sortOrder"] = nil
        }
        record["dateAdded"] = card.dateAdded as CKRecordValue
    }

    func deleteUserCard(_ card: UserCard) async throws {
        let recordID = CKRecord.ID(
            recordName: card.ckRecordID ?? card.id.uuidString,
            zoneID: legacyZoneID
        )
        try await container.privateCloudDatabase.deleteRecord(withID: recordID)
    }

    // MARK: - Conflict Resolution

    func resolveConflict(local: UserCard, server: UserCard) -> UserCard {
        if local.lastModified > server.lastModified {
            return local
        }
        return server
    }

    // MARK: - Helpers

    private func userCard(from record: CKRecord) -> UserCard? {
        guard let cardId = record["cardId"] as? String,
              let openDate = record["openDate"] as? Date else {
            return nil
        }

        let isActive = (record["isActive"] as? Int ?? 1) == 1
        let isBusinessCard = (record["isBusinessCard"] as? Int ?? 0) == 1
        let wasProductChanged = (record["wasProductChanged"] as? Int ?? 0) == 1

        // Parse signup bonus progress
        var bonusProgress: BonusProgress?
        if let spent = record["bonusSpent"] as? Int,
           let target = record["bonusTarget"] as? Int,
           let deadline = record["bonusDeadline"] as? Date {
            let completed = (record["bonusCompleted"] as? Int ?? 0) == 1 || spent >= target
            bonusProgress = BonusProgress(
                spentSoFar: spent,
                targetSpend: target,
                deadline: deadline,
                completed: completed
            )
        }

        // Parse benefit usage from JSON
        var benefitUsage: [BenefitUsage] = []
        if let benefitJSON = record["benefitUsageJSON"] as? String,
           let benefitData = benefitJSON.data(using: .utf8),
           let decoded = try? JSONDecoder().decode([BenefitUsage].self, from: benefitData) {
            benefitUsage = decoded
        }

        // Parse signup bonus override from JSON
        var signupBonusOverride: SignupBonusOverride?
        if let bonusJSON = record["signupBonusOverrideJSON"] as? String,
           let bonusData = bonusJSON.data(using: .utf8),
           let decoded = try? JSONDecoder().decode(SignupBonusOverride.self, from: bonusData) {
            signupBonusOverride = decoded
        }

        // Parse reward categories override from JSON
        var rewardCategoriesOverride: [UserRewardCategory]?
        if let categoriesJSON = record["rewardCategoriesOverrideJSON"] as? String,
           let categoriesData = categoriesJSON.data(using: .utf8),
           let decoded = try? JSONDecoder().decode([UserRewardCategory].self, from: categoriesData) {
            rewardCategoriesOverride = decoded
        }

        // Parse card status
        let cardStatus: CardStatus
        if let statusRaw = record["cardStatus"] as? String,
           let status = CardStatus(rawValue: statusRaw) {
            cardStatus = status
        } else if let closedDate = record["closedDate"] as? Date {
            cardStatus = .closed
        } else if wasProductChanged {
            cardStatus = .productChanged
        } else {
            cardStatus = isActive ? .active : .closed
        }

        return UserCard(
            id: UUID(uuidString: record.recordID.recordName) ?? UUID(),
            cardId: cardId,
            nickname: record["nickname"] as? String,
            lastFourDigits: record["lastFour"] as? String,
            openDate: openDate,
            annualFeeDate: record["annualFeeDate"] as? Date,
            signupBonusProgress: bonusProgress,
            benefitUsage: benefitUsage,
            isActive: isActive,
            notes: record["notes"] as? String,
            closedDate: record["closedDate"] as? Date,
            signupBonusReceivedDate: record["signupBonusReceivedDate"] as? Date,
            productFamily: record["productFamily"] as? String,
            isBusinessCard: isBusinessCard,
            wasProductChanged: wasProductChanged,
            productChangedFrom: record["productChangedFrom"] as? String,
            ckRecordID: record.recordID.recordName,
            lastModified: record["lastModified"] as? Date ?? Date(),
            sortOrder: record["sortOrder"] as? Int,
            dateAdded: record["dateAdded"] as? Date,
            issuerOverride: record["issuerOverride"] as? String,
            productNameOverride: record["productNameOverride"] as? String,
            networkOverride: record["networkOverride"] as? String,
            annualFeeOverride: record["annualFeeOverride"] as? Int,
            foreignTransactionFeeOverride: record["foreignTransactionFeeOverride"] as? Double,
            signupBonusOverride: signupBonusOverride,
            rewardCategoriesOverride: rewardCategoriesOverride,
            cardIconColor: record["cardIconColor"] as? String,
            cardStatus: cardStatus,
            currentBalance: record["currentBalance"] as? Double,
            lastStatementDate: record["lastStatementDate"] as? Date,
            lastStatementFileName: record["lastStatementFileName"] as? String
        )
    }
}
