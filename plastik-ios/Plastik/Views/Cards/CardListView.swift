import SwiftUI

struct CardListView: View {
    @Environment(CardViewModel.self) private var viewModel
    @Environment(DataFeedService.self) private var feedService
    @State private var showAddCard = false
    @State private var searchText = ""

    // Delete confirmation state
    @State private var cardToDelete: UserCard?
    @State private var showDeleteConfirmation = false

    // Edit mode for drag-and-drop reordering (iOS only)
    #if os(iOS)
    @State private var editMode: EditMode = .inactive
    #endif

    // Separate active and closed cards (uses ViewModel's sorted order)
    private var activeCards: [UserCard] {
        let cards = viewModel.activeCards
        if searchText.isEmpty {
            return cards
        }
        return cards.filter { userCard in
            let card = feedService.card(for: userCard.cardId)
            let name = userCard.nickname ?? card?.name ?? userCard.cardId
            let issuer = card?.issuer.displayName ?? ""
            return name.localizedCaseInsensitiveContains(searchText) ||
                   issuer.localizedCaseInsensitiveContains(searchText)
        }
    }

    private var closedCards: [UserCard] {
        let cards = viewModel.closedCards
        if searchText.isEmpty {
            return cards
        }
        return cards.filter { userCard in
            let card = feedService.card(for: userCard.cardId)
            let name = userCard.nickname ?? card?.name ?? userCard.cardId
            let issuer = card?.issuer.displayName ?? ""
            return name.localizedCaseInsensitiveContains(searchText) ||
                   issuer.localizedCaseInsensitiveContains(searchText)
        }
    }

    var body: some View {
        List {
            // Page Header with Controls
            Section {
                pageHeader
                    .listRowInsets(EdgeInsets())
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
            }

            // Active Bonuses section
            if !viewModel.cardsWithActiveBonus.isEmpty {
                Section {
                    ForEach(viewModel.cardsWithActiveBonus) { userCard in
                        let card = feedService.card(for: userCard.cardId)
                        NavigationLink(value: userCard) {
                            BonusProgressRow(userCard: userCard, card: card)
                        }
                    }
                } header: {
                    Text("Active Bonuses")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(.primary)
                        .textCase(nil)
                }
            }

            // Active Cards section with drag-and-drop
            Section {
                if activeCards.isEmpty && searchText.isEmpty {
                    emptyStateView
                        .listRowInsets(EdgeInsets())
                        .listRowBackground(Color.clear)
                        .listRowSeparator(.hidden)
                } else if activeCards.isEmpty && !searchText.isEmpty {
                    noResultsView
                        .listRowInsets(EdgeInsets())
                        .listRowBackground(Color.clear)
                        .listRowSeparator(.hidden)
                } else {
                    ForEach(activeCards) { userCard in
                        let card = feedService.card(for: userCard.cardId)
                        NavigationLink(value: userCard) {
                            CardRow(userCard: userCard, card: card)
                        }
                        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                            Button(role: .destructive) {
                                cardToDelete = userCard
                                showDeleteConfirmation = true
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }

                            Button {
                                closeCard(userCard)
                            } label: {
                                Label("Close", systemImage: "xmark.circle")
                            }
                            .tint(.orange)
                        }
                        .contextMenu {
                            Button {
                                closeCard(userCard)
                            } label: {
                                Label("Close Card", systemImage: "xmark.circle")
                            }

                            Button(role: .destructive) {
                                cardToDelete = userCard
                                showDeleteConfirmation = true
                            } label: {
                                Label("Delete Card...", systemImage: "trash")
                            }
                        }
                    }
                    .onMove { from, to in
                        viewModel.moveActiveCards(from: from, to: to)
                    }
                }
            } header: {
                HStack {
                    Text("Active Cards (\(activeCards.count))")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(.primary)
                        .textCase(nil)
                    Spacer()
                    if !activeCards.isEmpty {
                        #if os(iOS)
                        EditButton()
                            .font(.system(size: 14))
                        #endif
                    }
                }
            }

            // Closed Cards section
            if !closedCards.isEmpty {
                Section {
                    ForEach(closedCards) { userCard in
                        let card = feedService.card(for: userCard.cardId)
                        NavigationLink(value: userCard) {
                            ClosedCardRow(userCard: userCard, card: card)
                        }
                        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                            Button(role: .destructive) {
                                cardToDelete = userCard
                                showDeleteConfirmation = true
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }

                            Button {
                                reopenCard(userCard)
                            } label: {
                                Label("Reopen", systemImage: "arrow.uturn.backward")
                            }
                            .tint(.blue)
                        }
                        .contextMenu {
                            Button {
                                reopenCard(userCard)
                            } label: {
                                Label("Reopen Card", systemImage: "arrow.uturn.backward")
                            }

                            Button(role: .destructive) {
                                cardToDelete = userCard
                                showDeleteConfirmation = true
                            } label: {
                                Label("Delete Card...", systemImage: "trash")
                            }
                        }
                    }
                    .onMove { from, to in
                        viewModel.moveClosedCards(from: from, to: to)
                    }
                } header: {
                    Text("Closed Cards (\(closedCards.count))")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(.secondary)
                        .textCase(nil)
                }
            }
        }
        #if os(iOS)
        .listStyle(.insetGrouped)
        .environment(\.editMode, $editMode)
        #else
        .listStyle(.inset)
        #endif
        .navigationTitle("Cards")
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
        .navigationDestination(for: UserCard.self) { userCard in
            CardDetailView(userCard: userCard)
        }
        .sheet(isPresented: $showAddCard) {
            AddCardView()
        }
        .confirmationDialog(
            deleteDialogTitle,
            isPresented: $showDeleteConfirmation,
            titleVisibility: .visible
        ) {
            Button("Delete", role: .destructive) {
                if let card = cardToDelete {
                    viewModel.deleteCard(card)
                    cardToDelete = nil
                }
            }
            Button("Cancel", role: .cancel) {
                cardToDelete = nil
            }
        } message: {
            Text("This will permanently remove this card and all associated data. This cannot be undone.")
        }
    }

    // MARK: - Delete Dialog

    private var deleteDialogTitle: String {
        if let userCard = cardToDelete {
            let cardName = userCard.nickname ?? feedService.card(for: userCard.cardId)?.name ?? "this card"
            return "Delete \"\(cardName)\"?"
        }
        return "Delete Card?"
    }

    // MARK: - Page Header (Search + Add Card controls)

    private var pageHeader: some View {
        HStack(spacing: 16) {
            // Search field
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.secondary)
                    .font(.system(size: 14))

                TextField("Search cards...", text: $searchText)
                    .font(.system(size: 15))
                    .textFieldStyle(.plain)

                if !searchText.isEmpty {
                    Button {
                        searchText = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.tertiary)
                            .font(.system(size: 14))
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(searchFieldBackground)
            .cornerRadius(8)
            #if os(macOS)
            .frame(maxWidth: 300)
            #endif

            Spacer()

            // Add Card button
            Button {
                showAddCard = true
            } label: {
                Label("Add Card", systemImage: "plus")
                    .font(.system(size: 15, weight: .medium))
            }
            .buttonStyle(.borderedProminent)
            #if os(iOS)
            .controlSize(.large)
            #else
            .controlSize(.large)
            #endif
        }
        .padding(.vertical, 8)
    }

    // MARK: - Empty States

    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "creditcard.trianglebadge.exclamationmark")
                .font(.system(size: 48))
                .foregroundStyle(.tertiary)

            Text("No Cards Yet")
                .font(.system(size: 20, weight: .semibold))

            Text("Add your first credit card to start tracking rewards, bonuses, and benefits.")
                .font(.system(size: 15))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 300)

            Button {
                showAddCard = true
            } label: {
                Label("Add Your First Card", systemImage: "plus")
                    .font(.system(size: 15, weight: .medium))
            }
            .buttonStyle(.borderedProminent)
            .padding(.top, 8)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 60)
        .padding(.horizontal, 24)
    }

    private var noResultsView: some View {
        VStack(spacing: 12) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 32))
                .foregroundStyle(.tertiary)

            Text("No Results")
                .font(.system(size: 17, weight: .medium))

            Text("No cards match \"\(searchText)\"")
                .font(.system(size: 15))
                .foregroundStyle(.secondary)

            Button("Clear Search") {
                searchText = ""
            }
            .font(.system(size: 14))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }

    // MARK: - Helpers

    private var searchFieldBackground: Color {
        #if os(iOS)
        return Color(.tertiarySystemBackground)
        #else
        return Color(nsColor: .textBackgroundColor).opacity(0.5)
        #endif
    }

    private func closeCard(_ userCard: UserCard) {
        var updated = userCard
        updated.closedDate = Date()
        viewModel.updateCard(updated)
    }

    private func reopenCard(_ userCard: UserCard) {
        var updated = userCard
        updated.closedDate = nil
        viewModel.updateCard(updated)
    }
}

// MARK: - Card Row

struct CardRow: View {
    let userCard: UserCard
    let card: CreditCard?

    /// Determines if the card background is light (needs dark text)
    private var isLightBackground: Bool {
        guard let firstColor = cardGradientColors.first else { return false }
        return firstColor.isLight
    }

    /// Text color for card abbreviation based on background luminance
    private var cardTextColor: Color {
        isLightBackground ? .black : .white
    }

    /// Returns the effective annual fee (user override or catalog value)
    private var effectiveAnnualFee: Int {
        userCard.annualFeeOverride ?? card?.annualFee ?? 0
    }

    var body: some View {
        HStack(spacing: 12) {
            // Mini card visual with gradient
            RoundedRectangle(cornerRadius: 8)
                .fill(
                    LinearGradient(
                        colors: cardGradientColors,
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 64, height: 40)
                .shadow(color: .black.opacity(0.15), radius: 4, x: 0, y: 2)
                .overlay {
                    // Show issuer abbreviation or network
                    Text(issuerAbbreviation)
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(cardTextColor)
                }

            VStack(alignment: .leading, spacing: 4) {
                Text(userCard.nickname ?? card?.name ?? "Custom Card")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(.primary)

                Text(card?.issuer.displayName ?? "Custom")
                    .font(.system(size: 13))
                    .foregroundStyle(.secondary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                if effectiveAnnualFee > 0 {
                    Text(effectiveAnnualFee.currencyFormatted)
                        .font(.system(size: 13))
                        .foregroundStyle(.secondary)
                } else {
                    Text("No AF")
                        .font(.system(size: 13))
                        .foregroundStyle(.green)
                }
                if let last4 = userCard.lastFourDigits {
                    Text("•••• \(last4)")
                        .font(.system(size: 12))
                        .foregroundStyle(.tertiary)
                }
            }
            // NavigationLink provides its own disclosure indicator
        }
        .frame(minHeight: 64)
        .padding(.vertical, 8)
    }

    private var issuerAbbreviation: String {
        if let card = card {
            return card.issuer.abbreviation
        }
        return "CUST"
    }

    private var cardGradientColors: [Color] {
        guard let card = card else {
            // Custom card - neutral gray
            return [Color(hex: "6B7280"), Color(hex: "4B5563")]
        }
        return issuerGradient(card.issuer, cardName: card.name)
    }
}

// MARK: - Closed Card Row

struct ClosedCardRow: View {
    let userCard: UserCard
    let card: CreditCard?

    var body: some View {
        HStack(spacing: 12) {
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.gray.opacity(0.4))
                .frame(width: 64, height: 40)
                .overlay {
                    Image(systemName: "xmark")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(.white)
                }

            VStack(alignment: .leading, spacing: 4) {
                Text(userCard.nickname ?? card?.name ?? "Custom Card")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(.secondary)
                HStack(spacing: 4) {
                    Text(card?.issuer.displayName ?? "Custom")
                        .font(.system(size: 13))
                        .foregroundStyle(.tertiary)
                    if let closedDate = userCard.closedDate {
                        Text("• Closed \(closedDate.shortFormatted)")
                            .font(.system(size: 13))
                            .foregroundStyle(.tertiary)
                    }
                }
            }

            Spacer()

            // Show rechurn eligibility if available
            if let closedDate = userCard.closedDate {
                let monthsSinceClosed = Calendar.current.dateComponents([.month], from: closedDate, to: Date()).month ?? 0
                if monthsSinceClosed >= 48 {
                    Text("Rechurn Ready")
                        .font(.system(size: 12, weight: .semibold))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.green.opacity(0.2))
                        .foregroundStyle(.green)
                        .clipShape(RoundedRectangle(cornerRadius: 4))
                } else {
                    Text("\(48 - monthsSinceClosed)mo")
                        .font(.system(size: 13))
                        .foregroundStyle(.orange)
                }
            }
            // NavigationLink provides its own disclosure indicator
        }
        .frame(minHeight: 64)
        .padding(.vertical, 8)
    }
}

// MARK: - Bonus Progress Row

struct BonusProgressRow: View {
    let userCard: UserCard
    let card: CreditCard?

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(userCard.nickname ?? card?.name ?? "Custom Card")
                    .font(.system(size: 15, weight: .medium))
                Spacer()
                if let bonus = userCard.signupBonusProgress {
                    Text("\(bonus.daysRemaining)d left")
                        .font(.system(size: 13))
                        .foregroundStyle(bonus.daysRemaining < 30 ? .red : .secondary)
                }
            }

            if let bonus = userCard.signupBonusProgress {
                ProgressView(value: bonus.progress)
                    .tint(bonus.progress >= 1.0 ? .green : .blue)

                HStack {
                    Text("$\(bonus.spentSoFar) / $\(bonus.targetSpend)")
                        .font(.system(size: 13))
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text("\(Int(bonus.progress * 100))%")
                        .font(.system(size: 13, weight: .semibold))
                }
            }
        }
        .frame(minHeight: 52)
        .padding(.vertical, 8)
    }
}

// MARK: - Issuer Gradient Function (Updated for 25+ issuers)

private func issuerGradient(_ issuer: Issuer, cardName: String) -> [Color] {
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
        } else if nameLower.contains("hyatt") {
            return [Color(hex: "93328E"), Color(hex: "6a2468")]
        } else if nameLower.contains("ihg") {
            return [Color(hex: "00685B"), Color(hex: "004d44")]
        } else if nameLower.contains("marriott") {
            return [Color(hex: "821B3C"), Color(hex: "5e132a")]
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
        } else if nameLower.contains("blue cash") {
            return [Color(hex: "2E5A88"), Color(hex: "4682B4")]
        } else if nameLower.contains("delta") {
            return [Color(hex: "003366"), Color(hex: "00509E")]
        } else if nameLower.contains("hilton") {
            return [Color(hex: "002E5D"), Color(hex: "00508F")]
        } else {
            return [Color(hex: "006FCF"), Color(hex: "00A1E4")]
        }

    case .citi:
        if nameLower.contains("double cash") {
            return [Color(hex: "2F4F4F"), Color(hex: "4a6b6b")]
        } else if nameLower.contains("premier") || nameLower.contains("strata") {
            return [Color(hex: "003B70"), Color(hex: "0066b2")]
        } else if nameLower.contains("custom cash") {
            return [Color(hex: "004080"), Color(hex: "0066cc")]
        } else {
            return [Color(hex: "003B70"), Color(hex: "0066b2")]
        }

    case .capitalOne:
        if nameLower.contains("venture x") {
            return [Color(hex: "1a1a1a"), Color(hex: "333333")]
        } else if nameLower.contains("quicksilver") {
            return [Color(hex: "004977"), Color(hex: "00325a")]
        } else if nameLower.contains("savor") {
            return [Color(hex: "6B3A5B"), Color(hex: "8B4573")]
        } else {
            return [Color(hex: "D03027"), Color(hex: "a02620")]
        }

    case .bankOfAmerica:
        if nameLower.contains("premium") || nameLower.contains("elite") {
            return [Color(hex: "1a1a1a"), Color(hex: "4a4a4a")]
        } else if nameLower.contains("alaska") {
            return [Color(hex: "004C97"), Color(hex: "003366")]
        } else {
            return [Color(hex: "E31837"), Color(hex: "a31228")]
        }

    case .wellsFargo:
        if nameLower.contains("autograph") {
            return [Color(hex: "1a1a1a"), Color(hex: "333333")]
        } else if nameLower.contains("active cash") {
            return [Color(hex: "CD1409"), Color(hex: "9a0f07")]
        } else {
            return [Color(hex: "CD1409"), Color(hex: "9a0f07")]
        }

    case .usBank:
        if nameLower.contains("altitude reserve") {
            return [Color(hex: "1a1a1a"), Color(hex: "333333")]
        } else if nameLower.contains("altitude") {
            return [Color(hex: "004C97"), Color(hex: "003366")]
        } else {
            return [Color(hex: "D71E28"), Color(hex: "a3171e")]
        }

    case .barclays:
        if nameLower.contains("jetblue") {
            return [Color(hex: "003876"), Color(hex: "0055A5")]
        } else if nameLower.contains("wyndham") {
            return [Color(hex: "0072CE"), Color(hex: "0055A5")]
        } else if nameLower.contains("luxury") {
            return [Color(hex: "1a1a1a"), Color(hex: "333333")]
        } else {
            return [Color(hex: "00AEEF"), Color(hex: "0088cc")]
        }

    case .discover:
        if nameLower.contains("miles") {
            return [Color(hex: "E85D04"), Color(hex: "ff8533")]
        } else {
            return [Color(hex: "FF6600"), Color(hex: "ff8533")]
        }

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

#Preview {
    NavigationStack {
        CardListView()
    }
    .environment(CardViewModel())
    .environment(DataFeedService())
}
