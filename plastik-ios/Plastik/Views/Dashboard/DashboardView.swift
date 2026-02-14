import SwiftUI

struct DashboardView: View {
    @Environment(CardViewModel.self) private var cardViewModel
    @Environment(DataFeedService.self) private var feedService

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                welcomeSection
                statsSection
                whichCardSection
                transferPartnersSection
                myCardsSection
                upcomingActionsSection
            }
            .padding()
        }
        .navigationTitle("Dashboard")
    }

    // MARK: - Welcome Section (Section 7.2: Updated text)

    @ViewBuilder
    private var welcomeSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Welcome back!")
                .font(.system(size: 24, weight: .semibold))
            Text("Here's your card summary.") // Section 7.2: Removed "optimization"
                .font(.system(size: 15))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Stats Section (Section 6: Interactive)

    @ViewBuilder
    private var statsSection: some View {
        #if os(iOS)
        // iOS: 2x2 grid on smaller screens
        LazyVGrid(columns: [
            GridItem(.flexible()),
            GridItem(.flexible())
        ], spacing: 12) {
            statsContent
        }
        #else
        // macOS: 4 columns
        LazyVGrid(columns: [
            GridItem(.flexible()),
            GridItem(.flexible()),
            GridItem(.flexible()),
            GridItem(.flexible())
        ], spacing: 12) {
            statsContent
        }
        #endif
    }

    @ViewBuilder
    private var statsContent: some View {
        // Section 6: Clickable stat cards with navigation
        NavigationLink {
            CardListView()
        } label: {
            InteractiveStatCard(
                value: "\(cardViewModel.activeCards.count)",
                label: "Active Cards",
                color: .blue
            )
        }
        .buttonStyle(.plain)

        NavigationLink {
            CardListView() // Shows closed cards too
        } label: {
            InteractiveStatCard(
                value: "\(cardViewModel.closedCards.count)",
                label: "Closed",
                color: .gray
            )
        }
        .buttonStyle(.plain)

        InteractiveStatCard(
            value: "\(cardViewModel.fiveOverTwentyFourCount)/5",
            label: "5/24 Status",
            color: cardViewModel.fiveOverTwentyFourCount >= 5 ? .red : .orange
        )

        NavigationLink {
            TransferPartnerMapView()
        } label: {
            InteractiveStatCard(
                value: totalPointsFormatted,
                label: "Total Points",
                color: .purple
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Which Card Section

    @ViewBuilder
    private var whichCardSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Which Card Should I Use?")
                .font(.system(size: 17, weight: .semibold))

            let categories: [SpendCategory] = [.dining, .groceries, .gas, .travel]

            if cardViewModel.activeCards.isEmpty {
                Text("Add cards to see recommendations")
                    .font(.system(size: 15))
                    .foregroundStyle(.secondary)
                    .padding(.vertical, 8)
            } else {
                VStack(spacing: 8) {
                    ForEach(categories) { category in
                        if let (userCard, creditCard, rate) = bestCardForCategory(category) {
                            // Section 6: Clickable rows navigate to card detail
                            NavigationLink {
                                CardDetailView(userCard: userCard)
                            } label: {
                                HStack {
                                    Image(systemName: category.icon)
                                        .font(.system(size: 16))
                                        .foregroundStyle(.blue)
                                        .frame(width: 24)

                                    Text(category.displayName)
                                        .font(.system(size: 15))
                                        .foregroundStyle(.primary)
                                        .frame(width: 80, alignment: .leading)

                                    Text(userCard.nickname ?? creditCard.name)
                                        .font(.system(size: 15))
                                        .foregroundStyle(.secondary)
                                        .lineLimit(1)

                                    Spacer()

                                    Text(rate.multiplierFormatted)
                                        .font(.system(size: 15, weight: .bold))
                                        .foregroundStyle(.green)

                                    Image(systemName: "chevron.right")
                                        .font(.system(size: 12, weight: .semibold))
                                        .foregroundStyle(.tertiary)
                                }
                                .padding(.horizontal, 16)
                                .frame(minHeight: 52)
                                #if os(iOS)
                                .background(Color(.tertiarySystemBackground))
                                #else
                                .background(Color(nsColor: .controlBackgroundColor))
                                #endif
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
        }
        .padding(16)
        #if os(iOS)
        .background(Color(.secondarySystemBackground))
        #else
        .background(Color(nsColor: .windowBackgroundColor))
        #endif
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    // MARK: - Transfer Partners Section (Section 6: Interactive)

    @ViewBuilder
    private var transferPartnersSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Transfer Partners")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(.primary)
                Spacer()
                NavigationLink {
                    TransferPartnerMapView()
                } label: {
                    HStack(spacing: 4) {
                        Text("View All")
                            .font(.system(size: 14))
                        Image(systemName: "chevron.right")
                            .font(.system(size: 12))
                    }
                }
            }

            HStack {
                Text("\(airlinePartners) Airlines")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(.green)
                Text("·")
                    .foregroundStyle(.secondary)
                Text("\(hotelPartners) Hotels")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(.green)
                Spacer()
                Text("\(totalPointsFormatted) points")
                    .font(.system(size: 13))
                    .foregroundStyle(.secondary)
            }

            #if os(macOS)
            // macOS: show full partner names, clickable to detail pages
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 8) {
                ForEach(feedService.transferPartners.prefix(6)) { partner in
                    NavigationLink {
                        TransferPartnerDetailView(partner: partner)
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: partner.type.icon)
                                .font(.system(size: 11))
                                .foregroundStyle(.blue)
                            Text(partner.name)
                                .font(.system(size: 12, weight: .medium))
                                .foregroundStyle(.primary)
                                .lineLimit(1)
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.system(size: 9))
                                .foregroundStyle(.tertiary)
                        }
                        .padding(.horizontal, 10)
                        .frame(minHeight: 40)
                        .background(Color(nsColor: .controlBackgroundColor))
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                    }
                    .buttonStyle(.plain)
                }
            }
            #else
            // iOS: compact tiles
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 8) {
                ForEach(feedService.transferPartners.prefix(6)) { partner in
                    NavigationLink {
                        TransferPartnerDetailView(partner: partner)
                    } label: {
                        VStack(spacing: 2) {
                            Image(systemName: partner.type.icon)
                                .font(.system(size: 12))
                                .foregroundStyle(.blue)
                            Text(partner.name)
                                .font(.system(size: 10, weight: .medium))
                                .foregroundStyle(.primary)
                                .lineLimit(1)
                                .minimumScaleFactor(0.7)
                        }
                        .frame(maxWidth: .infinity)
                        .frame(minHeight: 40)
                        .background(Color(.tertiarySystemBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                    }
                    .buttonStyle(.plain)
                }
            }
            #endif
        }
        .padding(16)
        #if os(iOS)
        .background(Color(.secondarySystemBackground))
        #else
        .background(Color(nsColor: .windowBackgroundColor))
        #endif
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    // MARK: - My Cards Section (Section 6: Interactive)

    @ViewBuilder
    private var myCardsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("My Cards")
                    .font(.system(size: 17, weight: .semibold))
                Spacer()
                NavigationLink {
                    CardListView()
                } label: {
                    HStack(spacing: 4) {
                        Text("View All")
                            .font(.system(size: 14))
                        Image(systemName: "chevron.right")
                            .font(.system(size: 12))
                    }
                }
            }

            if cardViewModel.activeCards.isEmpty {
                Text("No active cards")
                    .font(.system(size: 15))
                    .foregroundStyle(.secondary)
                    .padding(.vertical, 8)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 16) {
                        // Show all cards - let horizontal scroll handle overflow
                        ForEach(cardViewModel.activeCards) { userCard in
                            let card = feedService.card(for: userCard.cardId)
                            // Section 6: Clickable cards navigate to card detail
                            NavigationLink {
                                CardDetailView(userCard: userCard)
                            } label: {
                                MiniCardView(userCard: userCard, card: card)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
        }
    }

    // MARK: - Upcoming Actions Section (Section 6: Interactive)

    @ViewBuilder
    private var upcomingActionsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Upcoming Actions")
                .font(.system(size: 17, weight: .semibold))

            if upcomingActions.isEmpty {
                Text("No upcoming actions")
                    .font(.system(size: 15))
                    .foregroundStyle(.secondary)
                    .padding(.vertical, 8)
            } else {
                HStack(spacing: 20) {
                    ForEach(upcomingActions.prefix(4), id: \.title) { action in
                        // Section 6: Clickable action items
                        if let userCard = action.userCard {
                            NavigationLink {
                                CardDetailView(userCard: userCard)
                            } label: {
                                ActionItem(action: action)
                            }
                            .buttonStyle(.plain)
                        } else {
                            ActionItem(action: action)
                        }
                    }
                }
            }
        }
        .padding(16)
        #if os(iOS)
        .background(Color(.secondarySystemBackground))
        #else
        .background(Color(nsColor: .windowBackgroundColor))
        #endif
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    // MARK: - Computed Properties

    private var totalPointsFormatted: String {
        // Placeholder - would aggregate from user cards
        "157k"
    }

    private var airlinePartners: Int {
        feedService.transferPartners.filter { $0.type == .airline }.count
    }

    private var hotelPartners: Int {
        feedService.transferPartners.filter { $0.type == .hotel }.count
    }

    private func bestCardForCategory(_ category: SpendCategory) -> (userCard: UserCard, creditCard: CreditCard, rate: Double)? {
        var best: (UserCard, CreditCard, Double)?

        for userCard in cardViewModel.activeCards {
            guard let creditCard = feedService.card(for: userCard.cardId) else { continue }
            let rate = creditCard.earningRates.first { $0.category == category }?.multiplier
                ?? creditCard.earningRates.first { $0.category == .other }?.multiplier
                ?? 1.0

            if let current = best {
                if rate > current.2 {
                    best = (userCard, creditCard, rate)
                }
            } else {
                best = (userCard, creditCard, rate)
            }
        }

        return best
    }

    private var upcomingActions: [(date: String, title: String, color: Color, userCard: UserCard?)] {
        // Generate real upcoming actions from user cards
        var actions: [(date: String, title: String, color: Color, userCard: UserCard?)] = []

        // Add annual fee dates
        for userCard in cardViewModel.activeCards {
            if let feeDate = userCard.annualFeeDate, feeDate > Date() {
                let card = feedService.card(for: userCard.cardId)
                let name = userCard.nickname ?? card?.name ?? "Card"
                actions.append((feeDate.shortFormatted, "\(name) Fee", .red, userCard))
            }
        }

        // Add bonus deadlines
        for userCard in cardViewModel.cardsWithActiveBonus {
            if let bonus = userCard.signupBonusProgress, !bonus.completed && !bonus.isExpired {
                let card = feedService.card(for: userCard.cardId)
                let name = userCard.nickname ?? card?.name ?? "Card"
                actions.append((bonus.deadline.shortFormatted, "\(name) Bonus", .orange, userCard))
            }
        }

        // Sort by date and take first 4
        return Array(actions.sorted { $0.date < $1.date }.prefix(4))
    }
}

// MARK: - Action Item View

private struct ActionItem: View {
    let action: (date: String, title: String, color: Color, userCard: UserCard?)

    var body: some View {
        VStack(spacing: 8) {
            Circle()
                .fill(action.color)
                .frame(width: 12, height: 12)
            Text(action.date)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(.primary)
            Text(action.title)
                .font(.system(size: 12))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .lineLimit(2)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Interactive Stat Card (Section 6 + Section 7.1)

struct InteractiveStatCard: View {
    let value: String
    let label: String
    let color: Color
    @State private var isHovered = false

    var body: some View {
        VStack(spacing: 4) {
            // Section 7.1: Dynamic font sizing to prevent overflow
            Text(value)
                .font(.system(size: dynamicFontSize, weight: .bold))
                .foregroundStyle(color)
                .lineLimit(1)
                .minimumScaleFactor(0.5) // Allow text to shrink if needed
            Text(label)
                .font(.system(size: 13))
                .foregroundStyle(.secondary)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
        .padding(.horizontal, 12)
        #if os(iOS)
        .background(Color(.secondarySystemBackground))
        #else
        .background(isHovered ? Color(nsColor: .selectedControlColor).opacity(0.1) : Color(nsColor: .controlBackgroundColor))
        .onHover { hovering in
            withAnimation(.easeOut(duration: 0.15)) {
                isHovered = hovering
            }
        }
        .scaleEffect(isHovered ? 1.02 : 1.0)
        #endif
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .animation(.easeOut(duration: 0.15), value: isHovered)
    }

    // Section 7.1: Dynamic font size based on value length
    private var dynamicFontSize: CGFloat {
        let length = value.count
        if length <= 3 {
            return 34
        } else if length <= 5 {
            return 28
        } else if length <= 7 {
            return 22
        } else {
            return 18
        }
    }
}

// Keep StatCard for backwards compatibility
struct StatCard: View {
    let value: String
    let label: String
    let color: Color

    var body: some View {
        InteractiveStatCard(value: value, label: label, color: color)
    }
}

// MARK: - Mini Card View

struct MiniCardView: View {
    let userCard: UserCard
    let card: CreditCard?
    @State private var isHovered = false

    /// Determines if the card background is light (needs dark text)
    private var isLightBackground: Bool {
        guard let firstColor = cardGradientColors.first else { return false }
        return firstColor.isLight
    }

    /// Primary text color based on background
    private var textColor: Color {
        isLightBackground ? .black : .white
    }

    /// Secondary text color based on background
    private var secondaryTextColor: Color {
        isLightBackground ? .black.opacity(0.7) : .white.opacity(0.8)
    }

    /// Tertiary text color based on background
    private var tertiaryTextColor: Color {
        isLightBackground ? .black.opacity(0.6) : .white.opacity(0.7)
    }

    /// Returns the effective annual fee (user override or catalog value)
    private var effectiveAnnualFee: Int {
        userCard.annualFeeOverride ?? card?.annualFee ?? 0
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            // Issuer abbreviation top left
            Text(card?.issuer.abbreviation ?? "CUST")
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(secondaryTextColor)

            Spacer()

            // Card name bottom left
            Text(userCard.nickname ?? card?.name ?? "Custom Card")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(textColor)
                .lineLimit(2)

            // Annual fee bottom right
            if effectiveAnnualFee > 0 {
                Text(effectiveAnnualFee.currencyFormatted + "/yr")
                    .font(.system(size: 11))
                    .foregroundStyle(tertiaryTextColor)
            } else {
                Text("No AF")
                    .font(.system(size: 11))
                    .foregroundStyle(tertiaryTextColor)
            }
        }
        .frame(width: 160, height: 100, alignment: .topLeading)
        .padding(8)
        .background(
            LinearGradient(
                colors: cardGradientColors,
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.2), radius: 8, x: 0, y: 4)
        #if os(macOS)
        .scaleEffect(isHovered ? 1.05 : 1.0)
        .onHover { hovering in
            withAnimation(.easeOut(duration: 0.15)) {
                isHovered = hovering
            }
        }
        #endif
    }

    private var cardGradientColors: [Color] {
        // User's custom icon color takes priority
        if let hex = userCard.cardIconColor, !hex.isEmpty {
            return [Color(hex: hex), Color(hex: hex).opacity(0.7)]
        }
        return card.map { dashboardCardGradient(for: $0.issuer, cardName: $0.name) } ?? [Color(hex: "6B7280"), Color(hex: "4B5563")]
    }
}

// MARK: - Dashboard Card Gradient (Updated for 25+ issuers)

private func dashboardCardGradient(for issuer: Issuer, cardName: String) -> [Color] {
    let nameLower = cardName.lowercased()

    switch issuer {
    // TIER 1: Major Issuers
    case .chase:
        if nameLower.contains("sapphire") {
            return [Color(hex: "004879"), Color(hex: "1a6bb3")]
        } else if nameLower.contains("ink") {
            return [Color(hex: "1a1a2e"), Color(hex: "16213e")]
        } else if nameLower.contains("freedom") {
            return [Color(hex: "1a5276"), Color(hex: "2874a6")]
        } else if nameLower.contains("united") {
            return [Color(hex: "003366"), Color(hex: "0055A5")]
        } else if nameLower.contains("southwest") {
            return [Color(hex: "CC0000"), Color(hex: "990000")]
        } else {
            return [Color(hex: "2c3e50"), Color(hex: "4a6074")]
        }

    case .amex:
        if nameLower.contains("gold") {
            return [Color(hex: "B4975A"), Color(hex: "CFB53B")]
        } else if nameLower.contains("platinum") {
            return [Color(hex: "A9A9A9"), Color(hex: "E8E8E8")]
        } else if nameLower.contains("green") {
            return [Color(hex: "1B5E3C"), Color(hex: "2E8B57")]
        } else if nameLower.contains("centurion") || nameLower.contains("black") {
            return [Color(hex: "1a1a1a"), Color(hex: "333333")]
        } else {
            return [Color(hex: "006FCF"), Color(hex: "00A1E4")]
        }

    case .citi:
        if nameLower.contains("double cash") {
            return [Color(hex: "2F4F4F"), Color(hex: "4a6b6b")]
        } else {
            return [Color(hex: "003B70"), Color(hex: "0066b2")]
        }

    case .capitalOne:
        if nameLower.contains("venture x") {
            return [Color(hex: "1a1a1a"), Color(hex: "333333")]
        } else if nameLower.contains("quicksilver") {
            return [Color(hex: "004977"), Color(hex: "00325a")]
        } else {
            return [Color(hex: "D03027"), Color(hex: "a02620")]
        }

    case .bankOfAmerica:
        return [Color(hex: "E31837"), Color(hex: "a31228")]

    case .wellsFargo:
        return [Color(hex: "CD1409"), Color(hex: "9a0f07")]

    case .usBank:
        return [Color(hex: "D71E28"), Color(hex: "a3171e")]

    case .barclays:
        return [Color(hex: "00AEEF"), Color(hex: "0088cc")]

    case .discover:
        return [Color(hex: "FF6600"), Color(hex: "ff8533")]

    // TIER 2: Mid-Market & Specialty Issuers
    case .usaa:
        return [Color(hex: "003366"), Color(hex: "00508F")]

    case .navyFederal:
        return [Color(hex: "003087"), Color(hex: "0050AA")]

    case .pnc:
        return [Color(hex: "FF6600"), Color(hex: "CC5200")]

    case .tdBank:
        return [Color(hex: "00843D"), Color(hex: "006B32")]

    case .synchrony:
        return [Color(hex: "0073CF"), Color(hex: "0055A5")]

    case .breadFinancial:
        return [Color(hex: "E35205"), Color(hex: "B84104")]

    case .goldmanSachs:
        return [Color(hex: "6CA0DC"), Color(hex: "4A90D9")]

    case .fnbo:
        return [Color(hex: "004B8D"), Color(hex: "003866")]

    case .creditOne:
        return [Color(hex: "002855"), Color(hex: "001A3A")]

    case .upgrade:
        return [Color(hex: "00D4AA"), Color(hex: "00B894")]

    case .avant:
        return [Color(hex: "4CAF50"), Color(hex: "388E3C")]

    // TIER 3: Tech & Fintech Issuers
    case .apple:
        return [Color(hex: "E8E8ED"), Color(hex: "F5F5F7")]

    case .brex:
        return [Color(hex: "FF5722"), Color(hex: "E64A19")]

    case .ramp:
        return [Color(hex: "FFD700"), Color(hex: "FFC107")]

    case .mercury:
        return [Color(hex: "5C6BC0"), Color(hex: "3F51B5")]

    // Special Category
    case .custom:
        return [Color(hex: "6B7280"), Color(hex: "4B5563")]
    }
}

// Uses Color(hex:) from DesignSystem.swift

#Preview {
    NavigationStack {
        DashboardView()
    }
    .environment(CardViewModel())
    .environment(DataFeedService())
}
