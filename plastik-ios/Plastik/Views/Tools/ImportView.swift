import SwiftUI
import UniformTypeIdentifiers

struct ImportView: View {
    @Environment(CardViewModel.self) private var cardViewModel
    @Environment(DataFeedService.self) private var feedService

    // State
    @State private var selectedUserCard: UserCard?
    @State private var importState: ImportState = .idle
    @State private var pastedText: String = ""
    @State private var isDragOver = false
    @State private var showFilePicker = false
    @State private var processingFileName: String = ""
    @State private var showSupportedIssuers = false

    // Preview state
    @State private var parsedStatement: ParsedStatement?
    @State private var showTransactions = false
    @State private var showMismatchWarning = false

    // History
    @State private var importHistory: [ImportHistoryItem] = []

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 32) {
                // Page Header
                pageHeader

                // Card Selector (only if user has cards)
                if !cardViewModel.userCards.isEmpty {
                    cardSelectorSection
                } else {
                    noCardsEmptyState
                }

                // Import Area (only if card is selected)
                if selectedUserCard != nil {
                    importSection
                }

                // Preview Section (when we have parsed data)
                if case .preview(let statement) = importState {
                    previewSection(statement: statement)
                }

                // Success State
                if case .success(let cardName, let count, let bonusUpdate) = importState {
                    successView(cardName: cardName, transactionCount: count, bonusProgressUpdate: bonusUpdate)
                }

                // Error State
                if case .error(let message) = importState {
                    errorView(message: message)
                }

                // Supported Formats
                supportedFormatsSection

                // Import History
                importHistorySection
            }
            .padding(24)
            .frame(maxWidth: 1200)
            .frame(maxWidth: .infinity)
        }
        .navigationTitle("Import")
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
        .fileImporter(
            isPresented: $showFilePicker,
            allowedContentTypes: [.pdf, .commaSeparatedText, .spreadsheet],
            allowsMultipleSelection: false
        ) { result in
            handleFileImport(result)
        }
        .onAppear {
            // Auto-select first card if only one exists
            if cardViewModel.userCards.count == 1 {
                selectedUserCard = cardViewModel.userCards.first
            }
        }
    }

    // MARK: - Page Header

    private var pageHeader: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Import Statement")
                .font(.system(size: 24, weight: .semibold))

            Text("Import your credit card statement to update balances, track transactions, and detect benefits usage. Supports PDF, CSV, and Excel files — drag a file, browse, or paste text directly.")
                .font(.system(size: 15))
                .foregroundStyle(.secondary)
        }
    }

    // MARK: - Card Selector Section

    private var cardSelectorSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Select Card")
                .font(.system(size: 17, weight: .semibold))

            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Text("Import to:")
                        .font(.system(size: 14, weight: .medium))

                    Picker("", selection: $selectedUserCard) {
                        Text("Choose a card...").tag(nil as UserCard?)
                        ForEach(cardViewModel.userCards) { userCard in
                            // Show ALL user cards with simplified label for iOS compatibility
                            Text(cardLabelFor(userCard))
                                .tag(userCard as UserCard?)
                        }
                    }
                    .labelsHidden()
                    .pickerStyle(.menu) // Use menu style on both platforms for consistency
                    #if os(macOS)
                    .frame(maxWidth: 350)
                    #endif
                }

                // Tip
                HStack(alignment: .top, spacing: 8) {
                    Image(systemName: "lightbulb")
                        .foregroundStyle(.yellow)
                        .font(.system(size: 14))

                    Text("Select the card that matches your statement. If you need to add a new card, go to Cards first.")
                        .font(.system(size: 13))
                        .foregroundStyle(.secondary)
                }
                .padding(12)
                .background(Color.yellow.opacity(0.1))
                .cornerRadius(8)
            }
            .padding(16)
            #if os(iOS)
            .background(Color(.secondarySystemBackground))
            #else
            .background(Color(nsColor: .controlBackgroundColor))
            #endif
            .cornerRadius(12)
        }
    }

    private var noCardsEmptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "creditcard.trianglebadge.exclamationmark")
                .font(.system(size: 40))
                .foregroundStyle(.tertiary)

            Text("No cards added yet")
                .font(.system(size: 17, weight: .medium))

            Text("Add a card first to import statements")
                .font(.system(size: 15))
                .foregroundStyle(.secondary)

            NavigationLink(destination: Text("Add Card View")) {
                Label("Add Card", systemImage: "plus")
            }
            .buttonStyle(.borderedProminent)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
        #if os(iOS)
        .background(Color(.secondarySystemBackground))
        #else
        .background(Color(nsColor: .controlBackgroundColor))
        #endif
        .cornerRadius(12)
    }

    // MARK: - Import Section

    private var importSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Import Statement")
                .font(.system(size: 17, weight: .semibold))

            // Processing state
            if case .processing(let progress, let status) = importState {
                processingView(progress: progress, status: status)
            } else if case .idle = importState {
                importInputArea
            }
        }
    }

    private var importInputArea: some View {
        VStack(spacing: 0) {
            // Drop zone
            ZStack {
                RoundedRectangle(cornerRadius: 16)
                    .fill(isDragOver ? Color.accentColor.opacity(0.08) : dropZoneBackgroundColor)

                RoundedRectangle(cornerRadius: 16)
                    .strokeBorder(
                        isDragOver ? Color.accentColor : borderColor,
                        style: StrokeStyle(lineWidth: 2, dash: isDragOver ? [] : [8, 4])
                    )

                VStack(spacing: 20) {
                    // Drop area
                    VStack(spacing: 12) {
                        Image(systemName: "doc.badge.arrow.up")
                            .font(.system(size: 48))
                            .foregroundStyle(isDragOver ? Color.accentColor : .secondary)
                            .scaleEffect(isDragOver ? 1.1 : 1.0)
                            .animation(.easeInOut(duration: 0.3), value: isDragOver)

                        Text(isDragOver ? "Release to import" : "Drop PDF, CSV, or Excel file here")
                            .font(.system(size: 17, weight: .semibold))
                    }
                    .frame(maxWidth: .infinity)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        showFilePicker = true
                    }

                    // Divider with "or"
                    HStack {
                        Rectangle()
                            .fill(Color.secondary.opacity(0.3))
                            .frame(height: 1)
                        Text("or")
                            .font(.system(size: 13))
                            .foregroundStyle(.tertiary)
                            .padding(.horizontal, 16)
                        Rectangle()
                            .fill(Color.secondary.opacity(0.3))
                            .frame(height: 1)
                    }
                    .padding(.horizontal, 32)

                    // Text paste area
                    VStack(alignment: .leading, spacing: 8) {
                        TextEditor(text: $pastedText)
                            .font(.system(size: 13, design: .monospaced))
                            .scrollContentBackground(.hidden)
                            .padding(8)
                            .frame(height: 150)
                            .background(textAreaBackgroundColor)
                            .cornerRadius(8)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(borderColor, lineWidth: 1)
                            )
                            .overlay(alignment: .topLeading) {
                                if pastedText.isEmpty {
                                    Text("Paste your statement text here (⌘V)...")
                                        .font(.system(size: 13))
                                        .foregroundStyle(.tertiary)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 12)
                                        .allowsHitTesting(false)
                                }
                            }

                        if !pastedText.isEmpty {
                            Text("\(pastedText.count) characters")
                                .font(.system(size: 11))
                                .foregroundStyle(.tertiary)
                        }
                    }
                    .padding(.horizontal, 16)

                    // Buttons
                    HStack(spacing: 16) {
                        Button {
                            showFilePicker = true
                        } label: {
                            Label("Select PDF, CSV, or Excel", systemImage: "folder")
                                .font(.system(size: 14, weight: .medium))
                        }
                        .buttonStyle(.bordered)

                        Button {
                            importText()
                        } label: {
                            Label("Import Text", systemImage: "text.badge.checkmark")
                                .font(.system(size: 14, weight: .medium))
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(pastedText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    }
                }
                .padding(24)
            }
            .frame(minHeight: 380)
            .animation(.easeOut(duration: 0.15), value: isDragOver)
            .onDrop(of: [.pdf, .commaSeparatedText, .spreadsheet, .fileURL], isTargeted: $isDragOver) { providers in
                handleDrop(providers)
            }
        }
    }

    private func processingView(progress: Double, status: String) -> some View {
        VStack(spacing: 20) {
            Image(systemName: "doc.fill")
                .font(.system(size: 32))
                .foregroundStyle(.secondary)

            Text(processingFileName)
                .font(.system(size: 15))
                .foregroundStyle(.secondary)

            VStack(spacing: 8) {
                ProgressView(value: progress)
                    .progressViewStyle(.linear)
                    .frame(maxWidth: 300)

                Text("\(Int(progress * 100))%")
                    .font(.system(size: 13, design: .monospaced))
                    .foregroundStyle(.secondary)
            }

            Text(status)
                .font(.system(size: 13))
                .foregroundStyle(.tertiary)

            Button("Cancel", role: .cancel) {
                importState = .idle
            }
            .buttonStyle(.borderless)
            .foregroundStyle(.red)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 60)
        #if os(iOS)
        .background(Color(.secondarySystemBackground))
        #else
        .background(Color(nsColor: .controlBackgroundColor))
        #endif
        .cornerRadius(16)
    }

    // MARK: - Preview Section

    @ViewBuilder
    private func previewSection(statement: ParsedStatement) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header with success icon
            HStack(spacing: 12) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 24))
                    .foregroundStyle(.green)

                VStack(alignment: .leading, spacing: 2) {
                    Text("Successfully parsed statement")
                        .font(.system(size: 17, weight: .semibold))
                    Text("Review the data below before applying")
                        .font(.system(size: 13))
                        .foregroundStyle(.secondary)
                }

                Spacer()
            }

            // Mismatch warning
            if showMismatchWarning {
                mismatchWarningBanner(statement: statement)
            }

            // Card Assignment
            cardAssignmentSection(statement: statement)

            // Statement Summary
            statementSummarySection(statement: statement)

            // Transactions
            transactionsSection(statement: statement)

            // Detected Benefits
            if !statement.detectedBenefits.isEmpty {
                benefitsSection(statement: statement)
            }

            // Action Buttons
            HStack {
                Button {
                    clearPreview()
                } label: {
                    Text("Clear")
                        .font(.system(size: 14, weight: .medium))
                }
                .buttonStyle(.bordered)

                Spacer()

                Button {
                    applyImport(statement: statement)
                } label: {
                    Label("Apply to Card", systemImage: "checkmark")
                        .font(.system(size: 14, weight: .medium))
                }
                .buttonStyle(.borderedProminent)
                .disabled(selectedUserCard == nil)
            }
            .padding(.top, 8)
        }
        .padding(20)
        #if os(iOS)
        .background(Color(.secondarySystemBackground))
        #else
        .background(Color(nsColor: .controlBackgroundColor))
        #endif
        .cornerRadius(12)
        .onAppear {
            setupPreviewState(statement: statement)
        }
    }

    private func mismatchWarningBanner(statement: ParsedStatement) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(.orange)
                .font(.system(size: 18))

            VStack(alignment: .leading, spacing: 4) {
                Text("Possible issuer mismatch")
                    .font(.system(size: 14, weight: .semibold))

                if let detected = statement.detectedIssuer {
                    Text("This statement appears to be from \(detected.displayName). If this is incorrect, tap Clear and select the correct card.")
                        .font(.system(size: 13))
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.orange.opacity(0.1))
        .cornerRadius(8)
    }

    private func cardAssignmentSection(statement: ParsedStatement) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Importing To")
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(.secondary)

            // Read-only card display
            HStack(spacing: 12) {
                // Card icon
                Image(systemName: "creditcard.fill")
                    .font(.system(size: 20))
                    .foregroundStyle(.blue)

                VStack(alignment: .leading, spacing: 2) {
                    if let userCard = selectedUserCard,
                       let catalogCard = feedService.cards.first(where: { $0.id == userCard.cardId }) {
                        // Show nickname if set, otherwise card name
                        Text(userCard.nickname ?? catalogCard.name)
                            .font(.system(size: 15, weight: .medium))
                        Text("\(catalogCard.issuer.displayName) \(catalogCard.name)")
                            .font(.system(size: 13))
                            .foregroundStyle(.secondary)
                    } else if let userCard = selectedUserCard {
                        // Custom card
                        Text(userCard.nickname ?? "Custom Card")
                            .font(.system(size: 15, weight: .medium))
                        Text("Custom Card")
                            .font(.system(size: 13))
                            .foregroundStyle(.secondary)
                    }
                }

                Spacer()

                // Checkmark to indicate confirmed selection
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 18))
                    .foregroundStyle(.green)
            }
            .padding(12)
            .background(textAreaBackgroundColor)
            .cornerRadius(8)

            // Help text
            HStack(alignment: .top, spacing: 6) {
                Image(systemName: "info.circle")
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)

                Text("To import to a different card, tap Clear and select another card.")
                    .font(.system(size: 12))
                    .foregroundStyle(.tertiary)
            }
        }
    }

    private func statementSummarySection(statement: ParsedStatement) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Statement Summary")
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(.secondary)

            VStack(spacing: 0) {
                SummaryRow(label: "Statement Period", value: statement.statementPeriodFormatted)
                Divider()
                if let previous = statement.previousBalance {
                    SummaryRow(label: "Previous Balance", value: formatCurrency(previous))
                    Divider()
                }
                if let payments = statement.paymentsReceived {
                    SummaryRow(label: "Payments Received", value: formatCurrency(payments), valueColor: .green)
                    Divider()
                }
                if let charges = statement.newCharges {
                    SummaryRow(label: "New Charges", value: formatCurrency(charges))
                    Divider()
                }
                SummaryRow(label: "Current Balance", value: formatCurrency(statement.currentBalance), isBold: true)
                Divider()
                if let minPayment = statement.minimumPayment {
                    SummaryRow(label: "Minimum Payment", value: formatCurrency(minPayment))
                    Divider()
                }
                if let dueDate = statement.paymentDueDate {
                    SummaryRow(label: "Payment Due Date", value: dueDate.formatted(.dateTime.month(.abbreviated).day().year()))
                }
            }
            .background(textAreaBackgroundColor)
            .cornerRadius(8)
        }
    }

    private func transactionsSection(statement: ParsedStatement) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Button {
                withAnimation {
                    showTransactions.toggle()
                }
            } label: {
                HStack {
                    Text("Transactions (\(statement.transactions.count))")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundStyle(.secondary)

                    Spacer()

                    Image(systemName: showTransactions ? "chevron.up" : "chevron.down")
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                }
            }
            .buttonStyle(.plain)

            if showTransactions {
                VStack(spacing: 0) {
                    ForEach(statement.transactions.prefix(10)) { transaction in
                        TransactionPreviewRow(transaction: transaction)
                        if transaction.id != statement.transactions.prefix(10).last?.id {
                            Divider()
                        }
                    }

                    if statement.transactions.count > 10 {
                        Text("... and \(statement.transactions.count - 10) more transactions")
                            .font(.system(size: 13))
                            .foregroundStyle(.tertiary)
                            .padding(.vertical, 12)
                    }
                }
                .background(textAreaBackgroundColor)
                .cornerRadius(8)
            }
        }
    }

    private func benefitsSection(statement: ParsedStatement) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Detected Benefits Usage")
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(.secondary)

            VStack(spacing: 0) {
                ForEach(statement.detectedBenefits) { benefit in
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                            .font(.system(size: 14))

                        Text(benefit.name)
                            .font(.system(size: 14))

                        Spacer()

                        Text(formatCurrency(benefit.amount))
                            .font(.system(size: 14, weight: .medium))
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)

                    if benefit.id != statement.detectedBenefits.last?.id {
                        Divider()
                    }
                }
            }
            .background(textAreaBackgroundColor)
            .cornerRadius(8)
        }
    }

    // MARK: - Success/Error Views

    private func successView(cardName: String, transactionCount: Int, bonusProgressUpdate: Int?) -> some View {
        VStack(spacing: 16) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 48))
                .foregroundStyle(.green)

            Text("Import Successful!")
                .font(.system(size: 20, weight: .semibold))

            Text("Imported \(transactionCount) transactions to \(cardName)")
                .font(.system(size: 15))
                .foregroundStyle(.secondary)

            if let bonusUpdate = bonusProgressUpdate, bonusUpdate > 0 {
                HStack(spacing: 6) {
                    Image(systemName: "star.fill")
                        .foregroundStyle(.yellow)
                    Text("Added $\(bonusUpdate.commaFormatted) to signup bonus progress")
                        .font(.system(size: 14))
                        .foregroundStyle(.secondary)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color.yellow.opacity(0.1))
                .cornerRadius(8)
            }

            Button("Import Another") {
                importState = .idle
                pastedText = ""
            }
            .buttonStyle(.bordered)
            .padding(.top, 8)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
        #if os(iOS)
        .background(Color(.secondarySystemBackground))
        #else
        .background(Color(nsColor: .controlBackgroundColor))
        #endif
        .cornerRadius(12)
    }

    private func errorView(message: String) -> some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 48))
                .foregroundStyle(.red)

            Text("Unable to Parse Statement")
                .font(.system(size: 20, weight: .semibold))

            Text(message)
                .font(.system(size: 15))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            HStack(spacing: 16) {
                Button("Try Again") {
                    importState = .idle
                }
                .buttonStyle(.borderedProminent)

                Button("Report Issue") {
                    // Open feedback
                }
                .buttonStyle(.bordered)
            }
            .padding(.top, 8)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
        #if os(iOS)
        .background(Color(.secondarySystemBackground))
        #else
        .background(Color(nsColor: .controlBackgroundColor))
        #endif
        .cornerRadius(12)
    }

    // MARK: - Supported Formats

    private var supportedFormatsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Button {
                withAnimation {
                    showSupportedIssuers.toggle()
                }
            } label: {
                HStack {
                    Text("Supported Formats")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(.primary)

                    Spacer()

                    Image(systemName: showSupportedIssuers ? "chevron.up" : "chevron.down")
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                }
            }
            .buttonStyle(.plain)

            if showSupportedIssuers {
                VStack(alignment: .leading, spacing: 12) {
                    // File format support
                    Text("Supported file types:")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(.secondary)

                    HStack(spacing: 8) {
                        FormatTypeBadge(format: "PDF", icon: "doc.fill")
                        FormatTypeBadge(format: "CSV", icon: "tablecells")
                        FormatTypeBadge(format: "Excel", icon: "tablecells.fill")
                    }

                    Divider()

                    // Issuer-specific support
                    Text("Issuer support:")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(.secondary)

                    HStack(spacing: 8) {
                        FormatBadge(issuer: "Chase", formats: ["PDF", "CSV", "Excel"])
                        FormatBadge(issuer: "Amex", formats: ["PDF", "CSV"])
                        FormatBadge(issuer: "Citi", formats: ["PDF", "CSV"])
                        FormatBadge(issuer: "Capital One", formats: ["PDF", "CSV"])
                        FormatBadge(issuer: "Discover", formats: ["PDF"])
                    }
                }
            }
        }
    }

    // MARK: - Import History

    private var importHistorySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Import History")
                    .font(.system(size: 17, weight: .semibold))

                Spacer()

                if !importHistory.isEmpty {
                    Button("Clear") {
                        importHistory.removeAll()
                    }
                    .font(.system(size: 13))
                    .foregroundStyle(.secondary)
                }
            }

            if importHistory.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "folder.badge.questionmark")
                        .font(.system(size: 32))
                        .foregroundStyle(.tertiary)

                    Text("No imports yet")
                        .font(.system(size: 15))
                        .foregroundStyle(.secondary)

                    Text("Import a statement to see your history here")
                        .font(.system(size: 13))
                        .foregroundStyle(.tertiary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 40)
                #if os(iOS)
                .background(Color(.secondarySystemBackground))
                #else
                .background(Color(nsColor: .controlBackgroundColor))
                #endif
                .cornerRadius(12)
            } else {
                VStack(spacing: 0) {
                    ForEach(importHistory) { item in
                        ImportHistoryRowView(item: item)
                        if item.id != importHistory.last?.id {
                            Divider().padding(.leading, 44)
                        }
                    }
                }
                #if os(iOS)
                .background(Color(.secondarySystemBackground))
                #else
                .background(Color(nsColor: .controlBackgroundColor))
                #endif
                .cornerRadius(12)
            }
        }
    }

    // MARK: - Helpers

    /// Creates a simple string label for a user card (for iOS picker compatibility)
    /// Shows user's nickname first if set, with product name in parentheses for context
    private func cardLabelFor(_ userCard: UserCard) -> String {
        if let card = feedService.cards.first(where: { $0.id == userCard.cardId }) {
            // Card exists in catalog
            if let nickname = userCard.nickname, !nickname.isEmpty {
                // User has set a nickname - show it first with product name for context
                return "\(nickname) (\(card.name))"
            } else {
                // No nickname - show "Issuer ProductName"
                return "\(card.issuer.displayName) \(card.name)"
            }
        } else {
            // Card not in catalog - show nickname or fallback
            return "\(userCard.nickname ?? "Unknown Card") (Custom)"
        }
    }

    private var dropZoneBackgroundColor: Color {
        #if os(iOS)
        return Color(.secondarySystemBackground)
        #else
        return Color(nsColor: .controlBackgroundColor)
        #endif
    }

    private var textAreaBackgroundColor: Color {
        #if os(iOS)
        return Color(.tertiarySystemBackground)
        #else
        return Color(nsColor: .textBackgroundColor).opacity(0.5)
        #endif
    }

    private var borderColor: Color {
        #if os(iOS)
        return Color(.separator)
        #else
        return Color(nsColor: .separatorColor)
        #endif
    }

    private func formatCurrency(_ amount: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        return formatter.string(from: NSNumber(value: amount)) ?? "$\(amount)"
    }

    // MARK: - Actions

    private func handleFileImport(_ result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            guard let url = urls.first else { return }
            processFile(url)
        case .failure(let error):
            importState = .error(error.localizedDescription)
        }
    }

    private func handleDrop(_ providers: [NSItemProvider]) -> Bool {
        guard let provider = providers.first else { return false }

        // Handle file URL drops (macOS needs security-scoped resource access)
        if provider.hasItemConformingToTypeIdentifier(UTType.fileURL.identifier) {
            provider.loadItem(forTypeIdentifier: UTType.fileURL.identifier, options: nil) { item, error in
                if let error = error {
                    DispatchQueue.main.async {
                        self.importState = .error("Failed to load dropped file: \(error.localizedDescription)")
                    }
                    return
                }

                var fileURL: URL?
                if let data = item as? Data,
                   let path = String(data: data, encoding: .utf8) {
                    // Try file:// URL first, then raw path
                    fileURL = URL(string: path) ?? URL(fileURLWithPath: path)
                } else if let url = item as? URL {
                    fileURL = url
                }

                guard let url = fileURL else {
                    DispatchQueue.main.async {
                        self.importState = .error("Could not read dropped file URL")
                    }
                    return
                }

                // For macOS, start security-scoped access before dispatching
                let hasAccess = url.startAccessingSecurityScopedResource()

                DispatchQueue.main.async {
                    self.processDroppedFile(url, hasSecurityAccess: hasAccess)
                }
            }
            return true
        }

        // Handle direct PDF drops - loadFileRepresentation copies to temp location
        // The temp file is only valid within this callback, so copy it ourselves
        if provider.hasItemConformingToTypeIdentifier(UTType.pdf.identifier) {
            provider.loadFileRepresentation(forTypeIdentifier: UTType.pdf.identifier) { tempURL, error in
                if let error = error {
                    DispatchQueue.main.async {
                        self.importState = .error("Failed to load PDF: \(error.localizedDescription)")
                    }
                    return
                }

                guard let tempURL = tempURL else {
                    DispatchQueue.main.async {
                        self.importState = .error("Could not access dropped PDF")
                    }
                    return
                }

                // Copy the temp file to our own location before it's deleted
                do {
                    let fileManager = FileManager.default
                    let tempDir = fileManager.temporaryDirectory
                    let destURL = tempDir.appendingPathComponent(UUID().uuidString + "_" + tempURL.lastPathComponent)
                    try fileManager.copyItem(at: tempURL, to: destURL)

                    DispatchQueue.main.async {
                        self.processDroppedFile(destURL, hasSecurityAccess: false, shouldCleanup: true)
                    }
                } catch {
                    DispatchQueue.main.async {
                        self.importState = .error("Failed to copy dropped PDF: \(error.localizedDescription)")
                    }
                }
            }
            return true
        }

        // Handle direct Excel/spreadsheet drops
        if provider.hasItemConformingToTypeIdentifier(UTType.spreadsheet.identifier) {
            provider.loadFileRepresentation(forTypeIdentifier: UTType.spreadsheet.identifier) { tempURL, error in
                if let error = error {
                    DispatchQueue.main.async {
                        self.importState = .error("Failed to load Excel file: \(error.localizedDescription)")
                    }
                    return
                }

                guard let tempURL = tempURL else {
                    DispatchQueue.main.async {
                        self.importState = .error("Could not access dropped Excel file")
                    }
                    return
                }

                // Copy the temp file to our own location before it's deleted
                do {
                    let fileManager = FileManager.default
                    let tempDir = fileManager.temporaryDirectory
                    let destURL = tempDir.appendingPathComponent(UUID().uuidString + "_" + tempURL.lastPathComponent)
                    try fileManager.copyItem(at: tempURL, to: destURL)

                    DispatchQueue.main.async {
                        self.processDroppedFile(destURL, hasSecurityAccess: false, shouldCleanup: true)
                    }
                } catch {
                    DispatchQueue.main.async {
                        self.importState = .error("Failed to copy dropped Excel file: \(error.localizedDescription)")
                    }
                }
            }
            return true
        }

        // Handle direct CSV drops
        if provider.hasItemConformingToTypeIdentifier(UTType.commaSeparatedText.identifier) {
            provider.loadFileRepresentation(forTypeIdentifier: UTType.commaSeparatedText.identifier) { tempURL, error in
                if let error = error {
                    DispatchQueue.main.async {
                        self.importState = .error("Failed to load CSV file: \(error.localizedDescription)")
                    }
                    return
                }

                guard let tempURL = tempURL else {
                    DispatchQueue.main.async {
                        self.importState = .error("Could not access dropped CSV file")
                    }
                    return
                }

                // Copy the temp file to our own location before it's deleted
                do {
                    let fileManager = FileManager.default
                    let tempDir = fileManager.temporaryDirectory
                    let destURL = tempDir.appendingPathComponent(UUID().uuidString + "_" + tempURL.lastPathComponent)
                    try fileManager.copyItem(at: tempURL, to: destURL)

                    DispatchQueue.main.async {
                        self.processDroppedFile(destURL, hasSecurityAccess: false, shouldCleanup: true)
                    }
                } catch {
                    DispatchQueue.main.async {
                        self.importState = .error("Failed to copy dropped CSV file: \(error.localizedDescription)")
                    }
                }
            }
            return true
        }

        return false
    }

    /// Process a file from drag-and-drop with proper resource cleanup
    private func processDroppedFile(_ url: URL, hasSecurityAccess: Bool, shouldCleanup: Bool = false) {
        processingFileName = url.lastPathComponent
        importState = .processing(progress: 0, status: "Reading file...")

        let fileExtension = url.pathExtension.lowercased()

        Task {
            defer {
                // Clean up security-scoped access
                if hasSecurityAccess {
                    url.stopAccessingSecurityScopedResource()
                }
                // Clean up temp file if we created it
                if shouldCleanup {
                    try? FileManager.default.removeItem(at: url)
                }
            }

            do {
                await MainActor.run {
                    importState = .processing(progress: 0.2, status: "Reading file...")
                }

                let statement: ParsedStatement

                switch fileExtension {
                case "pdf":
                    await MainActor.run {
                        importState = .processing(progress: 0.4, status: "Extracting text from PDF...")
                    }

                    let pdfParser = PDFParserService()
                    statement = try await pdfParser.parseStatement(from: url)

                case "xlsx", "xls":
                    await MainActor.run {
                        importState = .processing(progress: 0.4, status: "Reading Excel file...")
                    }

                    await MainActor.run {
                        importState = .processing(progress: 0.6, status: "Parsing transactions...")
                    }

                    statement = try StatementParser.parseExcel(
                        url: url,
                        fileName: url.lastPathComponent
                    )

                case "csv":
                    await MainActor.run {
                        importState = .processing(progress: 0.4, status: "Reading CSV file...")
                    }

                    let fileContent = try String(contentsOf: url, encoding: .utf8)

                    await MainActor.run {
                        importState = .processing(progress: 0.6, status: "Detecting issuer...")
                    }

                    await MainActor.run {
                        importState = .processing(progress: 0.8, status: "Parsing transactions...")
                    }

                    statement = StatementParser.parse(
                        text: fileContent,
                        sourceType: .csvFile,
                        fileName: url.lastPathComponent
                    )

                default:
                    await MainActor.run {
                        importState = .processing(progress: 0.4, status: "Reading file content...")
                    }

                    let fileContent = try String(contentsOf: url, encoding: .utf8)

                    await MainActor.run {
                        importState = .processing(progress: 0.6, status: "Parsing transactions...")
                    }

                    statement = StatementParser.parse(
                        text: fileContent,
                        sourceType: .pastedText,
                        fileName: url.lastPathComponent
                    )
                }

                await MainActor.run {
                    importState = .processing(progress: 1.0, status: "Complete!")
                    parsedStatement = statement
                    importState = .preview(statement)
                }

            } catch {
                await MainActor.run {
                    importState = .error("Failed to parse file: \(error.localizedDescription)")
                }
            }
        }
    }

    private func processFile(_ url: URL) {
        processingFileName = url.lastPathComponent
        importState = .processing(progress: 0, status: "Reading file...")

        let fileExtension = url.pathExtension.lowercased()

        Task {
            do {
                // Start security-scoped access for files from file picker
                let hasAccess = url.startAccessingSecurityScopedResource()
                defer {
                    if hasAccess {
                        url.stopAccessingSecurityScopedResource()
                    }
                }

                await MainActor.run {
                    importState = .processing(progress: 0.2, status: "Reading file...")
                }

                let statement: ParsedStatement

                switch fileExtension {
                case "pdf":
                    // Use PDFParserService for actual PDF parsing with OCR
                    await MainActor.run {
                        importState = .processing(progress: 0.4, status: "Extracting text from PDF...")
                    }

                    let pdfParser = PDFParserService()
                    statement = try await pdfParser.parseStatement(from: url)

                case "xlsx", "xls":
                    // Parse Excel file
                    await MainActor.run {
                        importState = .processing(progress: 0.4, status: "Reading Excel file...")
                    }

                    await MainActor.run {
                        importState = .processing(progress: 0.6, status: "Parsing transactions...")
                    }

                    statement = try StatementParser.parseExcel(
                        url: url,
                        fileName: url.lastPathComponent
                    )

                case "csv":
                    // Parse CSV file
                    await MainActor.run {
                        importState = .processing(progress: 0.4, status: "Reading CSV file...")
                    }

                    let fileContent = try String(contentsOf: url, encoding: .utf8)

                    await MainActor.run {
                        importState = .processing(progress: 0.6, status: "Detecting issuer...")
                    }

                    await MainActor.run {
                        importState = .processing(progress: 0.8, status: "Parsing transactions...")
                    }

                    statement = StatementParser.parse(
                        text: fileContent,
                        sourceType: .csvFile,
                        fileName: url.lastPathComponent
                    )

                default:
                    // Try as text file
                    await MainActor.run {
                        importState = .processing(progress: 0.4, status: "Reading file content...")
                    }

                    let fileContent = try String(contentsOf: url, encoding: .utf8)

                    await MainActor.run {
                        importState = .processing(progress: 0.6, status: "Parsing transactions...")
                    }

                    statement = StatementParser.parse(
                        text: fileContent,
                        sourceType: .pastedText,
                        fileName: url.lastPathComponent
                    )
                }

                await MainActor.run {
                    importState = .processing(progress: 1.0, status: "Complete!")
                    parsedStatement = statement
                    importState = .preview(statement)
                }

            } catch {
                await MainActor.run {
                    importState = .error("Failed to parse file: \(error.localizedDescription)")
                }
            }
        }
    }

    private func importText() {
        guard !pastedText.isEmpty else { return }

        processingFileName = "Pasted text"
        importState = .processing(progress: 0, status: "Parsing text...")

        // Simulate parsing
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            let statement = StatementParser.parse(
                text: pastedText,
                sourceType: .pastedText,
                fileName: nil
            )
            parsedStatement = statement
            importState = .preview(statement)
        }
    }

    private func setupPreviewState(statement: ParsedStatement) {
        // Check if detected issuer differs from the pre-selected card
        if let userCard = selectedUserCard,
           let catalogCard = feedService.cards.first(where: { $0.id == userCard.cardId }),
           let detected = statement.detectedIssuer,
           detected != catalogCard.issuer {
            showMismatchWarning = true
        }
    }

    private func clearPreview() {
        importState = .idle
        parsedStatement = nil
        pastedText = ""
        showMismatchWarning = false
        // Keep selectedUserCard so user can import again or change their selection
    }

    private func applyImport(statement: ParsedStatement) {
        guard var userCard = selectedUserCard else { return }

        // Get card display name from the pre-selected user card
        let cardName: String
        let issuerName: String
        let cardId: String

        if let catalogCard = feedService.cards.first(where: { $0.id == userCard.cardId }) {
            // Catalog card - use nickname if set, otherwise product name
            cardName = userCard.nickname ?? catalogCard.name
            issuerName = catalogCard.issuer.displayName
            cardId = catalogCard.id
        } else {
            // Custom card
            cardName = userCard.nickname ?? "Custom Card"
            issuerName = "Custom"
            cardId = userCard.cardId
        }

        // Update card with imported statement data
        userCard.currentBalance = statement.currentBalance
        userCard.lastStatementDate = statement.statementPeriodEnd ?? Date()
        userCard.lastStatementFileName = statement.sourceFileName
        userCard.lastModified = Date()

        // Update signup bonus progress if the card has one tracking
        var bonusSpendAdded: Int? = nil
        if var bonusProgress = userCard.signupBonusProgress {
            // Use newCharges if available, otherwise use totalSpend from transactions
            let spendAmount = Int(statement.newCharges ?? statement.totalSpend)

            // Add the imported spend to the progress
            bonusProgress.spentSoFar += spendAmount
            bonusSpendAdded = spendAmount

            // Check if bonus is now completed
            if bonusProgress.spentSoFar >= bonusProgress.targetSpend && !bonusProgress.completed {
                bonusProgress.completed = true
            }

            userCard.signupBonusProgress = bonusProgress
        }

        // Save the updated card to the view model
        cardViewModel.updateCard(userCard)

        // Update our local selection to reflect the changes
        selectedUserCard = userCard

        // Add to history
        let historyItem = ImportHistoryItem(
            filename: statement.sourceFileName ?? "Pasted text",
            sourceType: statement.sourceType,
            cardId: cardId,
            cardName: cardName,
            issuerName: issuerName,
            transactionsImported: statement.transactions.count,
            balance: statement.currentBalance
        )
        importHistory.insert(historyItem, at: 0)

        // Show success
        importState = .success(cardName: cardName, transactionCount: statement.transactions.count, bonusProgressUpdate: bonusSpendAdded)
        parsedStatement = nil
        pastedText = ""
    }
}

// MARK: - Supporting Views

struct SummaryRow: View {
    let label: String
    let value: String
    var valueColor: Color = .primary
    var isBold: Bool = false

    var body: some View {
        HStack {
            Text(label)
                .font(.system(size: 14))
                .foregroundStyle(.secondary)

            Spacer()

            Text(value)
                .font(.system(size: 14, weight: isBold ? .semibold : .regular))
                .foregroundStyle(valueColor)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
    }
}

struct TransactionPreviewRow: View {
    let transaction: ParsedTransaction

    var body: some View {
        HStack {
            Text(transaction.date?.formatted(.dateTime.month(.abbreviated).day()) ?? "—")
                .font(.system(size: 13))
                .foregroundStyle(.secondary)
                .frame(width: 50, alignment: .leading)

            Text(transaction.description)
                .font(.system(size: 14))
                .lineLimit(1)

            Spacer()

            Text(formatCurrency(transaction.amount))
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(transaction.isCredit ? .green : .primary)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
    }

    private func formatCurrency(_ amount: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        return formatter.string(from: NSNumber(value: amount)) ?? "$\(amount)"
    }
}

struct FormatBadge: View {
    let issuer: String
    let formats: [String]

    var body: some View {
        VStack(spacing: 4) {
            Text(issuer)
                .font(.system(size: 12, weight: .medium))

            HStack(spacing: 4) {
                ForEach(formats, id: \.self) { format in
                    Text(format)
                        .font(.system(size: 10, weight: .medium))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.accentColor.opacity(0.2))
                        .cornerRadius(4)
                }
            }
        }
        .padding(8)
        #if os(iOS)
        .background(Color(.tertiarySystemBackground))
        #else
        .background(Color(nsColor: .windowBackgroundColor))
        #endif
        .cornerRadius(8)
    }
}

struct FormatTypeBadge: View {
    let format: String
    let icon: String

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 12))
                .foregroundColor(.accentColor)

            Text(format)
                .font(.system(size: 13, weight: .medium))
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        #if os(iOS)
        .background(Color(.tertiarySystemBackground))
        #else
        .background(Color(nsColor: .windowBackgroundColor))
        #endif
        .cornerRadius(8)
    }
}

struct ImportHistoryRowView: View {
    let item: ImportHistoryItem

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: item.sourceType == "Text" ? "doc.text" : "doc.fill")
                .font(.system(size: 20))
                .foregroundStyle(.secondary)
                .frame(width: 32)

            VStack(alignment: .leading, spacing: 2) {
                Text(item.filename)
                    .font(.system(size: 14, weight: .medium))
                    .lineLimit(1)

                Text("\(item.cardName) • \(item.date.formatted(.dateTime.month(.abbreviated).day().year())) • \(item.transactionsImported) transactions")
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            Spacer()

            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(.green)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        ImportView()
    }
    .environment(CardViewModel())
    .environment(DataFeedService())
}
