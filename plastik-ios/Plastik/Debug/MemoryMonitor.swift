import Foundation
#if DEBUG
import os

/// Soak test infrastructure: monitors memory usage over extended periods
/// to detect memory leaks and resource exhaustion.
///
/// Usage: Call `MemoryMonitor.shared.startMonitoring()` in debug builds
/// to begin 60-second interval memory logging.
class MemoryMonitor {
    static let shared = MemoryMonitor()

    private var timer: Timer?
    private var samples: [MemorySample] = []
    private let logger = Logger(subsystem: Constants.bundleID, category: "MemoryMonitor")
    private let logFileURL: URL

    struct MemorySample: Codable {
        let timestamp: Date
        let residentMB: Int
        let totalMB: Int
        let activeViewCount: Int
    }

    private init() {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
            ?? FileManager.default.temporaryDirectory
        logFileURL = docs.appendingPathComponent("memory_log.json")
    }

    // MARK: - Monitoring

    func startMonitoring(interval: TimeInterval = 60) {
        guard timer == nil else { return }
        logger.info("📊 Memory monitoring started (interval: \(interval)s)")

        // Capture initial sample immediately
        recordSample()

        timer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] _ in
            self?.recordSample()
        }
    }

    func stopMonitoring() {
        timer?.invalidate()
        timer = nil
        logger.info("📊 Memory monitoring stopped. \(self.samples.count) samples recorded.")
        persistLog()
    }

    var isMonitoring: Bool { timer != nil }

    // MARK: - Memory Reading

    func getMemoryUsage() -> (used: Int, total: Int) {
        var info = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size) / 4
        let result = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                task_info(mach_task_self_, task_flavor_t(MACH_TASK_BASIC_INFO), $0, &count)
            }
        }
        let usedMB = result == KERN_SUCCESS ? Int(info.resident_size / 1024 / 1024) : 0
        return (usedMB, Int(ProcessInfo.processInfo.physicalMemory / 1024 / 1024))
    }

    // MARK: - Analysis

    var currentUsageMB: Int { getMemoryUsage().used }
    var peakUsageMB: Int { samples.map(\.residentMB).max() ?? 0 }
    var averageUsageMB: Int {
        guard !samples.isEmpty else { return 0 }
        return samples.map(\.residentMB).reduce(0, +) / samples.count
    }

    /// Returns true if memory appears to be growing without plateauing.
    /// Uses a simple linear regression on the last 10 samples.
    var isMemoryGrowing: Bool {
        guard samples.count >= 10 else { return false }
        let recent = samples.suffix(10).map { Double($0.residentMB) }
        let n = Double(recent.count)
        let sumX = n * (n - 1) / 2
        let sumY = recent.reduce(0, +)
        let sumXY = recent.enumerated().map { Double($0.offset) * $0.element }.reduce(0, +)
        let sumX2 = (0..<Int(n)).map { Double($0 * $0) }.reduce(0, +)
        let slope = (n * sumXY - sumX * sumY) / (n * sumX2 - sumX * sumX)
        // If slope is > 1 MB per sample interval, memory is growing
        return slope > 1.0
    }

    var sampleCount: Int { samples.count }

    var report: String {
        let usage = getMemoryUsage()
        var lines = [
            "=== Memory Monitor Report ===",
            "Samples: \(samples.count)",
            "Current: \(usage.used) MB / \(usage.total) MB",
            "Peak:    \(peakUsageMB) MB",
            "Average: \(averageUsageMB) MB",
            "Growing: \(isMemoryGrowing ? "⚠️ YES" : "✅ No")"
        ]
        if let first = samples.first, let last = samples.last {
            let duration = last.timestamp.timeIntervalSince(first.timestamp)
            let hours = Int(duration) / 3600
            let minutes = (Int(duration) % 3600) / 60
            lines.append("Duration: \(hours)h \(minutes)m")
            lines.append("Growth:  \(last.residentMB - first.residentMB) MB")
        }
        return lines.joined(separator: "\n")
    }

    // MARK: - Private

    private func recordSample() {
        let usage = getMemoryUsage()
        let sample = MemorySample(
            timestamp: Date(),
            residentMB: usage.used,
            totalMB: usage.total,
            activeViewCount: 0
        )
        samples.append(sample)
        logger.info("📊 Memory: \(usage.used)MB / \(usage.total)MB (sample #\(self.samples.count))")

        // Check for potential leak
        if isMemoryGrowing {
            logger.warning("⚠️ Memory appears to be growing consistently. Possible leak detected.")
        }
    }

    private func persistLog() {
        do {
            let data = try JSONEncoder().encode(samples)
            try data.write(to: logFileURL)
            logger.info("📊 Memory log saved to \(self.logFileURL.path)")
        } catch {
            logger.error("Failed to save memory log: \(error.localizedDescription)")
        }
    }

    func clearLog() {
        samples.removeAll()
        try? FileManager.default.removeItem(at: logFileURL)
    }
}
#endif
