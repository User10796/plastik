import SwiftUI

struct CardDetailView: View {
    @Environment(CardViewModel.self) private var viewModel
    @Environment(DataFeedService.self) private var feedService
    @State private var userCard: UserCard
    @State private var showDeleteConfirmation = false
    @State private var isEditing = false
    @State private var bonusSpendInput = ""

    init(userCard: UserCard) {
        _userCard = State(initialValue: userCard)
    }

    private var card: CreditCard? {
        feedService.card(for: userCard.cardId)
    }

    var body: some View {
        List {
            if let card {
                cardHeaderSection(card)
                earningRatesSection(card)
                if let bonus = userCard.signupBonusProgress {
                    bonusSection(bonus)
                }
                if !card.benefits.isEmpty {
                    benefitsSection(card)
                }
                if !card.transferPartners.isEmpty {
                    transferPartnersSection(card)
                }
                churnEligibilitySection(card)
                churnRulesSection(card)
                referralSection(card)
                userInfoSection
                actionsSection
            } else {
                // Fallback when card catalog data isn't available
                basicCardInfoSection
                if let bonus = userCard.signupBonusProgress {
                    bonusSection(bonus)
                }
                userInfoSection
                actionsSection
            }
        }
        .navigationTitle(userCard.nickname ?? card?.name ?? "Card Detail")
        #if os(iOS)
        .navigationBarTitleDisplayMode(.large)
        #endif
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button(isEditing ? "Done" : "Edit") {
                    if isEditing {
                        // Apply bonus spend update
                        if let amount = Int(bonusSpendInput),
                           userCard.signupBonusProgress != nil {
                            userCard.signupBonusProgress?.spentSoFar = amount
                            if amount >= (userCard.signupBonusProgress?.targetSpend ?? 0) {
                                userCard.signupBonusProgress?.completed = true
                            }
                        }
                        viewModel.updateCard(userCard)
                    }
                    isEditing.toggle()
                }
            }
        }
        .confirmationDialog(
            "Delete this card from your wallet?",
            isPresented: $showDeleteConfirmation,
            titleVisibility: .visible
        ) {
            Button("Delete", role: .destructive) {
                viewModel.deleteCard(userCard)
            }
        }
    }

    // MARK: - Sections

    @ViewBuilder
    private func cardHeaderSection(_ card: CreditCard) -> some View {
        Section {
            VStack(spacing: 16) {
                // Card visual
                RoundedRectangle(cornerRadius: 12)
                    .fill(
                        LinearGradient(
                            colors: [issuerGradientStart(card.issuer), issuerGradientEnd(card.issuer)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(height: 180)
                    .overlay(alignment: .topLeading) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(card.issuer.displayName)
                                .font(.caption)
                                .foregroundStyle(.white.opacity(0.8))
                            Text(card.name)
                                .font(.title3.bold())
                                .foregroundStyle(.white)
                        }
                        .padding()
                    }
                    .overlay(alignment: .bottomTrailing) {
                        VStack(alignment: .trailing, spacing: 2) {
                            Text(card.network.displayName)
                                .font(.caption.bold())
                                .foregroundStyle(.white.opacity(0.8))
                            if let last4 = userCard.lastFourDigits {
                                Text("•••• \(last4)")
                                    .font(.body.monospacedDigit())
                                    .foregroundStyle(.white)
                            }
                        }
                        .padding()
                    }

                HStack {
                    VStack(alignment: .leading) {
                        Text("Annual Fee")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text(card.annualFee > 0 ? card.annualFee.currencyFormatted : "No Fee")
                            .font(.headline)
                    }
                    Spacer()
                    VStack(alignment: .center) {
                        Text("Opened")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text(userCard.openDate.shortFormatted)
                            .font(.headline)
                    }
                    Spacer()
                    VStack(alignment: .trailing) {
                        Text("Status")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text(userCard.isActive ? "Active" : "Closed")
                            .font(.headline)
                            .foregroundStyle(userCard.isActive ? .green : .red)
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func earningRatesSection(_ card: CreditCard) -> some View {
        Section("Earning Rates") {
            ForEach(card.earningRates.sorted { $0.multiplier > $1.multiplier }) { rate in
                HStack {
                    Image(systemName: rate.category.icon)
                        .frame(width: 24)
                        .foregroundStyle(.blue)
                    Text(rate.category.displayName)
                    Spacer()
                    Text(rate.multiplier.multiplierFormatted)
                        .font(.headline)
                        .foregroundStyle(.primary)
                    if let cap = rate.cap {
                        Text("(up to $\(cap.commaFormatted))")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func bonusSection(_ bonus: BonusProgress) -> some View {
        Section("Signup Bonus Progress") {
            VStack(alignment: .leading, spacing: 8) {
                ProgressView(value: bonus.progress)
                    .tint(bonus.completed ? .green : (bonus.isExpired ? .red : .blue))
                    .scaleEffect(y: 2)
                    .padding(.vertical, 4)

                if isEditing && !bonus.completed && !bonus.isExpired {
                    HStack {
                        Text("$")
                            .font(.headline)
                            .foregroundStyle(.secondary)
                        TextField("Amount spent", text: $bonusSpendInput)
                            #if os(iOS)
                            .keyboardType(.numberPad)
                            #endif
                            .font(.title2.bold())
                            .onAppear {
                                bonusSpendInput = "\(bonus.spentSoFar)"
                            }
                        Text("of $\(bonus.targetSpend.commaFormatted)")
                            .foregroundStyle(.secondary)
                    }

                    Text("Remaining: $\(max(0, bonus.targetSpend - (Int(bonusSpendInput) ?? bonus.spentSoFar)).commaFormatted)")
                        .font(.caption)
                        .foregroundStyle(.blue)
                } else {
                    HStack {
                        Text("$\(bonus.spentSoFar.commaFormatted)")
                            .font(.title2.bold())
                        Text("of $\(bonus.targetSpend.commaFormatted)")
                            .foregroundStyle(.secondary)
                        Spacer()
                        if bonus.completed {
                            Label("Complete", systemImage: "checkmark.circle.fill")
                                .font(.caption.bold())
                                .foregroundStyle(.green)
                        } else if bonus.isExpired {
                            Label("Expired", systemImage: "xmark.circle.fill")
                                .font(.caption.bold())
                                .foregroundStyle(.red)
                        } else {
                            Text("\(bonus.daysRemaining) days left")
                                .font(.caption)
                                .foregroundStyle(bonus.daysRemaining < 30 ? .red : .secondary)
                        }
                    }
                }

                Text("Deadline: \(bonus.deadline.shortFormatted)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    @ViewBuilder
    private func benefitsSection(_ card: CreditCard) -> some View {
        Section("Benefits") {
            ForEach(card.benefits) { benefit in
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
            }
        }
    }

    @ViewBuilder
    private func transferPartnersSection(_ card: CreditCard) -> some View {
        let partners = feedService.partners(for: card)
        if !partners.isEmpty {
            Section("Transfer Partners") {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 140))], spacing: 8) {
                    ForEach(partners) { partner in
                        HStack(spacing: 6) {
                            Image(systemName: partner.type.icon)
                                .font(.caption)
                                .foregroundStyle(.blue)
                            Text(partner.name)
                                .font(.caption)
                                .lineLimit(1)
                            Spacer()
                            Text("\(partner.transferRatio ?? 1.0, specifier: "%.0f"):1")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 6)
                        .background(.ultraThinMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func churnRulesSection(_ card: CreditCard) -> some View {
        let rules = feedService.rules(for: card)
        if !rules.isEmpty {
            Section("Churn Rules") {
                ForEach(rules) { rule in
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Image(systemName: rule.ruleType.icon)
                                .foregroundStyle(.orange)
                            Text(rule.description)
                                .font(.headline)
                        }
                        Text(rule.details)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 2)
                }
            }
        }
    }

    // Fallback header when card catalog data isn't available
    @ViewBuilder
    private var basicCardInfoSection: some View {
        Section {
            VStack(spacing: 16) {
                // Simple card visual
                RoundedRectangle(cornerRadius: 12)
                    .fill(
                        LinearGradient(
                            colors: [.gray, .gray.opacity(0.6)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(height: 180)
                    .overlay(alignment: .topLeading) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Card ID: \(userCard.cardId)")
                                .font(.caption)
                                .foregroundStyle(.white.opacity(0.8))
                            Text(userCard.nickname ?? "Unknown Card")
                                .font(.title3.bold())
                                .foregroundStyle(.white)
                        }
                        .padding()
                    }
                    .overlay(alignment: .bottomTrailing) {
                        VStack(alignment: .trailing, spacing: 2) {
                            if let last4 = userCard.lastFourDigits {
                                Text("•••• \(last4)")
                                    .font(.body.monospacedDigit())
                                    .foregroundStyle(.white)
                            }
                        }
                        .padding()
                    }

                HStack {
                    VStack(alignment: .leading) {
                        Text("Opened")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text(userCard.openDate.shortFormatted)
                            .font(.headline)
                    }
                    Spacer()
                    VStack(alignment: .trailing) {
                        Text("Status")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text(userCard.closedDate == nil ? "Active" : "Closed")
                            .font(.headline)
                            .foregroundStyle(userCard.closedDate == nil ? .green : .red)
                    }
                }

                Text("Card details not available in catalog. Some features may be limited.")
                    .font(.caption)
                    .foregroundStyle(.orange)
                    .multilineTextAlignment(.center)
            }
        }
    }

    @ViewBuilder
    private var userInfoSection: some View {
        Section("Card Info") {
            if isEditing {
                TextField("Nickname", text: Binding(
                    get: { userCard.nickname ?? "" },
                    set: { userCard.nickname = $0.isEmpty ? nil : $0 }
                ))

                TextField("Last 4 Digits", text: Binding(
                    get: { userCard.lastFourDigits ?? "" },
                    set: { userCard.lastFourDigits = $0.isEmpty ? nil : $0 }
                ))
                #if os(iOS)
                .keyboardType(.numberPad)
                #endif

                Toggle("Active", isOn: $userCard.isActive)

                TextField("Notes", text: Binding(
                    get: { userCard.notes ?? "" },
                    set: { userCard.notes = $0.isEmpty ? nil : $0 }
                ), axis: .vertical)
                .lineLimit(3...6)
            } else {
                if let nickname = userCard.nickname {
                    LabeledContent("Nickname", value: nickname)
                }
                if let last4 = userCard.lastFourDigits {
                    LabeledContent("Last 4", value: last4)
                }
                LabeledContent("Opened", value: userCard.openDate.shortFormatted)
                LabeledContent("Status", value: userCard.isActive ? "Active" : "Closed")
                if let notes = userCard.notes {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Notes")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text(notes)
                            .font(.body)
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func churnEligibilitySection(_ card: CreditCard) -> some View {
        let service = ChurnEligibilityService()
        let eligibility = service.checkEligibility(
            for: card,
            userCards: viewModel.userCards,
            churnRules: feedService.churnRules
        )

        Section("Eligibility Check") {
            if eligibility.canApply && eligibility.canGetBonus {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                    Text("Eligible for card and bonus")
                        .font(.subheadline)
                }
            }

            if !eligibility.canApply {
                ForEach(eligibility.applicationBlockers) { blocker in
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundStyle(.red)
                            Text(blocker.rule.name)
                                .font(.subheadline.bold())
                        }
                        Text(blocker.reason)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        if let action = blocker.actionRequired {
                            Text(action)
                                .font(.caption)
                                .foregroundStyle(.blue)
                        }
                        if let date = blocker.resolveDate {
                            Text("Resolves: \(date.shortFormatted)")
                                .font(.caption2)
                                .foregroundStyle(.orange)
                        }
                    }
                }
            }

            if eligibility.canApply && !eligibility.canGetBonus {
                ForEach(eligibility.bonusBlockers) { blocker in
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundStyle(.yellow)
                            Text("No Bonus: \(blocker.rule.name)")
                                .font(.subheadline.bold())
                        }
                        Text(blocker.reason)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        if let date = blocker.resolveDate {
                            Text("Bonus eligible: \(date.shortFormatted)")
                                .font(.caption2)
                                .foregroundStyle(.orange)
                        }
                    }
                }
            }

            // Recommendations
            ForEach(eligibility.recommendations, id: \.self) { rec in
                HStack {
                    Image(systemName: "lightbulb")
                        .foregroundStyle(.blue)
                        .font(.caption)
                    Text(rec)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    @ViewBuilder
    private func referralSection(_ card: CreditCard) -> some View {
        if let referralLink = card.referralLink, let url = URL(string: referralLink) {
            Section("Referral") {
                ShareLink(item: url) {
                    Label("Share Referral Link", systemImage: "square.and.arrow.up")
                }

                Button {
                    #if os(iOS)
                    UIPasteboard.general.string = referralLink
                    #elseif os(macOS)
                    NSPasteboard.general.clearContents()
                    NSPasteboard.general.setString(referralLink, forType: .string)
                    #endif
                } label: {
                    Label("Copy Referral Link", systemImage: "doc.on.doc")
                }
            }
        }
    }

    @ViewBuilder
    private var actionsSection: some View {
        Section {
            Button(userCard.isActive ? "Archive Card" : "Reactivate Card") {
                userCard.isActive.toggle()
                viewModel.updateCard(userCard)
            }

            Button("Delete Card", role: .destructive) {
                showDeleteConfirmation = true
            }
        }
    }

    // MARK: - Helpers

    private func issuerGradientStart(_ issuer: Issuer) -> Color {
        switch issuer {
        case .chase: return .blue
        case .amex: return .indigo
        case .citi: return .cyan
        case .capitalOne: return .red
        case .barclays: return .teal
        case .usBank: return .purple
        case .wellsFargo: return .yellow
        case .bankOfAmerica: return .red
        case .discover: return .orange
        }
    }

    private func issuerGradientEnd(_ issuer: Issuer) -> Color {
        switch issuer {
        case .chase: return .blue.opacity(0.6)
        case .amex: return .purple
        case .citi: return .blue
        case .capitalOne: return .orange
        case .barclays: return .cyan
        case .usBank: return .indigo
        case .wellsFargo: return .red
        case .bankOfAmerica: return .pink
        case .discover: return .yellow
        }
    }
}
