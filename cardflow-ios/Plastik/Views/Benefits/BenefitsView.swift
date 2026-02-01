import SwiftUI

struct BenefitsView: View {
    @Environment(CardViewModel.self) private var cardViewModel
    @Environment(DataFeedService.self) private var feedService

    @State private var editingBenefitKey: String?
    @State private var usageInput = ""

    private var totalBenefitValue: Double {
        var total = 0.0
        for userCard in cardViewModel.userCards where userCard.isActive {
            if let card = feedService.card(for: userCard.cardId) {
                total += card.benefits.reduce(0.0) { $0 + $1.value }
            }
        }
        return total
    }

    private var totalUsed: Double {
        cardViewModel.userCards
            .filter { $0.isActive }
            .flatMap { $0.benefitUsage }
            .reduce(0.0) { $0 + $1.usedAmount }
    }

    var body: some View {
        List {
            summarySection

            ForEach(cardViewModel.userCards.filter { $0.isActive }) { userCard in
                if let card = feedService.card(for: userCard.cardId), !card.benefits.isEmpty {
                    Section(userCard.nickname ?? card.name) {
                        ForEach(card.benefits) { benefit in
                            let usage = userCard.benefitUsage.first { $0.benefitId == benefit.id }
                            let editKey = "\(userCard.id)-\(benefit.id)"

                            BenefitEditableRow(
                                benefit: benefit,
                                usage: usage,
                                isEditing: editingBenefitKey == editKey,
                                usageInput: editingBenefitKey == editKey ? $usageInput : .constant(""),
                                onTapEdit: {
                                    usageInput = usage.map { "\(Int($0.usedAmount))" } ?? "0"
                                    editingBenefitKey = editKey
                                },
                                onSave: { newAmount in
                                    updateBenefitUsage(
                                        userCardId: userCard.id,
                                        benefitId: benefit.id,
                                        amount: newAmount,
                                        benefit: benefit
                                    )
                                    editingBenefitKey = nil
                                    usageInput = ""
                                },
                                onCancel: {
                                    editingBenefitKey = nil
                                    usageInput = ""
                                }
                            )
                        }
                    }
                }
            }

            if cardViewModel.userCards.filter({ $0.isActive }).isEmpty {
                ContentUnavailableView(
                    "No Benefits",
                    systemImage: "gift",
                    description: Text("Add cards to track their benefits.")
                )
            }
        }
        .navigationTitle("Benefits")
    }

    @ViewBuilder
    private var summarySection: some View {
        Section {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Total Value")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text("$\(Int(totalBenefitValue))")
                        .font(.title.bold())
                        .foregroundStyle(.green)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 4) {
                    Text("Used")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text("$\(Int(totalUsed))")
                        .font(.title.bold())
                }
            }

            if totalBenefitValue > 0 {
                ProgressView(value: min(totalUsed / totalBenefitValue, 1.0))
                    .tint(.green)
                Text("\(Int(min(totalUsed / totalBenefitValue, 1.0) * 100))% of benefits utilized")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private func updateBenefitUsage(userCardId: UUID, benefitId: String, amount: Double, benefit: CardBenefit) {
        guard var userCard = cardViewModel.userCards.first(where: { $0.id == userCardId }) else { return }

        if let index = userCard.benefitUsage.firstIndex(where: { $0.benefitId == benefitId }) {
            userCard.benefitUsage[index].usedAmount = min(amount, benefit.value)
        } else {
            let nextReset = Calendar.current.date(byAdding: .year, value: 1, to: Date()) ?? Date()
            userCard.benefitUsage.append(
                BenefitUsage(benefitId: benefitId, usedAmount: min(amount, benefit.value), resetDate: nextReset)
            )
        }

        cardViewModel.updateCard(userCard)
    }
}

// MARK: - Benefit Row with Editing

struct BenefitEditableRow: View {
    let benefit: CardBenefit
    let usage: BenefitUsage?
    let isEditing: Bool
    @Binding var usageInput: String
    let onTapEdit: () -> Void
    let onSave: (Double) -> Void
    let onCancel: () -> Void

    private var usedAmount: Double {
        usage?.usedAmount ?? 0
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(benefit.name)
                        .font(.body)
                    Text(benefit.resetPeriod.displayName)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Text(benefit.formattedValue)
                    .font(.headline)
                    .foregroundStyle(.green)
            }

            if benefit.value > 0 {
                ProgressView(value: min(usedAmount / benefit.value, 1.0))
                    .tint(usedAmount >= benefit.value ? .green : .blue)

                if isEditing {
                    HStack {
                        Text("$")
                            .foregroundStyle(.secondary)
                        TextField("Amount used", text: $usageInput)
                            #if os(iOS)
                            .keyboardType(.decimalPad)
                            #endif
                            .textFieldStyle(.roundedBorder)

                        Text("/ \(benefit.formattedValue)")
                            .font(.caption)
                            .foregroundStyle(.secondary)

                        Button("Save") {
                            if let val = Double(usageInput) {
                                onSave(val)
                            }
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.small)

                        Button("Cancel", action: onCancel)
                            .controlSize(.small)
                    }
                } else {
                    HStack {
                        Text("$\(Int(usedAmount)) / \(benefit.formattedValue) used")
                            .font(.caption)
                            .foregroundStyle(.secondary)

                        Spacer()

                        Button {
                            onTapEdit()
                        } label: {
                            Label("Update", systemImage: "pencil")
                                .font(.caption)
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.mini)
                    }
                }

                if let usage, benefit.resetPeriod != .none {
                    Text("Resets \(usage.resetDate.relativeDescription)")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
            }
        }
        .padding(.vertical, 4)
    }
}
