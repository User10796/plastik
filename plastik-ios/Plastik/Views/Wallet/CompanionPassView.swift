import SwiftUI

struct CompanionPassView: View {
    @Environment(CardViewModel.self) private var cardViewModel
    @Environment(DataFeedService.self) private var feedService

    var body: some View {
        List {
            Section {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Southwest Companion Pass")
                        .font(.headline)

                    Text("Earn 135,000 qualifying points in a calendar year to unlock free travel for a companion on all Southwest flights.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    if hasCompanionPassProgress {
                        ProgressView(value: companionPassProgress)
                            .tint(.orange)

                        HStack {
                            Text("\(earnedPoints.commaFormatted) / 135,000 points")
                                .font(.caption)
                            Spacer()
                            Text("\(Int(companionPassProgress * 100))%")
                                .font(.caption.bold())
                        }
                        .foregroundStyle(.secondary)
                    }
                }
                .padding(.vertical, 4)
            }

            Section("How to Earn") {
                VStack(alignment: .leading, spacing: 8) {
                    earnMethodRow(
                        icon: "creditcard.fill",
                        title: "Credit Card Signup Bonuses",
                        detail: "Southwest cards offer 50,000-75,000 points"
                    )

                    earnMethodRow(
                        icon: "cart.fill",
                        title: "Credit Card Spending",
                        detail: "Earn points on everyday purchases"
                    )

                    earnMethodRow(
                        icon: "airplane",
                        title: "Southwest Flights",
                        detail: "Earn points when flying Southwest"
                    )

                    earnMethodRow(
                        icon: "arrow.triangle.swap",
                        title: "Transfer Partners",
                        detail: "Transfer from Chase, Marriott, or hotel partners"
                    )
                }
            }

            Section("Your Southwest Cards") {
                let swCards = southwestCards
                if swCards.isEmpty {
                    HStack {
                        Image(systemName: "info.circle")
                            .foregroundStyle(.blue)
                        Text("No Southwest cards in wallet")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                } else {
                    ForEach(swCards) { userCard in
                        if let card = feedService.card(for: userCard.cardId) {
                            HStack {
                                VStack(alignment: .leading) {
                                    Text(userCard.nickname ?? card.name)
                                        .font(.subheadline)
                                    Text("Opened: \(userCard.openDate.shortFormatted)")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                Spacer()
                                if let bonus = userCard.signupBonusProgress {
                                    Text("\(bonus.spentSoFar.commaFormatted) pts")
                                        .font(.caption.bold())
                                        .foregroundStyle(.blue)
                                }
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle("Companion Passes")
    }

    @ViewBuilder
    private func earnMethodRow(icon: String, title: String, detail: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(.orange)
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline.bold())
                Text(detail)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
    }

    private var hasCompanionPassProgress: Bool {
        !southwestCards.isEmpty
    }

    private var earnedPoints: Int {
        // Placeholder - would sum SW card points
        45000
    }

    private var companionPassProgress: Double {
        min(Double(earnedPoints) / 135000.0, 1.0)
    }

    private var southwestCards: [UserCard] {
        cardViewModel.userCards.filter { userCard in
            guard let card = feedService.card(for: userCard.cardId) else { return false }
            return card.name.lowercased().contains("southwest")
        }
    }
}

#Preview {
    NavigationStack {
        CompanionPassView()
    }
    .environment(CardViewModel())
    .environment(DataFeedService())
}
