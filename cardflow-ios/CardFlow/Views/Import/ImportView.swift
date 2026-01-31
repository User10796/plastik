import SwiftUI

struct ImportView: View {
    @Environment(DataStore.self) private var store
    @State private var statementText = ""
    @State private var selectedCardIndex = 0
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var parseResult: [String: Any]?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    // API Key Warning
                    if store.apiKey.isEmpty {
                        HStack(spacing: 8) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(ColorTheme.gold)
                            Text("Set your Anthropic API key in Settings to use statement parsing.")
                                .font(.caption)
                                .foregroundColor(ColorTheme.gold)
                        }
                        .padding()
                        .background(Color(red: 95/255, green: 63/255, blue: 31/255).opacity(0.5))
                        .cornerRadius(12)
                    }

                    // Card Picker
                    if !store.cards.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Select Card")
                                .font(.caption)
                                .foregroundColor(ColorTheme.textSecondary)

                            Picker("Card", selection: $selectedCardIndex) {
                                ForEach(Array(store.cards.enumerated()), id: \.offset) { index, card in
                                    Text("\(card.issuer) \(card.name)")
                                        .tag(index)
                                }
                            }
                            .pickerStyle(.menu)
                            .tint(ColorTheme.gold)
                            .padding(12)
                            .background(ColorTheme.surfaceBg)
                            .cornerRadius(10)
                        }
                    }

                    // Statement Input
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Paste Statement Text")
                            .font(.caption)
                            .foregroundColor(ColorTheme.textSecondary)

                        TextEditor(text: $statementText)
                            .frame(minHeight: 180)
                            .padding(8)
                            .scrollContentBackground(.hidden)
                            .background(ColorTheme.surfaceBg)
                            .foregroundColor(ColorTheme.textPrimary)
                            .cornerRadius(10)
                            .overlay(
                                Group {
                                    if statementText.isEmpty {
                                        Text("Paste your credit card statement text here...")
                                            .foregroundColor(ColorTheme.textMuted)
                                            .padding(.horizontal, 12)
                                            .padding(.vertical, 16)
                                            .allowsHitTesting(false)
                                    }
                                },
                                alignment: .topLeading
                            )
                    }

                    // Parse Button
                    Button(action: parseStatement) {
                        HStack(spacing: 8) {
                            if isLoading {
                                ProgressView()
                                    .tint(ColorTheme.background)
                            }
                            Text(isLoading ? "Parsing..." : "Parse Statement")
                                .font(.headline)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(store.apiKey.isEmpty || statementText.isEmpty || isLoading ? ColorTheme.surfaceBg : ColorTheme.gold)
                        .foregroundColor(store.apiKey.isEmpty || statementText.isEmpty || isLoading ? ColorTheme.textMuted : ColorTheme.background)
                        .cornerRadius(12)
                    }
                    .disabled(store.apiKey.isEmpty || statementText.isEmpty || isLoading)

                    // Error Display
                    if let error = errorMessage {
                        HStack(spacing: 8) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(ColorTheme.red)
                            Text(error)
                                .font(.caption)
                                .foregroundColor(ColorTheme.red)
                        }
                        .padding()
                        .background(Color(red: 79/255, green: 31/255, blue: 31/255).opacity(0.5))
                        .cornerRadius(12)
                    }

                    // Parse Results
                    if let result = parseResult {
                        parsedResultsView(result)
                    }
                }
                .padding()
            }
            .background(ColorTheme.background)
            .navigationTitle("Import Statement")
        }
    }

    // MARK: - Parsed Results

    @ViewBuilder
    private func parsedResultsView(_ result: [String: Any]) -> some View {
        VStack(spacing: 16) {
            // Balance & Summary
            VStack(spacing: 12) {
                Text("Parsed Results")
                    .font(.headline)
                    .foregroundColor(ColorTheme.textPrimary)

                if let balance = result["balance"] as? Double {
                    HStack {
                        Text("Balance")
                            .foregroundColor(ColorTheme.textSecondary)
                        Spacer()
                        Text(Formatters.formatCurrency(balance))
                            .font(.title3.weight(.bold))
                            .foregroundColor(ColorTheme.red)
                    }
                }

                if let minPayment = result["minimumPayment"] as? Double {
                    HStack {
                        Text("Minimum Payment")
                            .foregroundColor(ColorTheme.textSecondary)
                        Spacer()
                        Text(Formatters.formatCurrency(minPayment))
                            .foregroundColor(ColorTheme.textPrimary)
                    }
                }

                if let dueDate = result["dueDate"] as? String {
                    HStack {
                        Text("Due Date")
                            .foregroundColor(ColorTheme.textSecondary)
                        Spacer()
                        Text(Formatters.formatDate(dueDate))
                            .foregroundColor(ColorTheme.textPrimary)
                    }
                }

                if let apr = result["apr"] as? Double {
                    HStack {
                        Text("APR")
                            .foregroundColor(ColorTheme.textSecondary)
                        Spacer()
                        Text(String(format: "%.2f%%", apr))
                            .foregroundColor(ColorTheme.gold)
                    }
                }
            }
            .font(.subheadline)
            .padding()
            .background(ColorTheme.cardBg)
            .cornerRadius(12)

            // Category Totals
            if let categoryTotals = result["categoryTotals"] as? [String: Any] {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Category Totals")
                        .font(.headline)
                        .foregroundColor(ColorTheme.textPrimary)

                    ForEach(categoryTotals.sorted(by: { ($0.value as? Double ?? 0) > ($1.value as? Double ?? 0) }), id: \.key) { key, value in
                        if let amount = value as? Double, amount > 0 {
                            HStack {
                                Text(key.capitalized)
                                    .font(.subheadline)
                                    .foregroundColor(ColorTheme.textSecondary)
                                Spacer()
                                Text(Formatters.formatCurrency(amount))
                                    .font(.subheadline.weight(.medium))
                                    .foregroundColor(ColorTheme.textPrimary)
                            }
                        }
                    }
                }
                .padding()
                .background(ColorTheme.cardBg)
                .cornerRadius(12)
            }

            // Transactions
            if let transactions = result["transactions"] as? [[String: Any]] {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Transactions (\(transactions.count))")
                        .font(.headline)
                        .foregroundColor(ColorTheme.textPrimary)

                    ForEach(Array(transactions.enumerated()), id: \.offset) { _, txn in
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(txn["description"] as? String ?? "Unknown")
                                    .font(.subheadline)
                                    .foregroundColor(ColorTheme.textPrimary)
                                    .lineLimit(1)
                                HStack(spacing: 8) {
                                    if let date = txn["date"] as? String {
                                        Text(Formatters.formatDate(date))
                                            .font(.caption)
                                            .foregroundColor(ColorTheme.textMuted)
                                    }
                                    if let category = txn["category"] as? String {
                                        Text(category)
                                            .font(.caption2.weight(.medium))
                                            .foregroundColor(ColorTheme.blue)
                                            .padding(.horizontal, 6)
                                            .padding(.vertical, 1)
                                            .background(ColorTheme.blue.opacity(0.15))
                                            .cornerRadius(4)
                                    }
                                }
                            }
                            Spacer()
                            if let amount = txn["amount"] as? Double {
                                Text(Formatters.formatCurrency(abs(amount)))
                                    .font(.subheadline.weight(.medium))
                                    .foregroundColor(amount < 0 ? ColorTheme.green : ColorTheme.textPrimary)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
                .padding()
                .background(ColorTheme.cardBg)
                .cornerRadius(12)
            }

            // Apply Button
            if let balance = result["balance"] as? Double, !store.cards.isEmpty {
                Button(action: {
                    applyBalance(balance)
                }) {
                    HStack(spacing: 8) {
                        Image(systemName: "checkmark.circle.fill")
                        Text("Apply Balance to \(store.cards[selectedCardIndex].name)")
                            .font(.headline)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(ColorTheme.green)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                }
            }
        }
    }

    // MARK: - Actions

    private func parseStatement() {
        guard !store.apiKey.isEmpty else {
            errorMessage = "Please set your Anthropic API key in Settings."
            return
        }

        isLoading = true
        errorMessage = nil
        parseResult = nil

        let service = AnthropicService(apiKey: store.apiKey)

        Task {
            do {
                let result = try await service.parseStatement(statementText)
                await MainActor.run {
                    parseResult = result
                    isLoading = false
                }
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    isLoading = false
                }
            }
        }
    }

    private func applyBalance(_ balance: Double) {
        guard selectedCardIndex < store.cards.count else { return }
        var card = store.cards[selectedCardIndex]
        card.currentBalance = balance
        store.updateCard(card)
    }
}
