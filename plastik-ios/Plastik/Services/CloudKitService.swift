import Foundation
import CloudKit

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

    // MARK: - Zone Setup

    func setupZone() async throws {
        // Try to create the legacy zone if it doesn't exist
        let zone = CKRecordZone(zoneID: legacyZoneID)
        do {
            _ = try await container.privateCloudDatabase.save(zone)
        } catch let error as CKError where error.code == .serverRecordChanged {
            // Zone already exists - that's fine
        }
    }

    // MARK: - User Cards

    func fetchUserCards() async throws -> [UserCard] {
        isSyncing = true
        defer { isSyncing = false }

        // Use CKFetchRecordZoneChangesOperation to fetch all records
        // This doesn't require queryable indexes
        return try await fetchAllRecordsFromZone()
    }

    private func fetchAllRecordsFromZone() async throws -> [UserCard] {
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
        config.previousServerChangeToken = nil // Fetch all records

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

            operation.recordZoneFetchResultBlock = { zoneID, result in
                switch result {
                case .success:
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

            container.privateCloudDatabase.add(operation)
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
        let record = CKRecord(recordType: "UserCard", recordID: recordID)

        record["cardId"] = card.cardId as CKRecordValue
        record["nickname"] = card.nickname as CKRecordValue?
        record["lastFour"] = card.lastFourDigits as CKRecordValue?
        record["openDate"] = card.openDate as CKRecordValue
        record["isActive"] = (card.isActive ? 1 : 0) as CKRecordValue
        record["notes"] = card.notes as CKRecordValue?
        record["lastModified"] = card.lastModified as CKRecordValue

        if let bonus = card.signupBonusProgress {
            record["bonusSpent"] = bonus.spentSoFar as CKRecordValue
            record["bonusTarget"] = bonus.targetSpend as CKRecordValue
            record["bonusDeadline"] = bonus.deadline as CKRecordValue
        }

        _ = try await container.privateCloudDatabase.save(record)
        lastSyncDate = Date()
        syncError = nil
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

        var bonusProgress: BonusProgress?
        if let spent = record["bonusSpent"] as? Int,
           let target = record["bonusTarget"] as? Int,
           let deadline = record["bonusDeadline"] as? Date {
            bonusProgress = BonusProgress(
                spentSoFar: spent,
                targetSpend: target,
                deadline: deadline,
                completed: spent >= target
            )
        }

        return UserCard(
            id: UUID(uuidString: record.recordID.recordName) ?? UUID(),
            cardId: cardId,
            nickname: record["nickname"] as? String,
            lastFourDigits: record["lastFour"] as? String,
            openDate: openDate,
            signupBonusProgress: bonusProgress,
            isActive: isActive,
            notes: record["notes"] as? String,
            ckRecordID: record.recordID.recordName,
            lastModified: record["lastModified"] as? Date ?? Date()
        )
    }
}
