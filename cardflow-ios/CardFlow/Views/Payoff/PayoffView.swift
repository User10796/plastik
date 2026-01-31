import SwiftUI

struct PayoffView: View {
    @Environment(DataStore.self) private var store
    @State private var editingCardId: Int?
    @State private var editBalanceText = ""

    private var debtCards: [CreditCard] {
        store.cards.filter { $0.currentBalance > 0 }.sorted { $0.currentBalance < $1.currentBalance }
    }

    private var totalDebt: Double {
        debtCards.reduce(0) { $0 + $1.currentBalance }
    }

    private var totalMonthlyInterest: Double {
        debtCards.reduce(0) { $0 + ($1.currentBalance * $1.apr / 100.0 / 12.0) }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    // Total Debt Summary
                    VStack(spacing: 12) {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Total Debt")
                                    .font(.caption)
                                    .foregroundColor(ColorTheme.textSecondary)
                                Text(Formatters.formatCurrency(totalDebt))
                                    .font(.title.weight(.bold))
                                    .foregroundColor(ColorTheme.red)
                            }
                            Spacer()
                            VStack(alignment: .trailing, spacing: 4) {
                                Text("Monthly Interest")
                                    .font(.caption)
                                    .foregroundColor(ColorTheme.textSecondary)
                                Text(Formatters.formatCurrency(totalMonthlyInterest))
                                    .font(.title3.weight(.bold))
                                    .foregroundColor(ColorTheme.gold)
                            }
                        }

                        HStack {
                            Text("\(debtCards.count) cards with balances")
                                .font(.caption)
                                .foregroundColor(ColorTheme.textMuted)
                            Spacer()
                            if !debtCards.isEmpty {
                                let avgApr = debtCards.reduce(0.0) { $0 + $1.apr } / Double(debtCards.count)
                                Text("Avg APR: \(String(format: "%.1f%%", avgApr))")
                                    .font(.caption)
                                    .foregroundColor(ColorTheme.textMuted)
                            }
                        }
                    }
                    .padding()
                    .background(ColorTheme.cardBg)
                    .cornerRadius(16)
                    .overlay(RoundedRectangle(cornerRadius: 16).stroke(ColorTheme.border, lineWidth: 1))

                    if debtCards.isEmpty {
                        VStack(spacing: 12) {
                            Image(systemName: "checkmark.seal.fill")
                                .font(.system(size: 48))
                                .foregroundColor(ColorTheme.green)
                            Text("No Balances!")
                                .font(.title3.weight(.semibold))
                                .foregroundColor(ColorTheme.textPrimary)
                            Text("All your cards have zero balance.")
                                .font(.subheadline)
                                .foregroundColor(ColorTheme.textSecondary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(40)
                        .background(ColorTheme.cardBg)
                        .cornerRadius(16)
                    } else {
                        // Snowball Order
                        VStack(alignment: .leading, spacing: 12) {
                            HStack(spacing: 8) {
                                Image(systemName: "arrow.down.circle.fill")
                                    .foregroundColor(ColorTheme.blue)
                                Text("Snowball Order (Smallest First)")
                                    .font(.headline)
                                    .foregroundColor(ColorTheme.textPrimary)
                            }

                            Text("Pay minimums on all cards, then put extra toward the smallest balance first.")
                                .font(.caption)
                                .foregroundColor(ColorTheme.textSecondary)
                        }
                        .padding()
                        .background(ColorTheme.cardBg)
                        .cornerRadius(12)

                        // Card List
                        ForEach(Array(debtCards.enumerated()), id: \.element.id) { index, card in
                            let monthlyInterest = card.currentBalance * card.apr / 100.0 / 12.0

                            VStack(spacing: 12) {
                                HStack {
                                    VStack(alignment: .leading, spacing: 4) {
                                        HStack(spacing: 8) {
                                            if index == 0 {
                                                Text("NEXT")
                                                    .font(.caption2.weight(.bold))
                                                    .foregroundColor(ColorTheme.green)
                                                    .padding(.horizontal, 6)
                                                    .padding(.vertical, 2)
                                                    .background(ColorTheme.green.opacity(0.15))
                                                    .cornerRadius(4)
                                            }
                                            Text("\(card.issuer) \(card.name)")
                                                .font(.subheadline.weight(.semibold))
                                                .foregroundColor(ColorTheme.textPrimary)
                                                .lineLimit(1)
                                        }

                                        Text("APR: \(String(format: "%.2f%%", card.apr))")
                                            .font(.caption)
                                            .foregroundColor(ColorTheme.textMuted)
                                    }

                                    Spacer()

                                    VStack(alignment: .trailing, spacing: 4) {
                                        // Tappable balance
                                        if editingCardId == card.id {
                                            HStack(spacing: 4) {
                                                TextField("Balance", text: $editBalanceText)
                                                    .keyboardType(.decimalPad)
                                                    .font(.subheadline.weight(.semibold))
                                                    .foregroundColor(ColorTheme.textPrimary)
                                                    .multilineTextAlignment(.trailing)
                                                    .frame(width: 100)
                                                    .padding(.horizontal, 8)
                                                    .padding(.vertical, 4)
                                                    .background(ColorTheme.surfaceBg)
                                                    .cornerRadius(6)
                                                    .onSubmit {
                                                        saveBalance(for: card)
                                                    }

                                                Button(action: { saveBalance(for: card) }) {
                                                    Image(systemName: "checkmark.circle.fill")
                                                        .foregroundColor(ColorTheme.green)
                                                }
                                            }
                                        } else {
                                            Button(action: {
                                                editingCardId = card.id
                                                editBalanceText = String(format: "%.2f", card.currentBalance)
                                            }) {
                                                Text(Formatters.formatCurrency(card.currentBalance))
                                                    .font(.subheadline.weight(.bold))
                                                    .foregroundColor(ColorTheme.red)
                                            }
                                        }

                                        Text("~\(Formatters.formatCurrency(monthlyInterest))/mo interest")
                                            .font(.caption)
                                            .foregroundColor(ColorTheme.gold)
                                    }
                                }

                                // Utilization bar
                                if card.creditLimit > 0 {
                                    let utilization = card.currentBalance / card.creditLimit
                                    VStack(spacing: 4) {
                                        ProgressView(value: min(utilization, 1.0))
                                            .tint(utilization > 0.3 ? ColorTheme.red : ColorTheme.green)
                                        HStack {
                                            Text("\(String(format: "%.0f%%", utilization * 100)) utilization")
                                                .font(.caption2)
                                                .foregroundColor(ColorTheme.textMuted)
                                            Spacer()
                                            Text("Limit: \(Formatters.formatCurrency(card.creditLimit))")
                                                .font(.caption2)
                                                .foregroundColor(ColorTheme.textMuted)
                                        }
                                    }
                                }
                            }
                            .padding()
                            .background(ColorTheme.cardBg)
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(index == 0 ? ColorTheme.green.opacity(0.5) : ColorTheme.border, lineWidth: 1)
                            )
                        }

                        // Monthly Payment Allocation
                        VStack(alignment: .leading, spacing: 12) {
                            HStack(spacing: 8) {
                                Image(systemName: "dollarsign.circle.fill")
                                    .foregroundColor(ColorTheme.gold)
                                Text("Payment Allocation")
                                    .font(.headline)
                                    .foregroundColor(ColorTheme.textPrimary)
                            }

                            Text("Suggested monthly allocation using the debt snowball method:")
                                .font(.caption)
                                .foregroundColor(ColorTheme.textSecondary)

                            ForEach(Array(debtCards.enumerated()), id: \.element.id) { index, card in
                                let minPayment = max(card.currentBalance * 0.02, 25)
                                HStack {
                                    HStack(spacing: 6) {
                                        Circle()
                                            .fill(index == 0 ? ColorTheme.green : ColorTheme.textMuted)
                                            .frame(width: 8, height: 8)
                                        Text("\(card.issuer) \(card.name)")
                                            .font(.caption)
                                            .foregroundColor(ColorTheme.textPrimary)
                                            .lineLimit(1)
                                    }
                                    Spacer()
                                    Text(index == 0 ? "Min + Extra" : Formatters.formatCurrency(minPayment))
                                        .font(.caption.weight(.medium))
                                        .foregroundColor(index == 0 ? ColorTheme.green : ColorTheme.textSecondary)
                                }
                            }

                            let totalMin = debtCards.reduce(0.0) { $0 + max($1.currentBalance * 0.02, 25) }
                            Divider().overlay(ColorTheme.border)
                            HStack {
                                Text("Total Minimums")
                                    .font(.caption.weight(.medium))
                                    .foregroundColor(ColorTheme.textSecondary)
                                Spacer()
                                Text(Formatters.formatCurrency(totalMin))
                                    .font(.caption.weight(.bold))
                                    .foregroundColor(ColorTheme.textPrimary)
                            }
                        }
                        .padding()
                        .background(ColorTheme.cardBg)
                        .cornerRadius(12)
                    }
                }
                .padding()
            }
            .background(ColorTheme.background)
            .navigationTitle("Debt Payoff")
        }
    }

    // MARK: - Actions

    private func saveBalance(for card: CreditCard) {
        guard let newBalance = Double(editBalanceText) else {
            editingCardId = nil
            return
        }
        var updated = card
        updated.currentBalance = newBalance
        store.updateCard(updated)
        editingCardId = nil
    }
}
