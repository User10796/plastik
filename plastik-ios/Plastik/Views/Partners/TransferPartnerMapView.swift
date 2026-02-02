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
        List {
            if !feedService.transferRoutes.isEmpty {
                Section {
                    Picker("View", selection: $viewMode) {
                        ForEach(ViewMode.allCases, id: \.self) { mode in
                            Text(mode.rawValue).tag(mode)
                        }
                    }
                    .pickerStyle(.segmented)
                }
            }

            programFilterSection
            typeFilterSection

            switch viewMode {
            case .partners:
                partnersListSection
            case .routes:
                routesListSection
            }
        }
        .searchable(text: $searchText, prompt: "Search partners")
        .navigationTitle("Transfer Partners")
    }

    // MARK: - Program Filter

    @ViewBuilder
    private var programFilterSection: some View {
        Section {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    FilterChip(
                        label: "All Programs",
                        isSelected: selectedProgram == nil,
                        action: { selectedProgram = nil }
                    )
                    ForEach(programs, id: \.id) { prog in
                        HStack(spacing: 4) {
                            FilterChip(
                                label: prog.name,
                                isSelected: selectedProgram == prog.id,
                                action: { selectedProgram = prog.id }
                            )
                            if userPrograms.contains(prog.id) {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.caption2)
                                    .foregroundStyle(.green)
                            }
                        }
                    }
                }
            }
        }
    }

    // MARK: - Type Filter

    @ViewBuilder
    private var typeFilterSection: some View {
        Section {
            HStack(spacing: 12) {
                TypeFilterButton(
                    label: "All",
                    icon: "globe",
                    isSelected: selectedType == nil,
                    action: { selectedType = nil }
                )
                TypeFilterButton(
                    label: "Airlines",
                    icon: "airplane",
                    isSelected: selectedType == .airline,
                    action: { selectedType = .airline }
                )
                TypeFilterButton(
                    label: "Hotels",
                    icon: "building.2.fill",
                    isSelected: selectedType == .hotel,
                    action: { selectedType = .hotel }
                )
            }
        }
    }

    // MARK: - Partners List

    @ViewBuilder
    private var partnersListSection: some View {
        let airlines = filteredPartners.filter { $0.type == .airline }
        let hotels = filteredPartners.filter { $0.type == .hotel }

        if selectedType == nil || selectedType == .airline {
            if !airlines.isEmpty {
                Section("Airlines (\(airlines.count))") {
                    ForEach(airlines) { partner in
                        TransferPartnerRow(
                            partner: partner,
                            userPrograms: userPrograms,
                            routes: feedService.routes(to: partner.id)
                        )
                    }
                }
            }
        }

        if selectedType == nil || selectedType == .hotel {
            if !hotels.isEmpty {
                Section("Hotels (\(hotels.count))") {
                    ForEach(hotels) { partner in
                        TransferPartnerRow(
                            partner: partner,
                            userPrograms: userPrograms,
                            routes: feedService.routes(to: partner.id)
                        )
                    }
                }
            }
        }

        if filteredPartners.isEmpty {
            ContentUnavailableView(
                "No Partners Found",
                systemImage: "airplane.circle",
                description: Text("No transfer partners match your filters.")
            )
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

    @ViewBuilder
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

        if !filtered.isEmpty {
            // Group by from currency
            let grouped = Dictionary(grouping: filtered) { $0.fromCurrency }
            ForEach(grouped.keys.sorted(), id: \.self) { currencyId in
                let currencyName = feedService.currency(for: currencyId)?.shortName ?? currencyId
                Section("\(currencyName) Routes") {
                    ForEach((grouped[currencyId] ?? []).sorted { $0.ratio > $1.ratio }) { route in
                        TransferRouteRow(route: route, feedService: feedService, userPrograms: userPrograms)
                    }
                }
            }

            // Active bonuses
            let activeBonus = filtered.filter { $0.transferBonus?.isActive == true }
            if !activeBonus.isEmpty {
                Section("Active Bonus Transfers") {
                    ForEach(activeBonus) { route in
                        if let bonus = route.transferBonus,
                           let partner = feedService.transferPartners.first(where: { $0.id == route.toPartner }) {
                            VStack(alignment: .leading, spacing: 4) {
                                HStack {
                                    Image(systemName: "star.fill")
                                        .foregroundStyle(.yellow)
                                    Text(partner.name)
                                        .font(.subheadline.bold())
                                    Spacer()
                                    Text("+\(bonus.bonusPercent)%")
                                        .font(.headline.bold())
                                        .foregroundStyle(.green)
                                }
                                Text(bonus.description)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                Text("Until \(bonus.endDate.shortFormatted)")
                                    .font(.caption2)
                                    .foregroundStyle(.orange)
                            }
                        }
                    }
                }
            }
        } else {
            ContentUnavailableView(
                "No Routes Available",
                systemImage: "arrow.triangle.swap",
                description: Text("No transfer routes in the data feed yet.")
            )
        }
    }
}

// MARK: - Partner Row

struct TransferPartnerRow: View {
    let partner: TransferPartner
    let userPrograms: Set<String>
    let routes: [TransferRoute]

    private var availableViaUserCards: Bool {
        (partner.fromPrograms ?? []).contains { userPrograms.contains($0) } ||
        routes.contains { userPrograms.contains($0.fromCurrency) }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Image(systemName: partner.type.icon)
                    .font(.title3)
                    .foregroundStyle(partner.type == .airline ? .blue : .purple)
                    .frame(width: 30)

                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 4) {
                        Text(partner.name)
                            .font(.headline)
                        if let alliance = partner.alliance {
                            Text(alliance)
                                .font(.caption2)
                                .padding(.horizontal, 4)
                                .padding(.vertical, 1)
                                .background(.secondary.opacity(0.1))
                                .clipShape(RoundedRectangle(cornerRadius: 3))
                        }
                    }
                    Text(partner.type.displayName)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 2) {
                    if let ratio = partner.transferRatio {
                        RatioView(ratio: ratio)
                    } else if let bestRoute = routes.max(by: { $0.ratio < $1.ratio }) {
                        RatioView(ratio: bestRoute.ratio)
                    }
                    if availableViaUserCards {
                        Text("Available")
                            .font(.caption2.bold())
                            .foregroundStyle(.green)
                    }
                }
            }

            // Programs / routes
            let progs = partner.fromPrograms ?? []
            if !progs.isEmpty {
                HStack(spacing: 6) {
                    ForEach(progs, id: \.self) { prog in
                        Text(programShortName(prog))
                            .font(.caption2)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(
                                userPrograms.contains(prog)
                                    ? AnyShapeStyle(.blue.opacity(0.15))
                                    : AnyShapeStyle(.gray.opacity(0.1))
                            )
                            .foregroundStyle(userPrograms.contains(prog) ? .blue : .secondary)
                            .clipShape(RoundedRectangle(cornerRadius: 4))
                    }
                }
            } else if !routes.isEmpty {
                HStack(spacing: 6) {
                    ForEach(routes) { route in
                        HStack(spacing: 2) {
                            Text(programShortName(route.fromCurrency))
                            if route.ratio != 1.0 {
                                Text("(\(String(format: "%.1f", route.ratio)):1)")
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .font(.caption2)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(
                            userPrograms.contains(route.fromCurrency)
                                ? AnyShapeStyle(.blue.opacity(0.15))
                                : AnyShapeStyle(.gray.opacity(0.1))
                        )
                        .foregroundStyle(userPrograms.contains(route.fromCurrency) ? .blue : .secondary)
                        .clipShape(RoundedRectangle(cornerRadius: 4))
                    }
                }
            }

            // Active transfer bonus indicator
            if let activeBonus = routes.first(where: { $0.transferBonus?.isActive == true })?.transferBonus {
                HStack(spacing: 4) {
                    Image(systemName: "star.fill")
                        .font(.caption2)
                        .foregroundStyle(.yellow)
                    Text("+\(activeBonus.bonusPercent)% bonus until \(activeBonus.endDate.shortFormatted)")
                        .font(.caption2)
                        .foregroundStyle(.green)
                }
            }
        }
        .padding(.vertical, 4)
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

// MARK: - Route Row

struct TransferRouteRow: View {
    let route: TransferRoute
    let feedService: DataFeedService
    let userPrograms: Set<String>

    private var partner: TransferPartner? {
        feedService.transferPartners.first { $0.id == route.toPartner }
    }

    var body: some View {
        if let partner {
            HStack {
                Image(systemName: partner.type.icon)
                    .frame(width: 20)
                    .foregroundStyle(.blue)

                VStack(alignment: .leading, spacing: 2) {
                    Text(partner.name)
                        .font(.subheadline)
                    HStack(spacing: 8) {
                        Label(route.transferTime.displayName, systemImage: "clock")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                        if route.minimumTransfer > 0 {
                            Text("Min: \(route.minimumTransfer)")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    }
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 2) {
                    RatioView(ratio: route.ratio)
                    if let bonus = route.transferBonus, bonus.isActive {
                        Text("+\(bonus.bonusPercent)%")
                            .font(.caption2.bold())
                            .foregroundStyle(.green)
                    }
                }
            }
        }
    }
}

// MARK: - Ratio View

struct RatioView: View {
    let ratio: Double

    var body: some View {
        HStack(spacing: 2) {
            Text("\(ratio == 1.0 ? "1" : String(format: "%.1f", ratio))")
                .font(.headline.bold())
            Text(": 1")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}

// MARK: - Type Filter Button

struct TypeFilterButton: View {
    let label: String
    let icon: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.title3)
                Text(label)
                    .font(.caption)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .background(isSelected ? AnyShapeStyle(.blue.opacity(0.15)) : AnyShapeStyle(.ultraThinMaterial))
            .foregroundStyle(isSelected ? .blue : .primary)
            .clipShape(RoundedRectangle(cornerRadius: 10))
        }
        .buttonStyle(.plain)
    }
}
