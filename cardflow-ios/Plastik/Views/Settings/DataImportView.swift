import SwiftUI
import UniformTypeIdentifiers

struct DataImportView: View {
    @Environment(CardViewModel.self) private var cardViewModel
    @Environment(DataFeedService.self) private var feedService

    @State private var showFilePicker = false
    @State private var isProcessing = false
    @State private var parsedStatement: ParsedStatement?
    @State private var errorMessage: String?
    @State private var selectedCardId: String?

    private let parser = PDFParserService()

    var body: some View {
        List {
            instructionsSection
            importSection
            if isProcessing { progressSection }
            if let error = errorMessage { errorSection(error) }
            if let statement = parsedStatement { resultsSection(statement) }
            supportedFormatsSection
        }
        .navigationTitle("Import Data")
        .fileImporter(
            isPresented: $showFilePicker,
            allowedContentTypes: [UTType.pdf],
            allowsMultipleSelection: false
        ) { result in
            handleFileImport(result)
        }
    }

    // MARK: - Sections

    @ViewBuilder
    private var instructionsSection: some View {
        Section {
            VStack(alignment: .leading, spacing: 8) {
                Text("Import credit card statements to automatically track spending toward signup bonuses.")
                    .font(.body)
                    .foregroundStyle(.secondary)
                Text("Transactions are parsed using on-device OCR. No data leaves your device.")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
        }
    }

    @ViewBuilder
    private var importSection: some View {
        Section("PDF Import") {
            if parsedStatement == nil {
                // Card selector
                Picker("Statement Card", selection: Binding(
                    get: { selectedCardId ?? "" },
                    set: { selectedCardId = $0.isEmpty ? nil : $0 }
                )) {
                    Text("Select a card...").tag("")
                    ForEach(cardViewModel.userCards.filter { $0.isActive }) { userCard in
                        if let card = feedService.card(for: userCard.cardId) {
                            Text(userCard.nickname ?? card.name).tag(userCard.cardId)
                        }
                    }
                }
            }

            Button {
                showFilePicker = true
            } label: {
                Label("Select PDF Statement", systemImage: "doc.fill")
            }
            .disabled(isProcessing)
        }
    }

    @ViewBuilder
    private var progressSection: some View {
        Section {
            HStack {
                ProgressView()
                    .controlSize(.small)
                Text("Parsing statement...")
                    .font(.body)
                    .foregroundStyle(.secondary)
            }
        }
    }

    @ViewBuilder
    private func errorSection(_ error: String) -> some View {
        Section {
            HStack {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundStyle(.red)
                Text(error)
                    .font(.caption)
                    .foregroundStyle(.red)
            }

            Button("Try Again") {
                errorMessage = nil
                showFilePicker = true
            }
        }
    }

    @ViewBuilder
    private func resultsSection(_ statement: ParsedStatement) -> some View {
        Section("Results") {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Total Spend")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text("$\(Int(statement.totalSpend).commaFormatted)")
                        .font(.title2.bold())
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 2) {
                    Text("Transactions")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text("\(statement.transactions.count)")
                        .font(.title2.bold())
                }
            }

            if let last4 = statement.cardLastFour {
                LabeledContent("Card Ending In", value: last4)
            }
            if let date = statement.statementDate {
                LabeledContent("Statement Date", value: date.shortFormatted)
            }
        }

        // Category breakdown
        Section("Spending by Category") {
            let grouped = Dictionary(grouping: statement.transactions) { $0.category ?? .other }
            let sorted = grouped.sorted { a, b in
                a.value.reduce(0) { $0 + $1.amount } > b.value.reduce(0) { $0 + $1.amount }
            }

            ForEach(sorted, id: \.key) { category, txns in
                let total = txns.reduce(0.0) { $0 + $1.amount }
                HStack {
                    Image(systemName: category.icon)
                        .frame(width: 24)
                        .foregroundStyle(.blue)
                    Text(category.displayName)
                    Spacer()
                    Text("$\(Int(total).commaFormatted)")
                        .font(.headline)
                    Text("(\(txns.count))")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }

        // Transactions list
        Section("Transactions (\(statement.transactions.count))") {
            ForEach(statement.transactions) { txn in
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(txn.description)
                            .font(.body)
                            .lineLimit(1)
                        HStack(spacing: 4) {
                            if let date = txn.date {
                                Text(date.shortFormatted)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            if let cat = txn.category {
                                Text(cat.displayName)
                                    .font(.caption2)
                                    .padding(.horizontal, 4)
                                    .padding(.vertical, 1)
                                    .background(Color.blue.opacity(0.1))
                                    .clipShape(RoundedRectangle(cornerRadius: 3))
                            }
                        }
                    }
                    Spacer()
                    Text("$\(String(format: "%.2f", txn.amount))")
                        .font(.body.monospacedDigit())
                }
            }
        }

        // Apply to bonus tracking
        Section {
            if let cardId = selectedCardId,
               let index = cardViewModel.userCards.firstIndex(where: { $0.cardId == cardId }),
               let bonus = cardViewModel.userCards[index].signupBonusProgress,
               !bonus.completed {
                let newTotal = bonus.spentSoFar + Int(statement.totalSpend)
                VStack(alignment: .leading, spacing: 4) {
                    Text("Apply $\(Int(statement.totalSpend).commaFormatted) to signup bonus?")
                        .font(.body)
                    Text("Current: $\(bonus.spentSoFar.commaFormatted) → New: $\(newTotal.commaFormatted) of $\(bonus.targetSpend.commaFormatted)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Button {
                    cardViewModel.updateBonusSpend(
                        for: cardViewModel.userCards[index].id,
                        amount: newTotal
                    )
                    parsedStatement = nil
                } label: {
                    Label("Apply to Bonus Progress", systemImage: "plus.circle.fill")
                }
                .buttonStyle(.borderedProminent)
            }

            Button("Clear Results") {
                parsedStatement = nil
                errorMessage = nil
            }
        }
    }

    @ViewBuilder
    private var supportedFormatsSection: some View {
        Section("Supported Formats") {
            Label("Chase Statements", systemImage: "checkmark.circle.fill")
                .foregroundStyle(.green)
            Label("Amex Statements", systemImage: "checkmark.circle.fill")
                .foregroundStyle(.green)
            Label("Citi Statements", systemImage: "checkmark.circle.fill")
                .foregroundStyle(.green)
            Label("Other Issuers", systemImage: "checkmark.circle")
                .foregroundStyle(.secondary)
        }
    }

    // MARK: - Import Handler

    private func handleFileImport(_ result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            guard let url = urls.first else { return }

            guard url.startAccessingSecurityScopedResource() else {
                errorMessage = "Unable to access the selected file."
                return
            }

            isProcessing = true
            errorMessage = nil
            parsedStatement = nil

            Task {
                defer {
                    url.stopAccessingSecurityScopedResource()
                }

                do {
                    let statement = try await parser.parseStatement(from: url)
                    await MainActor.run {
                        self.parsedStatement = statement
                        self.isProcessing = false
                    }
                } catch {
                    await MainActor.run {
                        self.errorMessage = error.localizedDescription
                        self.isProcessing = false
                    }
                }
            }

        case .failure(let error):
            errorMessage = error.localizedDescription
        }
    }
}
