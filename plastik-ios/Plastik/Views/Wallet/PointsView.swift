import SwiftUI

struct PointsView: View {
    @Environment(CardViewModel.self) private var cardViewModel
    @Environment(DataFeedService.self) private var feedService

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Points Programs Overview
                programsSection

                // Transfer Partner Quick Access
                transferPartnerQuickAccess

                // Companion Pass Tracker
                companionPassSection

                // Points Strategy Tips
                strategySection
            }
            .padding(24)
            .frame(maxWidth: 1200)
            .frame(maxWidth: .infinity)
        }
        .navigationTitle("Points & Programs")
    }

    // MARK: - Points Programs

    @ViewBuilder
    private var programsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Your Points Programs")
                .font(.system(size: 17, weight: .semibold))

            if pointsPrograms.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "star.fill")
                        .font(.system(size: 32))
                        .foregroundStyle(.tertiary)
                    Text("No active points programs yet")
                        .font(.system(size: 15))
                        .foregroundStyle(.secondary)
                    Text("Add cards to see which points currencies you're earning.")
                        .font(.system(size: 13))
                        .foregroundStyle(.tertiary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 24)
            } else {
                VStack(spacing: 0) {
                    ForEach(pointsPrograms, id: \.currency) { program in
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(program.currency)
                                        .font(.system(size: 15, weight: .semibold))
                                    Text(program.issuer)
                                        .font(.system(size: 13))
                                        .foregroundStyle(.secondary)
                                }
                                Spacer()
                                VStack(alignment: .trailing, spacing: 2) {
                                    Text("\(program.cardCount) card\(program.cardCount == 1 ? "" : "s")")
                                        .font(.system(size: 13))
                                        .foregroundStyle(.secondary)
                                    Text("\(program.partnerCount) transfer partners")
                                        .font(.system(size: 12))
                                        .foregroundStyle(.blue)
                                }
                            }

                            // Cards in this program
                            HStack(spacing: 8) {
                                ForEach(program.cards, id: \.cardId) { userCard in
                                    let card = feedService.card(for: userCard.cardId)
                                    Text(userCard.nickname ?? card?.name ?? "Card")
                                        .font(.system(size: 11))
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 4)
                                        .background(.ultraThinMaterial)
                                        .clipShape(RoundedRectangle(cornerRadius: 4))
                                }
                            }

                            if program.hasPoolablePoints {
                                HStack(spacing: 4) {
                                    Image(systemName: "arrow.triangle.merge")
                                        .font(.system(size: 10))
                                        .foregroundStyle(.green)
                                    Text("Points can be pooled across these cards")
                                        .font(.system(size: 11))
                                        .foregroundStyle(.green)
                                }
                            }
                        }
                        .padding(16)

                        if program.currency != pointsPrograms.last?.currency {
                            Divider().padding(.leading, 16)
                        }
                    }
                }
                .background(cardBackground)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
        }
    }

    // MARK: - Transfer Partner Quick Access

    @ViewBuilder
    private var transferPartnerQuickAccess: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Transfer Partners")
                    .font(.system(size: 17, weight: .semibold))
                Spacer()
                NavigationLink {
                    TransferPartnerMapView()
                } label: {
                    HStack(spacing: 4) {
                        Text("Full Map")
                            .font(.system(size: 14))
                        Image(systemName: "chevron.right")
                            .font(.system(size: 12))
                    }
                }
            }

            if !availablePartners.isEmpty {
                Text("Based on your cards, you can transfer to \(availablePartners.count) loyalty programs:")
                    .font(.system(size: 13))
                    .foregroundStyle(.secondary)

                LazyVGrid(columns: [GridItem(.adaptive(minimum: 140))], spacing: 8) {
                    ForEach(availablePartners.prefix(12)) { partner in
                        NavigationLink {
                            TransferPartnerDetailView(partner: partner)
                        } label: {
                            HStack(spacing: 6) {
                                Image(systemName: partner.type.icon)
                                    .font(.caption)
                                    .foregroundStyle(.blue)
                                Text(partner.name)
                                    .font(.system(size: 12))
                                    .foregroundStyle(.primary)
                                    .lineLimit(1)
                                Spacer()
                            }
                            .padding(.horizontal, 10)
                            .padding(.vertical, 8)
                            .background(.ultraThinMaterial)
                            .clipShape(RoundedRectangle(cornerRadius: 6))
                        }
                        .buttonStyle(.plain)
                    }
                }
            } else {
                Text("Add cards to see available transfer partners.")
                    .font(.system(size: 13))
                    .foregroundStyle(.tertiary)
            }
        }
    }

    // MARK: - Companion Pass Section

    @ViewBuilder
    private var companionPassSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "person.2.fill")
                    .foregroundStyle(.orange)
                Text("Southwest Companion Pass")
                    .font(.system(size: 17, weight: .semibold))
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("Earn 135,000 qualifying points in a calendar year to unlock free travel for a companion on all Southwest flights through the end of the following year.")
                    .font(.system(size: 13))
                    .foregroundStyle(.secondary)

                let swCards = southwestCards
                if swCards.isEmpty {
                    HStack(spacing: 8) {
                        Image(systemName: "info.circle")
                            .foregroundStyle(.blue)
                        Text("You don't currently have any Southwest cards. A Southwest card signup bonus is the fastest path to the Companion Pass.")
                            .font(.system(size: 13))
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 4)
                } else {
                    Text("Your Southwest Cards")
                        .font(.system(size: 14, weight: .medium))
                        .padding(.top, 4)

                    ForEach(swCards) { userCard in
                        if let card = feedService.card(for: userCard.cardId) {
                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(userCard.nickname ?? card.name)
                                        .font(.system(size: 14))
                                    Text("Opened: \(userCard.openDate.shortFormatted)")
                                        .font(.system(size: 12))
                                        .foregroundStyle(.secondary)
                                }
                                Spacer()
                                if let bonus = userCard.signupBonusProgress {
                                    if bonus.completed {
                                        Label("Bonus Earned", systemImage: "checkmark.circle.fill")
                                            .font(.system(size: 12))
                                            .foregroundStyle(.green)
                                    } else {
                                        Text("\(bonus.daysRemaining)d left")
                                            .font(.system(size: 12))
                                            .foregroundStyle(.orange)
                                    }
                                }
                            }
                        }
                    }

                    // How to earn tips
                    Divider().padding(.vertical, 4)
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Ways to Earn Qualifying Points")
                            .font(.system(size: 13, weight: .medium))
                        earnTip("creditcard.fill", "Southwest card signup bonuses (50K-75K points)")
                        earnTip("cart.fill", "Everyday spending on Southwest cards")
                        earnTip("airplane", "Flying Southwest (points earned count)")
                        earnTip("arrow.triangle.swap", "Transfer from Chase UR or Marriott (limited)")
                    }
                }
            }
            .padding(16)
            .background(cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }

    @ViewBuilder
    private func earnTip(_ icon: String, _ text: String) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 10))
                .foregroundStyle(.orange)
                .frame(width: 16)
                .padding(.top, 2)
            Text(text)
                .font(.system(size: 12))
                .foregroundStyle(.secondary)
        }
    }

    // MARK: - Strategy Tips

    @ViewBuilder
    private var strategySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Points Strategy Tips")
                .font(.system(size: 17, weight: .semibold))

            VStack(spacing: 0) {
                tipRow(
                    icon: "arrow.triangle.swap",
                    title: "Transfer for outsized value",
                    detail: "Credit card points are often worth 1.5-3x more when transferred to airline/hotel partners vs. statement credits."
                )
                Divider().padding(.leading, 44)
                tipRow(
                    icon: "clock.arrow.circlepath",
                    title: "Don't let points expire",
                    detail: "Most programs keep points alive with any earning or redemption activity. Set a calendar reminder to earn at least 1 point per year."
                )
                Divider().padding(.leading, 44)
                tipRow(
                    icon: "creditcard.and.123",
                    title: "Pool points strategically",
                    detail: "Chase UR and Citi TYP let you pool points across cards. Having a premium card (Sapphire Reserve, Citi Strata) unlocks the best transfer rates."
                )
            }
            .padding(16)
            .background(cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }

    @ViewBuilder
    private func tipRow(icon: String, title: String, detail: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundStyle(.blue)
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 14, weight: .medium))
                Text(detail)
                    .font(.system(size: 13))
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 8)
    }

    // MARK: - Computed Properties

    private var cardBackground: some ShapeStyle {
        #if os(macOS)
        Color(nsColor: .controlBackgroundColor)
        #else
        Color(uiColor: .secondarySystemGroupedBackground)
        #endif
    }

    private var southwestCards: [UserCard] {
        cardViewModel.activeCards.filter { userCard in
            guard let card = feedService.card(for: userCard.cardId) else { return false }
            return card.name.lowercased().contains("southwest")
        }
    }

    private var availablePartners: [TransferPartner] {
        // Get partners accessible through user's card programs
        let userCardIds = Set(cardViewModel.activeCards.map(\.cardId))
        let userIssuers = Set(feedService.cards.filter { userCardIds.contains($0.id) }.map(\.issuer))

        // Map issuers to points currencies
        var currencyIds: Set<String> = []
        for issuer in userIssuers {
            switch issuer {
            case .chase: currencyIds.insert("chase-ur")
            case .amex: currencyIds.insert("amex-mr")
            case .citi: currencyIds.insert("citi-typ")
            case .capitalOne: currencyIds.insert("capital-one")
            default: break
            }
        }

        // Find partners reachable from these currencies
        let reachablePartnerIds = Set(
            feedService.transferRoutes
                .filter { currencyIds.contains($0.fromCurrency) }
                .map(\.toPartner)
        )

        return feedService.transferPartners.filter { reachablePartnerIds.contains($0.id) }
    }

    private struct PointsProgram {
        let currency: String
        let issuer: String
        let cards: [UserCard]
        let cardCount: Int
        let partnerCount: Int
        let hasPoolablePoints: Bool
    }

    private var pointsPrograms: [PointsProgram] {
        let userCardIds = Set(cardViewModel.activeCards.map(\.cardId))
        let userCards = feedService.cards.filter { userCardIds.contains($0.id) }

        var programs: [String: (issuer: String, cards: [UserCard], poolable: Bool)] = [:]

        for card in userCards {
            let key: String
            let label: String
            let poolable: Bool

            switch card.issuer {
            case .chase:
                key = "chase-ur"; label = "Chase"; poolable = true
            case .amex:
                key = "amex-mr"; label = "American Express"; poolable = true
            case .citi:
                key = "citi-typ"; label = "Citi"; poolable = true
            case .capitalOne:
                key = "capital-one"; label = "Capital One"; poolable = true
            default:
                continue
            }

            let userCard = cardViewModel.activeCards.first { $0.cardId == card.id }
            if let uc = userCard {
                var existing = programs[key] ?? (label, [], poolable)
                existing.cards.append(uc)
                programs[key] = existing
            }
        }

        return programs.map { (key, value) in
            let partnerCount = feedService.transferRoutes.filter { $0.fromCurrency == key }.count
            return PointsProgram(
                currency: currencyDisplayName(key),
                issuer: value.issuer,
                cards: value.cards,
                cardCount: value.cards.count,
                partnerCount: partnerCount,
                hasPoolablePoints: value.poolable && value.cards.count > 1
            )
        }.sorted { $0.cardCount > $1.cardCount }
    }

    private func currencyDisplayName(_ id: String) -> String {
        switch id {
        case "chase-ur": return "Ultimate Rewards"
        case "amex-mr": return "Membership Rewards"
        case "citi-typ": return "ThankYou Points"
        case "capital-one": return "Capital One Miles"
        default: return id
        }
    }
}

#Preview {
    NavigationStack {
        PointsView()
    }
    .environment(CardViewModel())
    .environment(DataFeedService())
}
