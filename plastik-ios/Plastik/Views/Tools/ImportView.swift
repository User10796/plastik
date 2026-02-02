import SwiftUI

struct ImportView: View {
    @Environment(CardViewModel.self) private var cardViewModel
    @Environment(DataFeedService.self) private var feedService
    @State private var showFilePicker = false
    @State private var isProcessing = false
    @State private var importResult: ImportResult?

    enum ImportResult {
        case success(Int)
        case error(String)
    }

    var body: some View {
        List {
            Section {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Image(systemName: "doc.text.fill")
                            .font(.title)
                            .foregroundStyle(.blue)
                        VStack(alignment: .leading) {
                            Text("Import Statement")
                                .font(.headline)
                            Text("Upload a PDF statement to automatically detect cards and transactions")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }

                    Button {
                        showFilePicker = true
                    } label: {
                        HStack {
                            Image(systemName: "square.and.arrow.down")
                            Text("Choose PDF File")
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(isProcessing)
                }
                .padding(.vertical, 8)
            }

            if isProcessing {
                Section {
                    HStack {
                        ProgressView()
                        Text("Processing statement...")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
            }

            if let result = importResult {
                Section {
                    switch result {
                    case .success(let count):
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(.green)
                            Text("Successfully imported \(count) transactions")
                        }
                    case .error(let message):
                        HStack {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundStyle(.red)
                            Text(message)
                        }
                    }
                }
            }

            Section("Supported Formats") {
                SupportedFormatRow(
                    issuer: "Chase",
                    formats: "PDF statements, CSV exports"
                )
                SupportedFormatRow(
                    issuer: "American Express",
                    formats: "PDF statements"
                )
                SupportedFormatRow(
                    issuer: "Citi",
                    formats: "PDF statements, CSV exports"
                )
                SupportedFormatRow(
                    issuer: "Capital One",
                    formats: "PDF statements"
                )
            }

            Section("Import History") {
                if importHistory.isEmpty {
                    Text("No imports yet")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(importHistory, id: \.date) { item in
                        HStack {
                            VStack(alignment: .leading) {
                                Text(item.filename)
                                    .font(.subheadline)
                                Text(item.date.shortFormatted)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            Text("\(item.transactionCount) txns")
                                .font(.caption)
                                .foregroundStyle(.blue)
                        }
                    }
                }
            }
        }
        .navigationTitle("Import")
        .fileImporter(
            isPresented: $showFilePicker,
            allowedContentTypes: [.pdf],
            allowsMultipleSelection: false
        ) { result in
            handleFileImport(result)
        }
    }

    private func handleFileImport(_ result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            guard urls.first != nil else { return }
            isProcessing = true
            // Simulate processing
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                isProcessing = false
                importResult = .success(15)
            }
        case .failure(let error):
            importResult = .error(error.localizedDescription)
        }
    }

    private var importHistory: [(filename: String, date: Date, transactionCount: Int)] {
        // Placeholder - would come from persistent storage
        []
    }
}

struct SupportedFormatRow: View {
    let issuer: String
    let formats: String

    var body: some View {
        HStack {
            Text(issuer)
                .font(.subheadline)
            Spacer()
            Text(formats)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}

#Preview {
    NavigationStack {
        ImportView()
    }
    .environment(CardViewModel())
    .environment(DataFeedService())
}
