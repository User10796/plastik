import Foundation
import CloudKit

@Observable
class CloudKitService {
    var isSyncing = false
    var lastSyncDate: Date?
    var syncError: String?

    private let container = CKContainer(identifier: "iCloud.com.plastik.app")
    private let zoneName = "PlastikZone"
    private var zoneID: CKRecordZone.ID {
        CKRecordZone.ID(zoneName: zoneName, ownerName: CKCurrentUserDefaultName)
    }

    private let userCardsKey = "userCards"

    // MARK: - Zone Setup

    func setupZone() async throws {
        let zone = CKRecordZone(zoneID: zoneID)
        _ = try await container.privateCloudDatabase.save(zone)
    }

    // MARK: - User Cards

    func fetchUserCards() async throws -> [UserCard] {
        isSyncing = true
        defer { isSyncing = false }

        let query = CKQuery(recordType: "UserCard", predicate: NSPredicate(value: true))
        query.sortDescriptors = [NSSortDescriptor(key: "openDate", ascending: false)]

        let (results, _) = try await container.privateCloudDatabase.records(
            matching: query,
            inZoneWith: zoneID,
            resultsLimit: 100
        )

        var cards: [UserCard] = []
        for (_, result) in results {
            if let record = try? result.get(),
               let card = userCard(from: record) {
                cards.append(card)
            }
        }

        lastSyncDate = Date()
        syncError = nil
        return cards
    }

    func saveUserCard(_ card: UserCard) async throws {
        isSyncing = true
        defer { isSyncing = false }

        let record: CKRecord
        if let recordID = card.ckRecordID {
            record = CKRecord(recordType: "UserCard", recordID: CKRecord.ID(recordName: recordID, zoneID: zoneID))
        } else {
            record = CKRecord(recordType: "UserCard", recordID: CKRecord.ID(recordName: card.id.uuidString, zoneID: zoneID))
        }

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
            zoneID: zoneID
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
