import SwiftUI
#if DEBUG

/// Debug test dashboard accessible from Settings.
/// Provides UI controls for soak tests, stress tests, and spike tests.
struct DebugTestView: View {
    @Environment(DataFeedService.self) private var feedService
    @Environment(CardViewModel.self) private var cardViewModel

    @State private var isRunningStress = false
    @State private var isRunningSpike = false
    @State private var stressResults: [StressTestHelper.StressTestResult] = []
    @State private var spikeResults: [SpikeTestHelper.SpikeTestResult] = []
    @State private var memoryReport: String = ""

    var body: some View {
        List {
            soakTestSection
            stressTestSection
            spikeTestSection
            memoryReportSection
        }
        .navigationTitle("Debug Tests")
        .onAppear { refreshMemoryReport() }
    }

    // MARK: - Soak Test

    @ViewBuilder
    private var soakTestSection: some View {
        Section {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Memory Monitor")
                        .font(.headline)
                    Text("Logs memory usage every 60 seconds to detect leaks")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Circle()
                    .fill(MemoryMonitor.shared.isMonitoring ? .green : .gray)
                    .frame(width: 10, height: 10)
            }

            if MemoryMonitor.shared.isMonitoring {
                Button("Stop Monitoring", role: .destructive) {
                    MemoryMonitor.shared.stopMonitoring()
                    refreshMemoryReport()
                }
            } else {
                Button("Start Monitoring") {
                    MemoryMonitor.shared.startMonitoring()
                    refreshMemoryReport()
                }
            }

            HStack {
                Text("Current Memory")
                Spacer()
                Text("\(MemoryMonitor.shared.currentUsageMB) MB")
                    .foregroundStyle(.secondary)
            }

            HStack {
                Text("Samples")
                Spacer()
                Text("\(MemoryMonitor.shared.sampleCount)")
                    .foregroundStyle(.secondary)
            }

            if MemoryMonitor.shared.sampleCount > 0 {
                HStack {
                    Text("Peak")
                    Spacer()
                    Text("\(MemoryMonitor.shared.peakUsageMB) MB")
                        .foregroundStyle(.secondary)
                }

                HStack {
                    Text("Leak Detected")
                    Spacer()
                    Image(systemName: MemoryMonitor.shared.isMemoryGrowing ? "exclamationmark.triangle.fill" : "checkmark.circle.fill")
                        .foregroundStyle(MemoryMonitor.shared.isMemoryGrowing ? .yellow : .green)
                }

                Button("Clear Log") {
                    MemoryMonitor.shared.clearLog()
                    refreshMemoryReport()
                }
            }
        } header: {
            Label("Soak Test", systemImage: "drop.fill")
        }
    }

    // MARK: - Stress Test

    @ViewBuilder
    private var stressTestSection: some View {
        Section {
            Text("Tests eligibility calculations, data parsing, and retention analysis under load")
                .font(.caption)
                .foregroundStyle(.secondary)

            Button {
                runStressTests()
            } label: {
                HStack {
                    if isRunningStress {
                        ProgressView()
                            .controlSize(.small)
                        Text("Running...")
                    } else {
                        Image(systemName: "bolt.fill")
                        Text("Run Stress Tests")
                    }
                }
            }
            .disabled(isRunningStress)

            ForEach(Array(stressResults.enumerated()), id: \.offset) { _, result in
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Image(systemName: result.passed ? "checkmark.circle.fill" : "xmark.circle.fill")
                            .foregroundStyle(result.passed ? .green : .red)
                        Text(result.scenario)
                            .font(.subheadline.bold())
                    }
                    HStack(spacing: 16) {
                        Label("\(String(format: "%.1f", result.duration))s", systemImage: "clock")
                        Label("\(result.peakMemoryMB)MB", systemImage: "memorychip")
                        Label("\(result.operationsCompleted) ops", systemImage: "number")
                    }
                    .font(.caption)
                    .foregroundStyle(.secondary)

                    if !result.errors.isEmpty {
                        Text("Errors: \(result.errors.first ?? "")")
                            .font(.caption2)
                            .foregroundStyle(.red)
                    }
                }
                .padding(.vertical, 2)
            }
        } header: {
            Label("Stress Test", systemImage: "bolt.horizontal.fill")
        }
    }

    // MARK: - Spike Test

    @ViewBuilder
    private var spikeTestSection: some View {
        Section {
            Text("Tests first-launch restore, bulk import, and rapid navigation")
                .font(.caption)
                .foregroundStyle(.secondary)

            Button {
                runSpikeTests()
            } label: {
                HStack {
                    if isRunningSpike {
                        ProgressView()
                            .controlSize(.small)
                        Text("Running...")
                    } else {
                        Image(systemName: "waveform.path.ecg")
                        Text("Run Spike Tests")
                    }
                }
            }
            .disabled(isRunningSpike)

            ForEach(Array(spikeResults.enumerated()), id: \.offset) { _, result in
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Image(systemName: result.errors.isEmpty ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                            .foregroundStyle(result.errors.isEmpty ? .green : .yellow)
                        Text(result.scenario)
                            .font(.subheadline.bold())
                    }
                    HStack(spacing: 16) {
                        Label("\(String(format: "%.2f", result.timeToUsableState))s", systemImage: "clock")
                        Label("\(result.peakMemoryMB)MB", systemImage: "memorychip")
                        Label("\(result.itemsProcessed) items", systemImage: "tray.full")
                    }
                    .font(.caption)
                    .foregroundStyle(.secondary)

                    if !result.errors.isEmpty {
                        Text("Errors: \(result.errors.first ?? "")")
                            .font(.caption2)
                            .foregroundStyle(.red)
                    }
                }
                .padding(.vertical, 2)
            }
        } header: {
            Label("Spike Test", systemImage: "waveform.path.ecg")
        }
    }

    // MARK: - Memory Report

    @ViewBuilder
    private var memoryReportSection: some View {
        if !memoryReport.isEmpty {
            Section {
                Text(memoryReport)
                    .font(.system(.caption, design: .monospaced))
                    .foregroundStyle(.secondary)
            } header: {
                Label("Memory Report", systemImage: "chart.line.uptrend.xyaxis")
            }
        }
    }

    // MARK: - Actions

    private func runStressTests() {
        isRunningStress = true
        stressResults = []
        Task {
            let results = await StressTestHelper.runAllTests(
                feedService: feedService,
                cardViewModel: cardViewModel
            )
            await MainActor.run {
                stressResults = results
                isRunningStress = false
                refreshMemoryReport()
            }
        }
    }

    private func runSpikeTests() {
        isRunningSpike = true
        spikeResults = []
        Task {
            let results = await SpikeTestHelper.runAllTests(
                feedService: feedService,
                cardViewModel: cardViewModel
            )
            await MainActor.run {
                spikeResults = results
                isRunningSpike = false
                refreshMemoryReport()
            }
        }
    }

    private func refreshMemoryReport() {
        memoryReport = MemoryMonitor.shared.report
    }
}
#endif
