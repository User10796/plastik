import SwiftUI

struct ChurnTrackerView: View {
    @Environment(CardViewModel.self) private var cardViewModel
    @Environment(DataFeedService.self) private var feedService

    private let eligibilityService = ChurnEligibilityService()

    private var status524: (count: Int, details: [CardIn524]) {
        eligibilityService.calculate524Status(userCards: cardViewModel.userCards, feedService: feedService)
    }

    var body: some View {
        List {
            chase524Section
            issuerEligibilitySection
            bonusEligibilitySection
            cardsIn524Section
            recommendationsSection
            issuerRulesSection
            toolsSection
        }
        .navigationTitle("Churn Tracker")
        .navigationDestination(for: String.self) { destination in
            if destination == "transfer-partners" {
                TransferPartnerMapView()
            } else if destination == "data-import" {
                DataImportView()
            } else if destination == "strategy" {
                StrategyView()
            }
        }
    }

    // MARK: - 5/24 Status Dashboard

    @ViewBuilder
    private var chase524Section: some View {
        let count = status524.count

        Section("Your 5/24 Status") {
            VStack(spacing: 12) {
                HStack {
                    Text("\(count)/24")
                        .font(.system(size: 48, weight: .bold, design: .rounded))
                        .foregroundStyle(count < 4 ? .green : (count < 5 ? .yellow : .red))

                    Spacer()

                    VStack(alignment: .trailing, spacing: 4) {
                        Text(statusText(for: count))
                            .font(.headline)
                            .foregroundStyle(statusColor(for: count))
                        Text("\(max(0, 5 - count)) slots remaining")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                ProgressView(value: min(Double(count) / 5.0, 1.0))
                    .tint(count < 4 ? .green : (count < 5 ? .yellow : .red))
                    .scaleEffect(y: 2)

                // Next slot opening
                let slots = eligibilityService.getUpcomingSlots(userCards: cardViewModel.userCards, feedService: feedService)
                if let nextSlot = slots.first, count >= 5 {
                    HStack {
                        Image(systemName: "calendar.badge.clock")
                            .foregroundStyle(.blue)
                        Text("Next slot opens: \(nextSlot.date.shortFormatted)")
                            .font(.caption)
                        Spacer()
                        Text("→ \(nextSlot.newCount)/24")
                            .font(.caption.bold())
                            .foregroundStyle(.green)
                    }
                    .padding(.top, 4)
                }
            }
            .padding(.vertical, 8)
        }
    }

    // MARK: - Issuer Eligibility Status

    @ViewBuilder
    private var issuerEligibilitySection: some View {
        let statuses = eligibilityService.issuerStatuses(
            userCards: cardViewModel.userCards,
            churnRules: feedService.churnRules
        )

        if !statuses.isEmpty {
            Section("Issuer Status") {
                ForEach(statuses) { status in
                    HStack {
                        Image(systemName: issuerStatusIcon(status.status))
                            .foregroundStyle(issuerStatusColor(status.status))
                            .frame(width: 24)

                        VStack(alignment: .leading, spacing: 2) {
                            Text(status.issuer.displayName)
                                .font(.subheadline.bold())
                            Text(status.summary)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }

                        Spacer()

                        if let date = status.nextEligibleDate {
                            Text(date.shortFormatted)
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
        }
    }

    // MARK: - Bonus Eligibility Timeline

    @ViewBuilder
    private var bonusEligibilitySection: some View {
        let bonusRules = feedService.churnRules.filter { $0.ruleType == .bonusEligibility }
        let rulesByIssuer = Dictionary(grouping: bonusRules) { $0.issuer }

        if !bonusRules.isEmpty {
            Section("Bonus Eligibility") {
                ForEach(Issuer.allCases.filter { rulesByIssuer[$0] != nil }) { issuer in
                    if let rules = rulesByIssuer[issuer] {
                        ForEach(rules) { rule in
                            bonusRuleRow(rule: rule)
                        }
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func bonusRuleRow(rule: ChurnRule) -> some View {
        let relevantCards = cardViewModel.userCards.filter { uc in
            if let family = rule.productFamily {
                return uc.productFamily == family
            }
            return feedService.card(for: uc.cardId)?.issuer == rule.issuer
        }

        HStack {
            Image(systemName: rule.category == .lifetimeLanguage ? "exclamationmark.triangle" : "clock.arrow.circlepath")
                .foregroundStyle(rule.category == .lifetimeLanguage ? .red : .orange)
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 2) {
                Text(rule.name)
                    .font(.subheadline.bold())

                if rule.category == .lifetimeLanguage {
                    if relevantCards.isEmpty {
                        Text("Eligible (no prior card)")
                            .font(.caption)
                            .foregroundStyle(.green)
                    } else {
                        Text("Ineligible (once per lifetime)")
                            .font(.caption)
                            .foregroundStyle(.red)
                    }
                } else if let cooldown = rule.cooldownMonths {
                    // Check if cooldown has passed
                    let latestRelevant = relevantCards.compactMap { uc -> Date? in
                        switch rule.cooldownStartsFrom {
                        case .bonusReceived: return uc.signupBonusReceivedDate
                        case .cardClosed: return uc.closedDate
                        case .cardOpened: return uc.openDate
                        case .none: return uc.openDate
                        }
                    }.max()

                    if let startDate = latestRelevant {
                        let eligibleDate = Calendar.current.date(byAdding: .month, value: cooldown, to: startDate) ?? startDate
                        if eligibleDate <= Date() {
                            Text("Eligible now")
                                .font(.caption)
                                .foregroundStyle(.green)
                        } else {
                            Text("Eligible: \(eligibleDate.shortFormatted)")
                                .font(.caption)
                                .foregroundStyle(.orange)
                        }
                    } else {
                        Text("Eligible (no prior card)")
                            .font(.caption)
                            .foregroundStyle(.green)
                    }
                }
            }

            Spacer()

            Text(rule.issuer.displayName)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
    }

    // MARK: - Cards in 5/24 Window

    @ViewBuilder
    private var cardsIn524Section: some View {
        let details = status524.details

        Section("Cards in 5/24 Window") {
            if details.isEmpty {
                Text("No cards opened in the past 24 months.")
                    .foregroundStyle(.secondary)
            } else {
                ForEach(details) { card524 in
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(card524.cardName)
                                .font(.body)
                            if let card = feedService.card(for: card524.card.cardId) {
                                Text(card.issuer.displayName)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        Spacer()
                        VStack(alignment: .trailing, spacing: 2) {
                            Text(card524.card.openDate.monthYear)
                                .font(.caption)
                            Text("Ages out \(card524.agesOutDate.monthYear)")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                            if card524.daysUntilAgeOut > 0 && card524.daysUntilAgeOut < 90 {
                                Text("\(card524.daysUntilAgeOut)d")
                                    .font(.caption2.bold())
                                    .foregroundStyle(.green)
                            }
                        }
                    }
                }
            }
        }
    }

    // MARK: - Recommendations

    @ViewBuilder
    private var recommendationsSection: some View {
        let count = status524.count

        Section("Recommendations") {
            if count >= 5 {
                let slots = eligibilityService.getUpcomingSlots(userCards: cardViewModel.userCards, feedService: feedService)
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.red)
                        Text("Chase cards unavailable")
                            .font(.subheadline.bold())
                    }
                    if let nextSlot = slots.first {
                        Text("Wait until \(nextSlot.date.shortFormatted) when \(nextSlot.cardName) ages out")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Text("Focus on non-Chase cards from Amex, Citi, Capital One, or Barclays")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            } else if count == 4 {
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundStyle(.yellow)
                        Text("Last Chase slot available")
                            .font(.subheadline.bold())
                    }
                    Text("Choose wisely - consider a premium Chase card (Sapphire, Ink) before hitting 5/24")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            } else {
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                        Text("Safe to apply for Chase cards")
                            .font(.subheadline.bold())
                    }
                    Text("You have \(5 - count) slots. Prioritize Chase cards first since they enforce 5/24.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            // Active bonus warnings
            let activeBonus = cardViewModel.userCards.filter {
                $0.signupBonusProgress != nil && !($0.signupBonusProgress?.completed ?? true)
            }
            ForEach(activeBonus) { userCard in
                if let bonus = userCard.signupBonusProgress,
                   let card = feedService.card(for: userCard.cardId) {
                    let remaining = bonus.targetSpend - bonus.spentSoFar
                    HStack {
                        Image(systemName: "clock.fill")
                            .foregroundStyle(.blue)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("\(card.name) bonus in progress")
                                .font(.caption.bold())
                            Text("$\(remaining.commaFormatted) more to spend by \(bonus.deadline.shortFormatted)")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
        }
    }

    // MARK: - Issuer Rules

    @ViewBuilder
    private var issuerRulesSection: some View {
        let rulesByIssuer = Dictionary(grouping: feedService.churnRules) { $0.issuer }

        Section("Issuer Rules") {
            ForEach(Issuer.allCases.filter { rulesByIssuer[$0] != nil }) { issuer in
                DisclosureGroup {
                    ForEach(rulesByIssuer[issuer] ?? []) { rule in
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Image(systemName: rule.category.icon)
                                    .foregroundStyle(rule.ruleType == .applicationEligibility ? .blue : .orange)
                                    .frame(width: 20)
                                Text(rule.name)
                                    .font(.subheadline.bold())
                                Spacer()
                                Text(rule.ruleType.displayName)
                                    .font(.caption2)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(rule.ruleType == .applicationEligibility ? .blue.opacity(0.15) : .orange.opacity(0.15))
                                    .foregroundStyle(rule.ruleType == .applicationEligibility ? .blue : .orange)
                                    .clipShape(RoundedRectangle(cornerRadius: 4))
                            }
                            Text(rule.details)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .padding(.vertical, 2)
                    }
                } label: {
                    Text(issuer.displayName)
                        .font(.headline)
                }
            }
        }
    }

    // MARK: - Tools

    @ViewBuilder
    private var toolsSection: some View {
        Section("Tools") {
            NavigationLink(value: "transfer-partners") {
                Label("Transfer Partner Map", systemImage: "arrow.triangle.swap")
            }

            NavigationLink(value: "strategy") {
                Label("Cancel vs Keep Strategy", systemImage: "chart.bar.doc.horizontal")
            }

            NavigationLink(value: "data-import") {
                Label("Import Statement (PDF)", systemImage: "doc.fill")
            }
        }
    }

    // MARK: - Helpers

    private func statusText(for count: Int) -> String {
        if count < 4 { return "Safe to Apply" }
        if count == 4 { return "Last Slot" }
        return "Over 5/24"
    }

    private func statusColor(for count: Int) -> Color {
        if count < 4 { return .green }
        if count == 4 { return .yellow }
        return .red
    }

    private func issuerStatusIcon(_ level: IssuerEligibilityStatus.EligibilityLevel) -> String {
        switch level {
        case .safe: return "checkmark.circle.fill"
        case .caution: return "exclamationmark.triangle.fill"
        case .blocked: return "xmark.circle.fill"
        }
    }

    private func issuerStatusColor(_ level: IssuerEligibilityStatus.EligibilityLevel) -> Color {
        switch level {
        case .safe: return .green
        case .caution: return .yellow
        case .blocked: return .red
        }
    }
}
