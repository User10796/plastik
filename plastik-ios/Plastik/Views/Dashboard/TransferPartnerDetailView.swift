import SwiftUI

struct TransferPartnerDetailView: View {
    @Environment(DataFeedService.self) private var feedService
    let partner: TransferPartner

    private var programURL: URL? {
        URL(string: partnerWebsite)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Header
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 12) {
                        Image(systemName: partner.type.icon)
                            .font(.system(size: 28))
                            .foregroundStyle(.blue)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(partner.name)
                                .font(.system(size: 22, weight: .bold))
                            Text(partner.type.displayName)
                                .font(.system(size: 15))
                                .foregroundStyle(.secondary)
                        }
                    }

                    if let alliance = partner.alliance, !alliance.isEmpty {
                        Label(alliance, systemImage: "globe")
                            .font(.system(size: 14))
                            .foregroundStyle(.secondary)
                    }
                }

                // Program Summary
                VStack(alignment: .leading, spacing: 8) {
                    Text("About the Program")
                        .font(.system(size: 17, weight: .semibold))
                    Text(partnerDescription)
                        .font(.system(size: 15))
                        .foregroundStyle(.secondary)
                }
                .padding(16)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(cardBackground)
                .clipShape(RoundedRectangle(cornerRadius: 12))

                // Transfer Routes
                let routes = feedService.transferRoutes.filter { $0.toPartner == partner.id }
                if !routes.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Transfer Options")
                            .font(.system(size: 17, weight: .semibold))

                        ForEach(routes) { route in
                            let currency = feedService.pointsCurrencies.first { $0.id == route.fromCurrency }
                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(currency?.name ?? route.fromCurrency)
                                        .font(.system(size: 15, weight: .medium))
                                    Text("Ratio: \(route.ratio, specifier: "%.0f"):1 · \(route.transferTime.displayName)")
                                        .font(.system(size: 13))
                                        .foregroundStyle(.secondary)
                                }
                                Spacer()
                                if let bonus = route.transferBonus, bonus.isActive {
                                    Text("+\(bonus.bonusPercent)%")
                                        .font(.system(size: 13, weight: .bold))
                                        .foregroundStyle(.green)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 4)
                                        .background(Color.green.opacity(0.15))
                                        .clipShape(RoundedRectangle(cornerRadius: 6))
                                }
                            }
                            .padding(.vertical, 4)
                            if route.id != routes.last?.id {
                                Divider()
                            }
                        }
                    }
                    .padding(16)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(cardBackground)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }

                // Partner Airlines (for alliances)
                if let partnerAirlines = partner.partnerAirlines, !partnerAirlines.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Partner Airlines")
                            .font(.system(size: 17, weight: .semibold))
                        Text("You can use \(partner.name) miles on these partner airlines:")
                            .font(.system(size: 13))
                            .foregroundStyle(.secondary)
                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 140))], spacing: 8) {
                            ForEach(partnerAirlines, id: \.self) { airline in
                                HStack(spacing: 6) {
                                    Image(systemName: "airplane")
                                        .font(.caption)
                                        .foregroundStyle(.blue)
                                    Text(airline)
                                        .font(.system(size: 13))
                                        .lineLimit(1)
                                }
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(.ultraThinMaterial)
                                .clipShape(RoundedRectangle(cornerRadius: 6))
                            }
                        }
                    }
                    .padding(16)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(cardBackground)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }

                // Website Link
                if let url = programURL {
                    Link(destination: url) {
                        HStack {
                            Image(systemName: "safari")
                                .font(.system(size: 16))
                            Text("Visit \(partner.name) Website")
                                .font(.system(size: 15, weight: .medium))
                            Spacer()
                            Image(systemName: "arrow.up.right")
                                .font(.system(size: 12))
                        }
                        .padding(16)
                        .background(cardBackground)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                }
            }
            .padding(24)
            .frame(maxWidth: 900)
            .frame(maxWidth: .infinity)
        }
        .navigationTitle(partner.name)
    }

    private var cardBackground: some ShapeStyle {
        #if os(macOS)
        return Color(nsColor: .controlBackgroundColor)
        #else
        return Color(uiColor: .secondarySystemGroupedBackground)
        #endif
    }

    // MARK: - Partner Data

    private var partnerDescription: String {
        let name = partner.name.lowercased()
        if name.contains("united") {
            return "United MileagePlus is the frequent flyer program of United Airlines. Earn and redeem miles for flights on United and its Star Alliance partners. Points transfer from Chase Ultimate Rewards and other programs."
        } else if name.contains("hyatt") {
            return "World of Hyatt rewards loyalty at Hyatt hotels and resorts worldwide. Known for excellent award value, especially at luxury properties. Points transfer 1:1 from Chase Ultimate Rewards."
        } else if name.contains("southwest") {
            return "Southwest Rapid Rewards offers flexible points for flights with no blackout dates. Earn 135,000 qualifying points in a calendar year to unlock the Companion Pass for free travel for a companion."
        } else if name.contains("british") || name.contains("avios") {
            return "British Airways Executive Club uses Avios points for flights on BA and oneworld partners. Avios are especially valuable for short-haul flights and off-peak redemptions."
        } else if name.contains("air france") || name.contains("klm") || name.contains("flying blue") {
            return "Flying Blue is the loyalty program of Air France and KLM. Members earn and spend Miles on flights with Air France, KLM, and SkyTeam partners. Regular promo rewards offer excellent value."
        } else if name.contains("marriott") || name.contains("bonvoy") {
            return "Marriott Bonvoy is one of the largest hotel loyalty programs with 30+ brands worldwide. Points can be redeemed for free nights or transferred to 40+ airline partners."
        } else if name.contains("hilton") {
            return "Hilton Honors spans 7,000+ properties across 18 brands. Points are easy to earn with Amex co-branded cards. Fifth night free on award stays makes longer trips a good value."
        } else if name.contains("ihg") {
            return "IHG One Rewards covers Holiday Inn, InterContinental, Kimpton, and more. The program offers fourth night free on award stays and points don't expire with account activity."
        } else if name.contains("delta") || name.contains("skymiles") {
            return "Delta SkyMiles is the loyalty program of Delta Air Lines. Miles can be earned through flights and Amex co-branded cards. No expiration on miles and a wide range of redemption options."
        } else if name.contains("american") || name.contains("aadvantage") {
            return "AAdvantage is American Airlines' loyalty program. Earn miles on AA flights and with Citi co-branded cards. Redeem for flights on American and oneworld alliance partners."
        } else if name.contains("jetblue") {
            return "JetBlue TrueBlue is known for simplicity: points are worth a fixed ~1.3 cents each. Pool points with family members and enjoy no blackout dates on redemptions."
        } else if name.contains("singapore") {
            return "Singapore Airlines KrisFlyer offers premium cabin award redemptions on one of the world's best airlines. Transfer partners include Chase, Amex, Citi, and Capital One."
        } else if name.contains("virgin") {
            return "Virgin Atlantic Flying Club points are especially valuable for premium cabin awards on Delta, Virgin Atlantic, and partner airlines. Points transfer from Chase, Amex, and Citi."
        } else if partner.type == .airline {
            return "\(partner.name) is an airline loyalty program. Transfer points from your credit card programs to redeem for flights and upgrades."
        } else {
            return "\(partner.name) is a hotel loyalty program. Transfer points from your credit card programs to redeem for free nights and upgrades."
        }
    }

    private var partnerWebsite: String {
        let name = partner.name.lowercased()
        if name.contains("united") { return "https://www.united.com/en/us/fly/mileageplus.html" }
        if name.contains("hyatt") { return "https://world.hyatt.com/" }
        if name.contains("southwest") { return "https://www.southwest.com/rapidrewards/" }
        if name.contains("british") || name.contains("avios") { return "https://www.britishairways.com/executive-club" }
        if name.contains("air france") || name.contains("flying blue") { return "https://www.flyingblue.com/" }
        if name.contains("marriott") || name.contains("bonvoy") { return "https://www.marriott.com/loyalty.mi" }
        if name.contains("hilton") { return "https://www.hilton.com/en/hilton-honors/" }
        if name.contains("ihg") { return "https://www.ihg.com/onerewards/" }
        if name.contains("delta") { return "https://www.delta.com/skymiles/" }
        if name.contains("american") || name.contains("aadvantage") { return "https://www.aa.com/aadvantage" }
        if name.contains("jetblue") { return "https://trueblue.jetblue.com/" }
        if name.contains("singapore") { return "https://www.singaporeair.com/krisflyer" }
        if name.contains("virgin") { return "https://www.virginatlantic.com/flying-club" }
        return "https://www.google.com/search?q=\(partner.name.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")+loyalty+program"
    }
}
