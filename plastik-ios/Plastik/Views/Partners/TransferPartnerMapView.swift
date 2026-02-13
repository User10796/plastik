import SwiftUI

struct TransferPartnerMapView: View {
    @Environment(DataFeedService.self) private var feedService
    @Environment(CardViewModel.self) private var cardViewModel

    @State private var selectedProgram: String?
    @State private var selectedType: PartnerType?
    @State private var searchText = ""
    @State private var viewMode: ViewMode = .partners

    enum ViewMode: String, CaseIterable {
        case partners = "Partners"
        case routes = "Routes"
    }

    private var programs: [(id: String, name: String)] {
        if !feedService.pointsCurrencies.isEmpty {
            return feedService.pointsCurrencies.map { ($0.id, $0.name) }
        }
        return [
            ("chase-ur", "Chase Ultimate Rewards"),
            ("amex-mr", "Amex Membership Rewards"),
            ("citi-typ", "Citi ThankYou Points"),
            ("capital-one", "Capital One Miles")
        ]
    }

    private var userPrograms: Set<String> {
        var progs = Set<String>()
        for userCard in cardViewModel.userCards {
            if let card = feedService.card(for: userCard.cardId) {
                for partner in feedService.partners(for: card) {
                    for prog in (partner.fromPrograms ?? []) {
                        progs.insert(prog)
                    }
                }
            }
        }
        // Also check pointsCurrencies
        for currency in feedService.pointsCurrencies {
            if cardViewModel.userCards.contains(where: { currency.earnedWith.contains($0.cardId) }) {
                progs.insert(currency.id)
            }
        }
        return progs
    }

    private var filteredPartners: [TransferPartner] {
        var partners = feedService.transferPartners

        if let program = selectedProgram {
            partners = partners.filter { ($0.fromPrograms ?? []).contains(program) }
            // Also include partners reachable via routes
            let routePartnerIds = Set(feedService.routes(for: program).map(\.toPartner))
            let routePartners = feedService.transferPartners.filter { routePartnerIds.contains($0.id) }
            partners = Array(Set(partners + routePartners))
        }

        if let type = selectedType {
            partners = partners.filter { $0.type == type }
        }

        if !searchText.isEmpty {
            partners = partners.filter {
                $0.name.localizedCaseInsensitiveContains(searchText)
            }
        }

        return partners.sorted { $0.name < $1.name }
    }

    var body: some View {
        ScrollView {
            // Section 4: Max-width container centered
            VStack(alignment: .leading, spacing: 24) {
                // Page Header
                pageHeader

                // View mode picker (if routes available)
                if !feedService.transferRoutes.isEmpty {
                    viewModePicker
                }

                // Program Filter Section (Section 5: Improved buttons)
                programFilterSection

                // Type Filter Section
                typeFilterSection

                // Content based on view mode
                switch viewMode {
                case .partners:
                    partnersListSection
                case .routes:
                    routesListSection
                }
            }
            .padding(24)
            .frame(maxWidth: 1200) // Section 4: Max-width
            .frame(maxWidth: .infinity) // Center the container
        }
        .navigationTitle("Transfer Partners")
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
    }

    // MARK: - Page Header

    private var pageHeader: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Transfer Partners")
                .font(.system(size: 24, weight: .semibold))

            // Search bar
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.secondary)
                    .font(.system(size: 14))

                TextField("Search partners...", text: $searchText)
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
            .frame(maxWidth: 400)
            #endif
        }
    }

    // MARK: - View Mode Picker

    private var viewModePicker: some View {
        Picker("View", selection: $viewMode) {
            ForEach(ViewMode.allCases, id: \.self) { mode in
                Text(mode.rawValue).tag(mode)
            }
        }
        .pickerStyle(.segmented)
        #if os(macOS)
        .frame(maxWidth: 200)
        #endif
    }

    // MARK: - Program Filter (Section 5: Improved buttons)

    private var programFilterSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Filter by Program")
                .font(.system(size: 17, weight: .semibold))

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ImprovedFilterChip(
                        label: "All Programs",
                        isSelected: selectedProgram == nil,
                        action: { selectedProgram = nil }
                    )
                    ForEach(programs, id: \.id) { prog in
                        ImprovedFilterChip(
                            label: prog.name,
                            isSelected: selectedProgram == prog.id,
                            showCheckmark: userPrograms.contains(prog.id),
                            action: { selectedProgram = prog.id }
                        )
                    }
                }
            }
        }
    }

    // MARK: - Type Filter

    private var typeFilterSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Partner Type")
                .font(.system(size: 17, weight: .semibold))

            HStack(spacing: 12) {
                ImprovedTypeFilterButton(
                    label: "All",
                    icon: "globe",
                    isSelected: selectedType == nil,
                    action: { selectedType = nil }
                )
                ImprovedTypeFilterButton(
                    label: "Airlines",
                    icon: "airplane",
                    isSelected: selectedType == .airline,
                    action: { selectedType = .airline }
                )
                ImprovedTypeFilterButton(
                    label: "Hotels",
                    icon: "building.2.fill",
                    isSelected: selectedType == .hotel,
                    action: { selectedType = .hotel }
                )

                Spacer()
            }
        }
    }

    // MARK: - Partners List

    private var partnersListSection: some View {
        let airlines = filteredPartners.filter { $0.type == .airline }
        let hotels = filteredPartners.filter { $0.type == .hotel }

        return VStack(alignment: .leading, spacing: 24) {
            if selectedType == nil || selectedType == .airline {
                if !airlines.isEmpty {
                    partnerSection(title: "Airlines", count: airlines.count, partners: airlines)
                }
            }

            if selectedType == nil || selectedType == .hotel {
                if !hotels.isEmpty {
                    partnerSection(title: "Hotels", count: hotels.count, partners: hotels)
                }
            }

            if filteredPartners.isEmpty {
                emptyStateView
            }
        }
    }

    private func partnerSection(title: String, count: Int, partners: [TransferPartner]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("\(title) (\(count))")
                .font(.system(size: 17, weight: .semibold))

            VStack(spacing: 0) {
                ForEach(partners) { partner in
                    ImprovedTransferPartnerRow(
                        partner: partner,
                        userPrograms: userPrograms,
                        routes: feedService.routes(to: partner.id)
                    )

                    if partner.id != partners.last?.id {
                        Divider()
                    }
                }
            }
            .padding(16)
            .background(cardBackgroundColor)
            .cornerRadius(12)
        }
    }

    // MARK: - Routes List

    private var routesForCurrentFilter: [TransferRoute] {
        if let program = selectedProgram {
            return feedService.routes(for: program)
        } else {
            return feedService.transferRoutes
        }
    }

    private var routesListSection: some View {
        let filtered = routesForCurrentFilter.filter { route in
            if let type = selectedType {
                guard let partner = feedService.transferPartners.first(where: { $0.id == route.toPartner }) else { return false }
                return partner.type == type
            }
            return true
        }.filter { route in
            if searchText.isEmpty { return true }
            let partner = feedService.transferPartners.first { $0.id == route.toPartner }
            return partner?.name.localizedCaseInsensitiveContains(searchText) ?? false
        }

        return VStack(alignment: .leading, spacing: 24) {
            if !filtered.isEmpty {
                // Group by from currency
                let grouped = Dictionary(grouping: filtered) { $0.fromCurrency }
                ForEach(grouped.keys.sorted(), id: \.self) { currencyId in
                    let currencyName = feedService.currency(for: currencyId)?.shortName ?? currencyId
                    routeSection(title: "\(currencyName) Routes", routes: grouped[currencyId] ?? [])
                }

                // Active bonuses
                let activeBonus = filtered.filter { $0.transferBonus?.isActive == true }
                if !activeBonus.isEmpty {
                    activeBonusSection(routes: activeBonus)
                }
            } else {
                emptyRoutesView
            }
        }
    }

    private func routeSection(title: String, routes: [TransferRoute]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.system(size: 17, weight: .semibold))

            VStack(spacing: 0) {
                ForEach(routes.sorted { $0.ratio > $1.ratio }) { route in
                    ImprovedTransferRouteRow(route: route, feedService: feedService, userPrograms: userPrograms)

                    if route.id != routes.sorted(by: { $0.ratio > $1.ratio }).last?.id {
                        Divider()
                    }
                }
            }
            .padding(16)
            .background(cardBackgroundColor)
            .cornerRadius(12)
        }
    }

    private func activeBonusSection(routes: [TransferRoute]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "star.fill")
                    .foregroundStyle(.yellow)
                Text("Active Bonus Transfers")
                    .font(.system(size: 17, weight: .semibold))
            }

            VStack(spacing: 0) {
                ForEach(routes) { route in
                    if let bonus = route.transferBonus,
                       let partner = feedService.transferPartners.first(where: { $0.id == route.toPartner }) {
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Image(systemName: "star.fill")
                                    .foregroundStyle(.yellow)
                                    .font(.system(size: 14))
                                Text(partner.name)
                                    .font(.system(size: 15, weight: .semibold))
                                Spacer()
                                Text("+\(bonus.bonusPercent)%")
                                    .font(.system(size: 17, weight: .bold))
                                    .foregroundStyle(.green)
                            }
                            Text(bonus.description)
                                .font(.system(size: 13))
                                .foregroundStyle(.secondary)
                            Text("Until \(bonus.endDate.shortFormatted)")
                                .font(.system(size: 12))
                                .foregroundStyle(.orange)
                        }
                        .padding(.vertical, 12)

                        if route.id != routes.last?.id {
                            Divider()
                        }
                    }
                }
            }
            .padding(16)
            .background(Color.yellow.opacity(0.08))
            .cornerRadius(12)
        }
    }

    // MARK: - Empty States

    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "airplane.circle")
                .font(.system(size: 48))
                .foregroundStyle(.tertiary)

            Text("No Partners Found")
                .font(.system(size: 20, weight: .semibold))

            Text("No transfer partners match your filters.")
                .font(.system(size: 15))
                .foregroundStyle(.secondary)

            if selectedProgram != nil || selectedType != nil {
                Button("Clear Filters") {
                    selectedProgram = nil
                    selectedType = nil
                    searchText = ""
                }
                .buttonStyle(.bordered)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 60)
        .background(cardBackgroundColor)
        .cornerRadius(12)
    }

    private var emptyRoutesView: some View {
        VStack(spacing: 16) {
            Image(systemName: "arrow.triangle.swap")
                .font(.system(size: 48))
                .foregroundStyle(.tertiary)

            Text("No Routes Available")
                .font(.system(size: 20, weight: .semibold))

            Text("No transfer routes in the data feed yet.")
                .font(.system(size: 15))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 60)
        .background(cardBackgroundColor)
        .cornerRadius(12)
    }

    // MARK: - Helpers

    private var cardBackgroundColor: Color {
        #if os(iOS)
        return Color(.secondarySystemBackground)
        #else
        return Color(nsColor: .controlBackgroundColor)
        #endif
    }

    private var searchFieldBackground: Color {
        #if os(iOS)
        return Color(.tertiarySystemBackground)
        #else
        return Color(nsColor: .textBackgroundColor).opacity(0.5)
        #endif
    }
}

// MARK: - Improved Filter Chip (Section 5)

struct ImprovedFilterChip: View {
    let label: String
    let isSelected: Bool
    var showCheckmark: Bool = false
    let action: () -> Void

    private var pillBackground: Color {
        #if os(iOS)
        return Color(.tertiarySystemBackground)
        #else
        return Color(nsColor: .controlBackgroundColor)
        #endif
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                Text(label)
                    .font(.system(size: 14, weight: .medium)) // Section 5: Minimum 14px
                if showCheckmark {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 12))
                        .foregroundStyle(.green)
                }
            }
            .padding(.horizontal, 12) // Section 5: 8px+ horizontal
            .padding(.vertical, 12) // iOS: Increased for 44px touch target
            .frame(minHeight: 44) // iOS accessibility: 44px minimum touch target
            .background(isSelected ? Color.accentColor : pillBackground)
            .foregroundStyle(isSelected ? Color.white : Color.primary)
            .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Improved Type Filter Button (Section 5)

struct ImprovedTypeFilterButton: View {
    let label: String
    let icon: String
    let isSelected: Bool
    let action: () -> Void

    private var buttonBackground: Color {
        #if os(iOS)
        return Color(.tertiarySystemBackground)
        #else
        return Color(nsColor: .controlBackgroundColor)
        #endif
    }

    private var selectedBackground: Color {
        Color.accentColor.opacity(0.15)
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 16))
                Text(label)
                    .font(.system(size: 14, weight: .medium)) // Section 5: Minimum 14px
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12) // iOS: Increased for 44px touch target
            .frame(minHeight: 44) // iOS accessibility: 44px minimum touch target
            .background(isSelected ? selectedBackground : buttonBackground)
            .foregroundStyle(isSelected ? Color.accentColor : Color.primary)
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(isSelected ? Color.accentColor : Color.clear, lineWidth: 1.5)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Improved Partner Row (Section 4: Compact layout)

struct ImprovedTransferPartnerRow: View {
    let partner: TransferPartner
    let userPrograms: Set<String>
    let routes: [TransferRoute]

    private var availableViaUserCards: Bool {
        (partner.fromPrograms ?? []).contains { userPrograms.contains($0) } ||
        routes.contains { userPrograms.contains($0.fromCurrency) }
    }

    var body: some View {
        HStack(spacing: 16) {
            // Icon
            Image(systemName: partner.type.icon)
                .font(.system(size: 20))
                .foregroundStyle(partner.type == .airline ? .blue : .purple)
                .frame(width: 32)

            // Partner info
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text(partner.name)
                        .font(.system(size: 15, weight: .medium))
                    if let alliance = partner.alliance {
                        Text(alliance)
                            .font(.system(size: 11))
                            .padding(.horizontal, 5)
                            .padding(.vertical, 2)
                            .background(Color.secondary.opacity(0.15))
                            .clipShape(RoundedRectangle(cornerRadius: 4))
                    }
                }

                // Programs row
                let progs = partner.fromPrograms ?? []
                if !progs.isEmpty {
                    HStack(spacing: 4) {
                        ForEach(progs, id: \.self) { prog in
                            Text(programShortName(prog))
                                .font(.system(size: 11))
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(
                                    userPrograms.contains(prog)
                                        ? Color.blue.opacity(0.15)
                                        : Color.gray.opacity(0.1)
                                )
                                .foregroundStyle(userPrograms.contains(prog) ? .blue : .secondary)
                                .clipShape(RoundedRectangle(cornerRadius: 4))
                        }
                    }
                } else if !routes.isEmpty {
                    HStack(spacing: 4) {
                        ForEach(routes.prefix(3)) { route in
                            Text(programShortName(route.fromCurrency))
                                .font(.system(size: 11))
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(
                                    userPrograms.contains(route.fromCurrency)
                                        ? Color.blue.opacity(0.15)
                                        : Color.gray.opacity(0.1)
                                )
                                .foregroundStyle(userPrograms.contains(route.fromCurrency) ? .blue : .secondary)
                                .clipShape(RoundedRectangle(cornerRadius: 4))
                        }
                    }
                }
            }

            Spacer()

            // Ratio and status
            VStack(alignment: .trailing, spacing: 4) {
                if let ratio = partner.transferRatio {
                    ImprovedRatioView(ratio: ratio)
                } else if let bestRoute = routes.max(by: { $0.ratio < $1.ratio }) {
                    ImprovedRatioView(ratio: bestRoute.ratio)
                }

                if availableViaUserCards {
                    Text("Available")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(.green)
                }
            }

            // Active bonus indicator
            if let activeBonus = routes.first(where: { $0.transferBonus?.isActive == true })?.transferBonus {
                VStack(spacing: 2) {
                    Image(systemName: "star.fill")
                        .font(.system(size: 12))
                        .foregroundStyle(.yellow)
                    Text("+\(activeBonus.bonusPercent)%")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(.green)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.yellow.opacity(0.15))
                .clipShape(RoundedRectangle(cornerRadius: 6))
            }
        }
        .padding(.vertical, 12)
    }

    private func programShortName(_ id: String) -> String {
        switch id {
        case "chase-ur": return "Chase UR"
        case "amex-mr": return "Amex MR"
        case "citi-typ": return "Citi TYP"
        case "capital-one": return "Cap One"
        default: return id
        }
    }
}

// MARK: - Improved Route Row

struct ImprovedTransferRouteRow: View {
    let route: TransferRoute
    let feedService: DataFeedService
    let userPrograms: Set<String>

    private var partner: TransferPartner? {
        feedService.transferPartners.first { $0.id == route.toPartner }
    }

    var body: some View {
        if let partner {
            HStack(spacing: 16) {
                Image(systemName: partner.type.icon)
                    .font(.system(size: 18))
                    .foregroundStyle(.blue)
                    .frame(width: 24)

                VStack(alignment: .leading, spacing: 4) {
                    Text(partner.name)
                        .font(.system(size: 15, weight: .medium))

                    HStack(spacing: 12) {
                        Label(route.transferTime.displayName, systemImage: "clock")
                            .font(.system(size: 12))
                            .foregroundStyle(.secondary)
                        if route.minimumTransfer > 0 {
                            Text("Min: \(route.minimumTransfer)")
                                .font(.system(size: 12))
                                .foregroundStyle(.secondary)
                        }
                    }
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 4) {
                    ImprovedRatioView(ratio: route.ratio)
                    if let bonus = route.transferBonus, bonus.isActive {
                        Text("+\(bonus.bonusPercent)%")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(.green)
                    }
                }
            }
            .padding(.vertical, 12)
        }
    }
}

// MARK: - Improved Ratio View

struct ImprovedRatioView: View {
    let ratio: Double

    var body: some View {
        HStack(spacing: 2) {
            Text("\(ratio == 1.0 ? "1" : String(format: "%.1f", ratio))")
                .font(.system(size: 17, weight: .bold))
            Text(": 1")
                .font(.system(size: 13))
                .foregroundStyle(.secondary)
        }
    }
}

// Keep old types for backwards compatibility with other files
struct TypeFilterButton: View {
    let label: String
    let icon: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        ImprovedTypeFilterButton(label: label, icon: icon, isSelected: isSelected, action: action)
    }
}

struct TransferPartnerRow: View {
    let partner: TransferPartner
    let userPrograms: Set<String>
    let routes: [TransferRoute]

    var body: some View {
        ImprovedTransferPartnerRow(partner: partner, userPrograms: userPrograms, routes: routes)
    }
}

struct TransferRouteRow: View {
    let route: TransferRoute
    let feedService: DataFeedService
    let userPrograms: Set<String>

    var body: some View {
        ImprovedTransferRouteRow(route: route, feedService: feedService, userPrograms: userPrograms)
    }
}

struct RatioView: View {
    let ratio: Double

    var body: some View {
        ImprovedRatioView(ratio: ratio)
    }
}
