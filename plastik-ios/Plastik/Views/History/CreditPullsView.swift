import SwiftUI

struct CreditPullsView: View {
    @Environment(CardViewModel.self) private var cardViewModel
    @Environment(DataFeedService.self) private var feedService
    @State private var selectedBureau: CreditBureau = .all

    enum CreditBureau: String, CaseIterable {
        case all = "All"
        case experian = "Experian"
        case equifax = "Equifax"
        case transUnion = "TransUnion"
    }

    var body: some View {
        List {
            Section {
                Picker("Filter by Bureau", selection: $selectedBureau) {
                    ForEach(CreditBureau.allCases, id: \.self) { bureau in
                        Text(bureau.rawValue).tag(bureau)
                    }
                }
                .pickerStyle(.segmented)
            }

            Section("Pull Summary") {
                HStack {
                    PullSummaryCard(
                        bureau: "Experian",
                        count: pullCount(for: .experian),
                        color: .blue
                    )
                    PullSummaryCard(
                        bureau: "Equifax",
                        count: pullCount(for: .equifax),
                        color: .red
                    )
                    PullSummaryCard(
                        bureau: "TransUnion",
                        count: pullCount(for: .transUnion),
                        color: .green
                    )
                }
            }

            Section("Recent Inquiries") {
                if filteredPulls.isEmpty {
                    ContentUnavailableView(
                        "No Credit Pulls Tracked",
                        systemImage: "magnifyingglass",
                        description: Text("Credit pulls are estimated based on your card applications.")
                    )
                } else {
                    ForEach(filteredPulls, id: \.date) { pull in
                        CreditPullRow(pull: pull)
                    }
                }
            }

            Section("How Inquiries Work") {
                VStack(alignment: .leading, spacing: 12) {
                    InfoRow(
                        title: "Hard vs Soft Pulls",
                        detail: "Hard inquiries (from applications) affect your score. Soft pulls (from pre-approvals) don't."
                    )

                    InfoRow(
                        title: "Impact Duration",
                        detail: "Hard inquiries affect your score for 12 months and remain on your report for 2 years."
                    )

                    InfoRow(
                        title: "Rate Shopping",
                        detail: "Multiple inquiries for mortgages, auto loans, or student loans within 14-45 days count as one."
                    )
                }
            }

            Section("Issuer Patterns") {
                IssuerPullRow(issuer: "Chase", bureaus: "Experian (most states)")
                IssuerPullRow(issuer: "American Express", bureaus: "Experian")
                IssuerPullRow(issuer: "Citi", bureaus: "Experian, Equifax")
                IssuerPullRow(issuer: "Capital One", bureaus: "All three bureaus")
                IssuerPullRow(issuer: "Barclays", bureaus: "TransUnion")
            }
        }
        .navigationTitle("Credit Pulls")
    }

    private func pullCount(for bureau: CreditBureau) -> Int {
        let cutoff = Calendar.current.date(byAdding: .year, value: -2, to: Date()) ?? Date()
        let recentCards = cardViewModel.userCards.filter { $0.openDate > cutoff }

        switch bureau {
        case .all:
            return recentCards.count
        case .experian:
            return recentCards.filter { userCard in
                guard let card = feedService.card(for: userCard.cardId) else { return false }
                return [Issuer.chase, .amex, .citi].contains(card.issuer)
            }.count
        case .equifax:
            return recentCards.filter { userCard in
                guard let card = feedService.card(for: userCard.cardId) else { return false }
                return [Issuer.citi, .capitalOne].contains(card.issuer)
            }.count
        case .transUnion:
            return recentCards.filter { userCard in
                guard let card = feedService.card(for: userCard.cardId) else { return false }
                return [Issuer.barclays, .capitalOne, .discover].contains(card.issuer)
            }.count
        }
    }

    private var filteredPulls: [(cardName: String, issuer: String, bureau: String, date: Date)] {
        let cutoff = Calendar.current.date(byAdding: .year, value: -2, to: Date()) ?? Date()

        return cardViewModel.userCards
            .filter { $0.openDate > cutoff }
            .sorted { $0.openDate > $1.openDate }
            .compactMap { userCard in
                guard let card = feedService.card(for: userCard.cardId) else { return nil }
                let bureau = estimatedBureau(for: card.issuer)

                if selectedBureau != .all && !bureau.lowercased().contains(selectedBureau.rawValue.lowercased()) {
                    return nil
                }

                return (
                    cardName: userCard.nickname ?? card.name,
                    issuer: card.issuer.displayName,
                    bureau: bureau,
                    date: userCard.openDate
                )
            }
    }

    private func estimatedBureau(for issuer: Issuer) -> String {
        switch issuer {
        case .chase: return "Experian"
        case .amex: return "Experian"
        case .citi: return "Experian, Equifax"
        case .capitalOne: return "All three"
        case .barclays: return "TransUnion"
        case .usBank: return "Experian, TransUnion"
        case .wellsFargo: return "Experian"
        case .bankOfAmerica: return "Experian, TransUnion"
        case .discover: return "TransUnion, Experian"
        }
    }
}

struct PullSummaryCard: View {
    let bureau: String
    let count: Int
    let color: Color

    var body: some View {
        VStack(spacing: 4) {
            Text("\(count)")
                .font(.title2.bold())
                .foregroundStyle(color)
            Text(bureau)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(color.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

struct CreditPullRow: View {
    let pull: (cardName: String, issuer: String, bureau: String, date: Date)

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(pull.cardName)
                    .font(.subheadline)
                Text(pull.issuer)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Text(pull.bureau)
                    .font(.caption)
                    .foregroundStyle(.blue)
                Text(pull.date.shortFormatted)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 2)
    }
}

struct InfoRow: View {
    let title: String
    let detail: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.subheadline.bold())
            Text(detail)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}

struct IssuerPullRow: View {
    let issuer: String
    let bureaus: String

    var body: some View {
        HStack {
            Text(issuer)
                .font(.subheadline)
            Spacer()
            Text(bureaus)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}

#Preview {
    NavigationStack {
        CreditPullsView()
    }
    .environment(CardViewModel())
    .environment(DataFeedService())
}
