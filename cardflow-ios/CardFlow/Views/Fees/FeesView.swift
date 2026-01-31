import SwiftUI

struct FeesView: View {
    @Environment(DataStore.self) private var store

    private var cardsWithFees: [CreditCard] {
        store.cards
            .filter { $0.annualFee > 0 }
            .sorted { (Formatters.daysUntil($0.anniversaryDate) ?? 999) < (Formatters.daysUntil($1.anniversaryDate) ?? 999) }
    }

    private var totalAnnualFees: Double {
        store.cards.reduce(0) { $0 + $1.annualFee }
    }

    private var nextUpcoming: CreditCard? {
        cardsWithFees.first { (Formatters.daysUntil($0.anniversaryDate) ?? 0) > 0 }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    // Summary Section
                    summarySection

                    // Cards List
                    if cardsWithFees.isEmpty {
                        emptyState
                    } else {
                        LazyVStack(spacing: 12) {
                            ForEach(cardsWithFees) { card in
                                FeeCardRow(card: card, store: store)
                            }
                        }
                    }
                }
                .padding()
            }
            .background(ColorTheme.background)
            .navigationTitle("Annual Fees")
        }
    }

    // MARK: - Summary

    private var summarySection: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Total Annual Fees")
                    .font(.caption)
                    .foregroundColor(ColorTheme.textSecondary)
                Text(Formatters.formatCurrency(totalAnnualFees))
                    .font(.title2.weight(.bold))
                    .foregroundColor(ColorTheme.gold)
                Text("\(cardsWithFees.count) card\(cardsWithFees.count == 1 ? "" : "s") with fees")
                    .font(.caption2)
                    .foregroundColor(ColorTheme.textMuted)
            }
            Spacer()
            if let next = nextUpcoming {
                VStack(alignment: .trailing, spacing: 4) {
                    Text("Next Fee")
                        .font(.caption)
                        .foregroundColor(ColorTheme.textSecondary)
                    Text("\(next.issuer) \(next.name)")
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(ColorTheme.textPrimary)
                        .lineLimit(1)
                    if let days = Formatters.daysUntil(next.anniversaryDate) {
                        Text("\(days) day\(days == 1 ? "" : "s")")
                            .font(.caption.weight(.medium))
                            .foregroundColor(days <= 30 ? ColorTheme.red : ColorTheme.gold)
                    }
                }
            }
        }
        .padding()
        .background(ColorTheme.cardBg)
        .cornerRadius(16)
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(ColorTheme.border, lineWidth: 1))
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "calendar.badge.checkmark")
                .font(.system(size: 48))
                .foregroundColor(ColorTheme.textMuted)
            Text("No Annual Fees")
                .font(.headline)
                .foregroundColor(ColorTheme.textSecondary)
            Text("Cards with annual fees will appear here")
                .font(.subheadline)
                .foregroundColor(ColorTheme.textMuted)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 60)
    }
}

// MARK: - Fee Card Row

struct FeeCardRow: View {
    let card: CreditCard
    let store: DataStore
    @State private var feeDecision: String
    @State private var retentionOffer: String
    @State private var showDowngrades = false

    init(card: CreditCard, store: DataStore) {
        self.card = card
        self.store = store
        _feeDecision = State(initialValue: card.feeDecision ?? "Undecided")
        _retentionOffer = State(initialValue: card.retentionOffer ?? "")
    }

    private var daysUntil: Int? {
        Formatters.daysUntil(card.anniversaryDate)
    }

    private var isUrgent: Bool {
        guard let days = daysUntil else { return false }
        return days >= 0 && days <= 30
    }

    private var downgradeOptions: [String] {
        DowngradePaths.options(for: "\(card.issuer) \(card.name)")
    }

    private let decisions = ["Undecided", "Keep", "Downgrade", "Cancel"]

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("\(card.issuer) \(card.name)")
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(ColorTheme.textPrimary)
                    Text(Formatters.formatDate(card.anniversaryDate))
                        .font(.caption)
                        .foregroundColor(ColorTheme.textMuted)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 2) {
                    Text(Formatters.formatCurrency(card.annualFee))
                        .font(.subheadline.weight(.bold))
                        .foregroundColor(ColorTheme.gold)
                    if let days = daysUntil {
                        Text(days > 0 ? "\(days) day\(days == 1 ? "" : "s")" : "Past due")
                            .font(.caption.weight(.medium))
                            .foregroundColor(isUrgent ? ColorTheme.red : ColorTheme.textMuted)
                    }
                }
            }

            // Urgent banner
            if isUrgent {
                HStack(spacing: 6) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.caption2)
                    Text("Action needed soon")
                        .font(.caption.weight(.medium))
                }
                .foregroundColor(ColorTheme.red)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(ColorTheme.red.opacity(0.1))
                .cornerRadius(8)
            }

            // Fee Decision Picker
            VStack(alignment: .leading, spacing: 4) {
                Text("Decision")
                    .font(.caption)
                    .foregroundColor(ColorTheme.textSecondary)

                Picker("Decision", selection: $feeDecision) {
                    ForEach(decisions, id: \.self) { Text($0) }
                }
                .pickerStyle(.segmented)
                .onChange(of: feeDecision) { _, newValue in
                    var updated = card
                    updated.feeDecision = newValue == "Undecided" ? nil : newValue
                    store.updateCard(updated)
                }
            }

            // Downgrade Suggestions
            if feeDecision == "Downgrade" && !downgradeOptions.isEmpty {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Downgrade Options")
                        .font(.caption.weight(.semibold))
                        .foregroundColor(ColorTheme.textSecondary)

                    FlowLayout(spacing: 6) {
                        ForEach(downgradeOptions, id: \.self) { option in
                            Text(option)
                                .font(.caption.weight(.medium))
                                .foregroundColor(ColorTheme.green)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 5)
                                .background(ColorTheme.green.opacity(0.12))
                                .cornerRadius(8)
                        }
                    }
                }
            }

            // Retention Offer
            VStack(alignment: .leading, spacing: 4) {
                Text("Retention Offer")
                    .font(.caption)
                    .foregroundColor(ColorTheme.textSecondary)

                TextField("e.g. 10k points or $50 credit", text: $retentionOffer)
                    .font(.caption)
                    .foregroundColor(ColorTheme.textPrimary)
                    .padding(8)
                    .background(ColorTheme.surfaceBg)
                    .cornerRadius(8)
                    .onSubmit {
                        var updated = card
                        updated.retentionOffer = retentionOffer.isEmpty ? nil : retentionOffer
                        store.updateCard(updated)
                    }
                    .onChange(of: retentionOffer) { _, newValue in
                        var updated = card
                        updated.retentionOffer = newValue.isEmpty ? nil : newValue
                        store.updateCard(updated)
                    }
            }
        }
        .padding()
        .background(ColorTheme.cardBg)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(isUrgent ? ColorTheme.red.opacity(0.5) : ColorTheme.border, lineWidth: isUrgent ? 1.5 : 1)
        )
    }
}

// MARK: - Flow Layout

struct FlowLayout: Layout {
    var spacing: CGFloat = 6

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = layout(proposal: proposal, subviews: subviews)
        return result.size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = layout(proposal: proposal, subviews: subviews)
        for (index, position) in result.positions.enumerated() {
            subviews[index].place(at: CGPoint(x: bounds.minX + position.x, y: bounds.minY + position.y), proposal: .unspecified)
        }
    }

    private func layout(proposal: ProposedViewSize, subviews: Subviews) -> (size: CGSize, positions: [CGPoint]) {
        let maxWidth = proposal.width ?? .infinity
        var positions: [CGPoint] = []
        var currentX: CGFloat = 0
        var currentY: CGFloat = 0
        var lineHeight: CGFloat = 0
        var maxX: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if currentX + size.width > maxWidth && currentX > 0 {
                currentX = 0
                currentY += lineHeight + spacing
                lineHeight = 0
            }
            positions.append(CGPoint(x: currentX, y: currentY))
            lineHeight = max(lineHeight, size.height)
            currentX += size.width + spacing
            maxX = max(maxX, currentX)
        }

        return (CGSize(width: maxX, height: currentY + lineHeight), positions)
    }
}
