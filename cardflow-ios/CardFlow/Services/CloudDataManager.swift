import Foundation

@Observable
class CloudDataManager {
    var isAvailable: Bool = false
    var lastSyncDate: Date?

    private var metadataQuery: NSMetadataQuery?
    private var fileURL: URL?
    private var localFallbackURL: URL?
    private var lastWriteDate: Date?

    var onDataChanged: ((CardFlowData) -> Void)?

    private static let directoryName = "CardFlow"
    private static let fileName = "cardflow-data.json"

    init() {
        setupLocalFallback()
        setupICloud()
    }

    deinit {
        stopMetadataQuery()
    }

    // MARK: - Setup

    private func setupLocalFallback() {
        let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let localDir = documentsURL.appendingPathComponent(Self.directoryName)
        try? FileManager.default.createDirectory(at: localDir, withIntermediateDirectories: true)
        localFallbackURL = localDir.appendingPathComponent(Self.fileName)
    }

    func setupICloud() {
        // Check if iCloud is available
        guard FileManager.default.ubiquityIdentityToken != nil else {
            isAvailable = false
            return
        }

        // Get the iCloud Drive Documents root.
        // On iOS, url(forUbiquityContainerIdentifier: nil) returns the app's
        // iCloud container. To access the shared iCloud Drive folder
        // (com~apple~CloudDocs) we look for the Documents path within it.
        // However, for cross-app compatibility with the Electron app which writes
        // to ~/Library/Mobile Documents/com~apple~CloudDocs/CardFlow/,
        // we use the general iCloud Drive container.
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self else { return }

            // url(forUbiquityContainerIdentifier:) can block, so call on background thread
            guard let iCloudRoot = FileManager.default.url(forUbiquityContainerIdentifier: nil) else {
                DispatchQueue.main.async {
                    self.isAvailable = false
                }
                return
            }

            // The iCloud container root for nil identifier gives us the app's default
            // ubiquity container. For shared iCloud Drive access, we navigate to
            // Documents within that container. The Electron app writes to
            // com~apple~CloudDocs/CardFlow/ which maps to the iCloud Drive root.
            let cardFlowDir = iCloudRoot.appendingPathComponent("Documents")
                .appendingPathComponent(Self.directoryName)

            do {
                try FileManager.default.createDirectory(
                    at: cardFlowDir,
                    withIntermediateDirectories: true,
                    attributes: nil
                )
            } catch {
                print("CloudDataManager: Failed to create iCloud directory: \(error)")
                DispatchQueue.main.async {
                    self.isAvailable = false
                }
                return
            }

            let url = cardFlowDir.appendingPathComponent(Self.fileName)

            DispatchQueue.main.async {
                self.fileURL = url
                self.isAvailable = true
                self.startMetadataQuery()
            }
        }
    }

    // MARK: - Metadata Query (Watch for External Changes)

    private func startMetadataQuery() {
        guard let fileURL else { return }

        let query = NSMetadataQuery()
        query.searchScopes = [NSMetadataQueryUbiquitousDocumentsScope, NSMetadataQueryUbiquitousDataScope]
        query.predicate = NSPredicate(format: "%K == %@", NSMetadataItemFSNameKey, Self.fileName)

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(metadataQueryDidUpdate),
            name: .NSMetadataQueryDidUpdate,
            object: query
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(metadataQueryDidFinishGathering),
            name: .NSMetadataQueryDidFinishGathering,
            object: query
        )

        metadataQuery = query
        query.start()
    }

    private func stopMetadataQuery() {
        metadataQuery?.stop()
        metadataQuery = nil
        NotificationCenter.default.removeObserver(self)
    }

    @objc private func metadataQueryDidFinishGathering(_ notification: Notification) {
        metadataQuery?.disableUpdates()
        handleMetadataQueryResults()
        metadataQuery?.enableUpdates()
    }

    @objc private func metadataQueryDidUpdate(_ notification: Notification) {
        metadataQuery?.disableUpdates()
        handleMetadataQueryResults()
        metadataQuery?.enableUpdates()
    }

    private func handleMetadataQueryResults() {
        // Debounce: ignore changes we just wrote (within 3 seconds)
        if let lastWrite = lastWriteDate, Date().timeIntervalSince(lastWrite) < 3.0 {
            return
        }

        guard let data = load() else { return }

        // Only notify if modified by another device/app
        if data.lastModifiedBy != "ios" {
            DispatchQueue.main.async { [weak self] in
                self?.lastSyncDate = Date()
                self?.onDataChanged?(data)
            }
        }
    }

    // MARK: - Load

    func load() -> CardFlowData? {
        let url = activeFileURL
        guard FileManager.default.fileExists(atPath: url.path) else {
            return nil
        }

        var loadedData: CardFlowData?
        var coordinatorError: NSError?

        let coordinator = NSFileCoordinator(filePresenter: nil)
        coordinator.coordinate(readingItemAt: url, options: [], error: &coordinatorError) { readURL in
            do {
                let data = try Data(contentsOf: readURL)
                let decoder = JSONDecoder()
                loadedData = try decoder.decode(CardFlowData.self, from: data)
            } catch {
                print("CloudDataManager: Failed to load data: \(error)")
            }
        }

        if let error = coordinatorError {
            print("CloudDataManager: File coordination error on read: \(error)")
        }

        return loadedData
    }

    // MARK: - Save

    func save(_ data: CardFlowData) {
        var mutableData = data
        mutableData.lastModified = ISO8601DateFormatter().string(from: Date())
        mutableData.lastModifiedBy = "ios"
        mutableData.schemaVersion = 1

        let url = activeFileURL
        var coordinatorError: NSError?

        let coordinator = NSFileCoordinator(filePresenter: nil)
        coordinator.coordinate(writingItemAt: url, options: .forReplacing, error: &coordinatorError) { writeURL in
            do {
                let encoder = JSONEncoder()
                encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
                let jsonData = try encoder.encode(mutableData)
                try jsonData.write(to: writeURL, options: .atomic)
                DispatchQueue.main.async { [weak self] in
                    self?.lastWriteDate = Date()
                    self?.lastSyncDate = Date()
                }
            } catch {
                print("CloudDataManager: Failed to save data: \(error)")
            }
        }

        if let error = coordinatorError {
            print("CloudDataManager: File coordination error on write: \(error)")
        }

        // Also save to local fallback
        if isAvailable, let fallbackURL = localFallbackURL {
            saveToLocal(data: mutableData, url: fallbackURL)
        }
    }

    // MARK: - Local Fallback

    func loadLocal() -> CardFlowData? {
        guard let url = localFallbackURL,
              FileManager.default.fileExists(atPath: url.path) else {
            return nil
        }
        do {
            let data = try Data(contentsOf: url)
            return try JSONDecoder().decode(CardFlowData.self, from: data)
        } catch {
            print("CloudDataManager: Failed to load local data: \(error)")
            return nil
        }
    }

    func saveLocal(_ data: CardFlowData) {
        guard let url = localFallbackURL else { return }
        var mutableData = data
        mutableData.lastModified = ISO8601DateFormatter().string(from: Date())
        mutableData.lastModifiedBy = "ios"
        saveToLocal(data: mutableData, url: url)
    }

    private func saveToLocal(data: CardFlowData, url: URL) {
        do {
            let encoder = JSONEncoder()
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            let jsonData = try encoder.encode(data)
            try jsonData.write(to: url, options: .atomic)
        } catch {
            print("CloudDataManager: Failed to save local fallback: \(error)")
        }
    }

    // MARK: - Helpers

    /// Returns the iCloud file URL if available, otherwise the local fallback URL.
    private var activeFileURL: URL {
        if isAvailable, let url = fileURL {
            return url
        }
        return localFallbackURL!
    }

    /// Merge on startup: use whichever data is newer (iCloud vs local).
    func mergeOnStartup() -> CardFlowData? {
        let iCloudData = isAvailable ? load() : nil
        let localData = loadLocal()

        switch (iCloudData, localData) {
        case let (cloud?, local?):
            // Compare timestamps, use newer
            let cloudDate = ISO8601DateFormatter().date(from: cloud.lastModified) ?? .distantPast
            let localDate = ISO8601DateFormatter().date(from: local.lastModified) ?? .distantPast
            if cloudDate >= localDate {
                saveLocal(cloud)
                return cloud
            } else {
                if isAvailable { save(local) }
                return local
            }
        case let (cloud?, nil):
            saveLocal(cloud)
            return cloud
        case let (nil, local?):
            if isAvailable { save(local) }
            return local
        case (nil, nil):
            return nil
        }
    }
}
