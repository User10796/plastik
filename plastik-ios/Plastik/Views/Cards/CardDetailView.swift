import SwiftUI

struct CardDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(CardViewModel.self) private var viewModel
    @Environment(DataFeedService.self) private var feedService
    @State private var userCard: UserCard
    @State private var showDeleteConfirmation = false
    @State private var showCloseCardConfirmation = false
    @State private var closeDate = Date()
    @State private var showEditSheet = false

    init(userCard: UserCard) {
        _userCard = State(initialValue: userCard)
    }

    private var card: CreditCard? {
        feedService.card(for: userCard.cardId)
    }

    // MARK: - Computed Properties for Overrides

    /// Returns the effective annual fee (user override or catalog value)
    private var effectiveAnnualFee: Int {
        userCard.annualFeeOverride ?? card?.annualFee ?? 0
    }

    /// Returns the effective issuer name
    private var effectiveIssuerName: String {
        if let override = userCard.issuerOverride, let issuer = Issuer(rawValue: override) {
            return issuer.displayName
        }
        return card?.issuer.displayName ?? "Unknown"
    }

    /// Returns the effective card name
    private var effectiveCardName: String {
        userCard.productNameOverride ?? card?.name ?? userCard.nickname ?? "Unknown Card"
    }

    /// Returns the effective network
    private var effectiveNetwork: CardNetwork {
        if let override = userCard.networkOverride, let network = CardNetwork(rawValue: override) {
            return network
        }
        return card?.network ?? .visa
    }

    /// Returns whether this card has user overrides
    private var hasUserOverrides: Bool {
        userCard.annualFeeOverride != nil ||
        userCard.issuerOverride != nil ||
        userCard.productNameOverride != nil ||
        userCard.networkOverride != nil ||
        userCard.signupBonusOverride != nil ||
        userCard.rewardCategoriesOverride != nil ||
        userCard.cardIconColor != nil
    }

    /// Card header gradient colors - uses custom icon color if set
    private var headerGradientColors: [Color] {
        if let hex = userCard.cardIconColor, !hex.isEmpty {
            return [Color(hex: hex), Color(hex: hex).opacity(0.7)]
        }
        if let card = card {
            return [issuerGradientStart(card.issuer), issuerGradientEnd(card.issuer)]
        }
        return [Color(hex: "4a5568"), Color(hex: "2d3748")]
    }

    var body: some View {
        List {
            if let card {
                cardHeaderSection(card)
                earningRatesSection(card)
                if let bonus = userCard.signupBonusProgress {
                    bonusSection(bonus)
                } else if let override = userCard.signupBonusOverride {
                    signupBonusOverrideSection(override)
                }
                if !card.benefits.isEmpty {
                    benefitsSection(card)
                }
                if !card.transferPartners.isEmpty {
                    transferPartnersSection(card)
                }
                if userCard.currentBalance != nil || userCard.lastStatementDate != nil {
                    statementDataSection
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
                } else if let override = userCard.signupBonusOverride {
                    signupBonusOverrideSection(override)
                }
                if let categories = userCard.rewardCategoriesOverride, !categories.isEmpty {
                    customEarningRatesSection(categories)
                }
                if userCard.currentBalance != nil || userCard.lastStatementDate != nil {
                    statementDataSection
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
                Button {
                    showEditSheet = true
                } label: {
                    Image(systemName: "pencil.circle")
                }
            }
        }
        .sheet(isPresented: $showEditSheet, onDismiss: {
            refreshFromViewModel()
        }) {
            EditCardView(userCard: $userCard, catalogCard: card)
                .id(userCard.id) // Force fresh sheet per card
        }
        .onChange(of: viewModel.userCards) { _, _ in
            refreshFromViewModel()
        }
        .confirmationDialog(
            "Delete \"\(cardDisplayName)\"?",
            isPresented: $showDeleteConfirmation,
            titleVisibility: .visible
        ) {
            Button("Delete", role: .destructive) {
                viewModel.deleteCard(userCard)
                dismiss()
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("This will permanently remove this card and all associated data. This cannot be undone.")
        }
    }

    // MARK: - Computed Properties

    private var cardDisplayName: String {
        userCard.nickname ?? card?.name ?? "this card"
    }

    /// Refresh local @State userCard from viewModel's canonical copy
    private func refreshFromViewModel() {
        let oldColor = userCard.cardIconColor
        if let updated = viewModel.userCards.first(where: { $0.id == userCard.id }) {
            userCard = updated
            print("CardDetailView.refresh: \(userCard.cardId) by UUID, color: \(oldColor ?? "nil") -> \(updated.cardIconColor ?? "nil")")
        } else if let updated = viewModel.userCards.first(where: { $0.cardId == userCard.cardId && $0.openDate == userCard.openDate }) {
            userCard = updated
            print("CardDetailView.refresh: \(userCard.cardId) by cardId+date fallback, color: \(oldColor ?? "nil") -> \(updated.cardIconColor ?? "nil")")
        } else {
            print("CardDetailView.refresh: \(userCard.cardId) NOT FOUND in viewModel (id=\(userCard.id))")
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
                            colors: headerGradientColors,
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(height: 180)
                    .overlay(alignment: .topLeading) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(effectiveIssuerName)
                                .font(.caption)
                                .foregroundStyle(.white.opacity(0.8))
                            Text(effectiveCardName)
                                .font(.title3.bold())
                                .foregroundStyle(.white)
                        }
                        .padding()
                    }
                    .overlay(alignment: .bottomTrailing) {
                        VStack(alignment: .trailing, spacing: 2) {
                            Text(effectiveNetwork.displayName)
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
                    .overlay(alignment: .topTrailing) {
                        Button {
                            showEditSheet = true
                        } label: {
                            Image(systemName: "pencil.circle.fill")
                                .font(.title3)
                                .foregroundStyle(.white)
                                .padding(8)
                        }
                        .buttonStyle(.plain)
                    }

                HStack {
                    VStack(alignment: .leading) {
                        HStack(spacing: 4) {
                            Text("Annual Fee")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            if userCard.annualFeeOverride != nil {
                                Image(systemName: "pencil.circle.fill")
                                    .font(.caption2)
                                    .foregroundStyle(.blue)
                            }
                        }
                        Text(effectiveAnnualFee > 0 ? effectiveAnnualFee.currencyFormatted : "No Fee")
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
                        HStack(spacing: 4) {
                            Image(systemName: userCard.cardStatus.icon)
                                .font(.caption)
                            Text(userCard.cardStatus.displayName)
                                .font(.headline)
                        }
                        .foregroundStyle(statusColor)
                    }
                }
            }
        }
    }

    private var statusColor: Color {
        switch userCard.cardStatus {
        case .active: return .green
        case .closed: return .red
        case .productChanged: return .orange
        }
    }

    @ViewBuilder
    private func earningRatesSection(_ card: CreditCard) -> some View {
        Section {
            // Show user-overridden categories if they exist
            if let userCategories = userCard.rewardCategoriesOverride, !userCategories.isEmpty {
                ForEach(userCategories.sorted { $0.rewardRate > $1.rewardRate }) { category in
                    HStack {
                        Image(systemName: iconForCategory(category.categoryName))
                            .frame(width: 24)
                            .foregroundStyle(.blue)
                        Text(category.categoryName)
                        Spacer()
                        Text(category.formattedRate)
                            .font(.headline)
                            .foregroundStyle(.primary)
                        if let cap = category.formattedCap {
                            Text("(\(cap))")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Image(systemName: "pencil.circle.fill")
                            .font(.caption2)
                            .foregroundStyle(.blue)
                    }
                }

                // Show catalog rates in a collapsed section if user has overrides
                if !card.earningRates.isEmpty {
                    DisclosureGroup {
                        ForEach(card.earningRates.sorted { $0.multiplier > $1.multiplier }) { rate in
                            HStack {
                                Image(systemName: rate.category.icon)
                                    .frame(width: 24)
                                    .foregroundStyle(.secondary)
                                Text(rate.category.displayName)
                                    .foregroundStyle(.secondary)
                                Spacer()
                                Text(rate.multiplier.multiplierFormatted)
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    } label: {
                        HStack {
                            Image(systemName: "info.circle")
                                .foregroundStyle(.secondary)
                            Text("Original Catalog Rates")
                                .foregroundStyle(.secondary)
                        }
                        .font(.caption)
                    }
                }
            } else {
                // Show catalog rates normally
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
        } header: {
            HStack {
                Text("Earning Rates")
                if userCard.rewardCategoriesOverride != nil {
                    Text("(Custom)")
                        .font(.caption2)
                        .foregroundStyle(.blue)
                }
            }
        }
    }

    private func iconForCategory(_ name: String) -> String {
        let lower = name.lowercased()
        if lower.contains("dining") || lower.contains("restaurant") { return "fork.knife" }
        if lower.contains("travel") { return "airplane" }
        if lower.contains("groceries") || lower.contains("grocery") { return "cart.fill" }
        if lower.contains("gas") { return "fuelpump.fill" }
        if lower.contains("streaming") { return "play.tv.fill" }
        if lower.contains("hotel") { return "bed.double.fill" }
        if lower.contains("airline") { return "airplane.departure" }
        if lower.contains("uber") || lower.contains("lyft") { return "car.fill" }
        if lower.contains("online") || lower.contains("shopping") { return "globe" }
        if lower.contains("drugstore") || lower.contains("pharmacy") { return "cross.case.fill" }
        if lower.contains("home") { return "hammer.fill" }
        if lower.contains("entertainment") { return "ticket.fill" }
        return "creditcard.fill"
    }

    @ViewBuilder
    private func bonusSection(_ bonus: BonusProgress) -> some View {
        Section {
            VStack(alignment: .leading, spacing: 8) {
                // Show user override info if available
                if let override = userCard.signupBonusOverride {
                    HStack {
                        Text("\(override.bonusAmount.commaFormatted)")
                            .font(.title2.bold())
                        Text(override.bonusType.displayName.lowercased())
                            .foregroundStyle(.secondary)
                        Spacer()
                        bonusStatusBadge(override.bonusEarned)
                    }

                    HStack {
                        Text("Spend $\(override.spendRequirement.commaFormatted) in \(override.timeframeDays) days")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        Spacer()
                        Image(systemName: "pencil.circle.fill")
                            .font(.caption2)
                            .foregroundStyle(.blue)
                    }
                }

                ProgressView(value: bonus.progress)
                    .tint(bonus.completed ? .green : (bonus.isExpired ? .red : .blue))
                    .scaleEffect(y: 2)
                    .padding(.vertical, 4)

                if userCard.signupBonusOverride == nil {
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
        } header: {
            HStack {
                Text("Signup Bonus Progress")
                if userCard.signupBonusOverride != nil {
                    Text("(Custom)")
                        .font(.caption2)
                        .foregroundStyle(.blue)
                }
            }
        }
    }

    @ViewBuilder
    private func bonusStatusBadge(_ status: BonusEarnedStatus) -> some View {
        switch status {
        case .yes:
            Label("Earned", systemImage: "checkmark.circle.fill")
                .font(.caption.bold())
                .foregroundStyle(.green)
        case .no:
            Label("Not Earned", systemImage: "xmark.circle.fill")
                .font(.caption.bold())
                .foregroundStyle(.red)
        case .inProgress:
            Label("In Progress", systemImage: "clock.fill")
                .font(.caption.bold())
                .foregroundStyle(.blue)
        }
    }

    @ViewBuilder
    private func signupBonusOverrideSection(_ override: SignupBonusOverride) -> some View {
        Section {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("\(override.bonusAmount.commaFormatted)")
                        .font(.title2.bold())
                    Text(override.bonusType.displayName.lowercased())
                        .foregroundStyle(.secondary)
                    Spacer()
                    bonusStatusBadge(override.bonusEarned)
                }

                HStack {
                    Image(systemName: "dollarsign.circle")
                        .foregroundStyle(.blue)
                    Text("Spend $\(override.spendRequirement.commaFormatted)")
                    Spacer()
                    Image(systemName: "clock")
                        .foregroundStyle(.secondary)
                    Text("\(override.timeframeDays) days")
                        .foregroundStyle(.secondary)
                }
                .font(.subheadline)
            }
        } header: {
            HStack {
                Text("Signup Bonus")
                Text("(Custom)")
                    .font(.caption2)
                    .foregroundStyle(.blue)
            }
        }
    }

    @ViewBuilder
    private func customEarningRatesSection(_ categories: [UserRewardCategory]) -> some View {
        Section {
            ForEach(categories.sorted { $0.rewardRate > $1.rewardRate }) { category in
                HStack {
                    Image(systemName: iconForCategory(category.categoryName))
                        .frame(width: 24)
                        .foregroundStyle(.blue)
                    Text(category.categoryName)
                    Spacer()
                    Text(category.formattedRate)
                        .font(.headline)
                        .foregroundStyle(.primary)
                    if let cap = category.formattedCap {
                        Text("(\(cap))")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        } header: {
            HStack {
                Text("Earning Rates")
                Text("(Custom)")
                    .font(.caption2)
                    .foregroundStyle(.blue)
            }
        }
    }

    @ViewBuilder
    private var statementDataSection: some View {
        Section("Statement Data") {
            if let balance = userCard.currentBalance {
                HStack {
                    Label("Current Balance", systemImage: "dollarsign.circle")
                    Spacer()
                    Text(balance.currencyFormatted)
                        .font(.headline)
                        .foregroundColor(balance >= 0 ? .primary : .red)
                }
            }

            if let date = userCard.lastStatementDate {
                HStack {
                    Label("Statement Date", systemImage: "calendar")
                    Spacer()
                    Text(date.shortFormatted)
                        .foregroundStyle(.secondary)
                }
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
            if let nickname = userCard.nickname {
                LabeledContent("Nickname", value: nickname)
            }
            if let last4 = userCard.lastFourDigits {
                LabeledContent("Last 4", value: last4)
            }
            LabeledContent("Opened", value: userCard.openDate.shortFormatted)
            HStack {
                Text("Status")
                Spacer()
                HStack(spacing: 4) {
                    Image(systemName: userCard.cardStatus.icon)
                        .font(.caption)
                    Text(userCard.cardStatus.displayName)
                }
                .foregroundStyle(statusColor)
            }
            if userCard.cardStatus == .closed, let closedDate = userCard.closedDate {
                LabeledContent("Closed", value: closedDate.shortFormatted)
            }
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
            if userCard.cardStatus == .active {
                Button {
                    closeDate = Date()
                    showCloseCardConfirmation = true
                } label: {
                    Label("Close Card", systemImage: "xmark.circle")
                        .foregroundStyle(.orange)
                }
            } else {
                Button {
                    userCard.cardStatus = .active
                    userCard.closedDate = nil
                    userCard.isActive = true
                    viewModel.updateCard(userCard)
                } label: {
                    Label("Reactivate Card", systemImage: "arrow.uturn.backward")
                }
            }

            Button(role: .destructive) {
                showDeleteConfirmation = true
            } label: {
                Label("Delete Card", systemImage: "trash")
            }
        }
        .sheet(isPresented: $showCloseCardConfirmation) {
            closeCardConfirmationSheet
        }
    }

    @ViewBuilder
    private var closeCardConfirmationSheet: some View {
        NavigationStack {
            Form {
                Section {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack(spacing: 8) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundStyle(.orange)
                                .font(.title3)
                            Text("Close \"\(cardDisplayName)\"?")
                                .font(.headline)
                        }

                        Text("Closing this card will:")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)

                        VStack(alignment: .leading, spacing: 6) {
                            closeCardBullet("Remove it from your active card count")
                            closeCardBullet("Remove it from \"Which Card Should I Use\" recommendations")
                            closeCardBullet("Move it to the Closed Cards section")
                            closeCardBullet("Record the close date for churn timing calculations")
                            closeCardBullet("Track when you become eligible for a new signup bonus")
                        }
                    }
                }

                Section("Close Date") {
                    DatePicker("Date Closed", selection: $closeDate, displayedComponents: .date)

                    Text("Choose the actual date the card was closed. This is used for churn eligibility calculations (e.g., 48-month bonus cooldowns).")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Section {
                    Text("You can reactivate this card later if needed.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            #if os(macOS)
            .formStyle(.grouped)
            .frame(minWidth: 450, minHeight: 400)
            #endif
            .navigationTitle("Close Card")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        showCloseCardConfirmation = false
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Close Card") {
                        userCard.cardStatus = .closed
                        userCard.closedDate = closeDate
                        userCard.isActive = false
                        viewModel.updateCard(userCard)
                        showCloseCardConfirmation = false
                    }
                    .foregroundStyle(.orange)
                    .fontWeight(.semibold)
                }
            }
        }
    }

    @ViewBuilder
    private func closeCardBullet(_ text: String) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: "circle.fill")
                .font(.system(size: 5))
                .foregroundStyle(.secondary)
                .padding(.top, 6)
            Text(text)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }

    // MARK: - Helpers

    private func issuerGradientStart(_ issuer: Issuer) -> Color {
        switch issuer {
        // Tier 1: Major Issuers
        case .chase: return .blue
        case .amex: return .indigo
        case .citi: return .cyan
        case .capitalOne: return .red
        case .barclays: return .teal
        case .usBank: return .purple
        case .wellsFargo: return .yellow
        case .bankOfAmerica: return .red
        case .discover: return .orange
        // Tier 2: Mid-Market & Specialty Issuers
        case .usaa: return .blue
        case .navyFederal: return .blue
        case .pnc: return .orange
        case .tdBank: return .green
        case .synchrony: return .blue
        case .breadFinancial: return .orange
        case .goldmanSachs: return .blue
        case .fnbo: return .blue
        case .creditOne: return .blue
        case .upgrade: return .teal
        case .avant: return .green
        // Tier 3: Tech & Fintech Issuers
        case .apple: return .gray
        case .brex: return .orange
        case .ramp: return .yellow
        case .mercury: return .indigo
        // Special
        case .custom: return .gray
        }
    }

    private func issuerGradientEnd(_ issuer: Issuer) -> Color {
        switch issuer {
        // Tier 1: Major Issuers
        case .chase: return .blue.opacity(0.6)
        case .amex: return .purple
        case .citi: return .blue
        case .capitalOne: return .orange
        case .barclays: return .cyan
        case .usBank: return .indigo
        case .wellsFargo: return .red
        case .bankOfAmerica: return .pink
        case .discover: return .yellow
        // Tier 2: Mid-Market & Specialty Issuers
        case .usaa: return .blue.opacity(0.6)
        case .navyFederal: return .blue.opacity(0.6)
        case .pnc: return .orange.opacity(0.6)
        case .tdBank: return .green.opacity(0.6)
        case .synchrony: return .blue.opacity(0.6)
        case .breadFinancial: return .orange.opacity(0.6)
        case .goldmanSachs: return .cyan
        case .fnbo: return .blue.opacity(0.6)
        case .creditOne: return .blue.opacity(0.6)
        case .upgrade: return .cyan
        case .avant: return .green.opacity(0.6)
        // Tier 3: Tech & Fintech Issuers
        case .apple: return .gray.opacity(0.6)
        case .brex: return .red
        case .ramp: return .orange
        case .mercury: return .purple
        // Special
        case .custom: return .gray.opacity(0.6)
        }
    }
}
