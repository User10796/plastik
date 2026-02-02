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

    // MARK: - Welcome Section

    @ViewBuilder
    private var welcomeSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Welcome back!")
                .font(.title2.bold())
            Text("Here's your card optimization summary.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Stats Section

    @ViewBuilder
    private var statsSection: some View {
        LazyVGrid(columns: [
            GridItem(.flexible()),
            GridItem(.flexible()),
            GridItem(.flexible()),
            GridItem(.flexible())
        ], spacing: 12) {
            StatCard(
                value: "\(cardViewModel.activeCards.count)",
                label: "Active Cards",
                color: .blue
            )

            StatCard(
                value: "\(cardViewModel.closedCards.count)",
                label: "Closed",
                color: .gray
            )

            StatCard(
                value: "\(cardViewModel.fiveOverTwentyFourCount)/5",
                label: "5/24 Status",
                color: cardViewModel.fiveOverTwentyFourCount >= 5 ? .red : .orange
            )

            StatCard(
                value: totalPointsFormatted,
                label: "Total Points",
                color: .purple
            )
        }
    }

    // MARK: - Which Card Section

    @ViewBuilder
    private var whichCardSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Which Card Should I Use?")
                .font(.headline)

            let categories: [SpendCategory] = [.dining, .groceries, .gas, .travel]

            if cardViewModel.activeCards.isEmpty {
                Text("Add cards to see recommendations")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .padding(.vertical, 8)
            } else {
                VStack(spacing: 8) {
                    ForEach(categories) { category in
                        if let (userCard, creditCard, rate) = bestCardForCategory(category) {
                            HStack {
                                Image(systemName: category.icon)
                                    .foregroundStyle(.blue)
                                    .frame(width: 24)

                                Text(category.displayName)
                                    .font(.subheadline)
                                    .frame(width: 80, alignment: .leading)

                                Text(userCard.nickname ?? creditCard.name)
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                                    .lineLimit(1)

                                Spacer()

                                Text(rate.multiplierFormatted)
                                    .font(.subheadline.bold())
                                    .foregroundStyle(.green)
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 10)
                            .background(Color(.systemGray).opacity(0.1))
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                        }
                    }
                }
            }
        }
        .padding()
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    // MARK: - Transfer Partners Section

    @ViewBuilder
    private var transferPartnersSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Transfer Partners")
                    .font(.headline)
                Spacer()
                Text("Your \(totalPointsFormatted) points unlock:")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            HStack {
                Text("\(airlinePartners) Airlines")
                    .font(.subheadline.bold())
                    .foregroundStyle(.green)
                Text("·")
                    .foregroundStyle(.secondary)
                Text("\(hotelPartners) Hotels")
                    .font(.subheadline.bold())
                    .foregroundStyle(.green)
            }

            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 8) {
                ForEach(feedService.transferPartners.prefix(6)) { partner in
                    Text(partner.name.prefix(3).uppercased())
                        .font(.caption2.bold())
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(Color(.systemGray).opacity(0.2))
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                }
            }
        }
        .padding()
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    // MARK: - My Cards Section

    @ViewBuilder
    private var myCardsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("My Cards")
                    .font(.headline)
                Spacer()
                NavigationLink("View All →") {
                    CardListView()
                }
                .font(.caption)
            }

            if cardViewModel.activeCards.isEmpty {
                Text("No active cards")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .padding(.vertical, 8)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(cardViewModel.activeCards.prefix(5)) { userCard in
                            let card = feedService.card(for: userCard.cardId)
                            MiniCardView(userCard: userCard, card: card)
                        }
                    }
                }
            }
        }
    }

    // MARK: - Upcoming Actions Section

    @ViewBuilder
    private var upcomingActionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Upcoming Actions")
                .font(.headline)

            HStack(spacing: 20) {
                ForEach(upcomingActions.prefix(4), id: \.title) { action in
                    VStack(spacing: 8) {
                        Circle()
                            .fill(action.color)
                            .frame(width: 12, height: 12)
                        Text(action.date)
                            .font(.caption.bold())
                        Text(action.title)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
        }
        .padding()
        .background(.ultraThinMaterial)
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

    private var upcomingActions: [(date: String, title: String, color: Color)] {
        // Generate real upcoming actions from user cards
        var actions: [(date: String, title: String, color: Color)] = []

        // Add annual fee dates
        for userCard in cardViewModel.activeCards {
            if let feeDate = userCard.annualFeeDate, feeDate > Date() {
                let card = feedService.card(for: userCard.cardId)
                let name = userCard.nickname ?? card?.name ?? "Card"
                actions.append((feeDate.shortFormatted, "\(name) Fee", .red))
            }
        }

        // Add bonus deadlines
        for userCard in cardViewModel.cardsWithActiveBonus {
            if let bonus = userCard.signupBonusProgress, !bonus.completed && !bonus.isExpired {
                let card = feedService.card(for: userCard.cardId)
                let name = userCard.nickname ?? card?.name ?? "Card"
                actions.append((bonus.deadline.shortFormatted, "\(name) Bonus", .orange))
            }
        }

        // Sort by date and take first 4
        return Array(actions.sorted { $0.date < $1.date }.prefix(4))
    }
}

// MARK: - Supporting Views

struct StatCard: View {
    let value: String
    let label: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(value)
                .font(.title2.bold())
                .foregroundStyle(color)
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}

struct MiniCardView: View {
    let userCard: UserCard
    let card: CreditCard?

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(userCard.nickname ?? card?.name.components(separatedBy: " ").first ?? userCard.cardId)
                .font(.caption.bold())
                .foregroundStyle(.white)
                .lineLimit(2)
            Spacer()
            if let fee = card?.annualFee, fee > 0 {
                Text(fee.currencyFormatted + "/yr")
                    .font(.caption2)
                    .foregroundStyle(.white.opacity(0.8))
            } else if card != nil {
                Text("No AF")
                    .font(.caption2)
                    .foregroundStyle(.white.opacity(0.8))
            } else {
                Text(card?.issuer.displayName ?? "")
                    .font(.caption2)
                    .foregroundStyle(.white.opacity(0.8))
            }
        }
        .frame(width: 100, height: 65, alignment: .topLeading)
        .padding(10)
        .background(
            LinearGradient(
                colors: card.map { cardGradient(for: $0.issuer) } ?? [.gray, .gray.opacity(0.7)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    private func cardGradient(for issuer: Issuer) -> [Color] {
        switch issuer {
        case .chase: return [.blue, .blue.opacity(0.7)]
        case .amex: return [.indigo, .purple]
        case .citi: return [.cyan, .blue]
        case .capitalOne: return [.red, .orange]
        case .barclays: return [.teal, .cyan]
        case .usBank: return [.purple, .indigo]
        case .wellsFargo: return [.yellow, .orange]
        case .bankOfAmerica: return [.red, .pink]
        case .discover: return [.orange, .yellow]
        }
    }
}

#Preview {
    NavigationStack {
        DashboardView()
    }
    .environment(CardViewModel())
    .environment(DataFeedService())
}
