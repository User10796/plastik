import SwiftUI

// MARK: - Credit Card Visual Component
// Renders credit cards with issuer-specific gradients, proper shadows, and multiple sizes
// Uses definitions from DesignSystem.swift (CardSize, IssuerTheme, IssuerGradients, CardShadow, etc.)

struct CreditCardView: View {
    let card: CreditCard
    let size: CardSize
    var showAnnualFee: Bool = true
    var isSelected: Bool = false
    var isDisabled: Bool = false

    private var theme: IssuerTheme {
        IssuerGradients.theme(for: card.issuer, cardName: card.name)
    }

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Background gradient
                RoundedRectangle(cornerRadius: size.cornerRadius)
                    .fill(theme.gradient)

                // Glossy overlay
                RoundedRectangle(cornerRadius: size.cornerRadius)
                    .fill(
                        LinearGradient(
                            colors: [
                                .white.opacity(0.15),
                                .clear,
                                .black.opacity(0.1)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )

                // Content based on size
                cardContent(for: size)
            }
            .clipShape(RoundedRectangle(cornerRadius: size.cornerRadius))
            .cardShadow(isDisabled ? CardShadow(color: .clear, radius: 0, x: 0, y: 0) : .default)
            .opacity(isDisabled ? 0.7 : 1.0)
            .saturation(isDisabled ? 0.4 : 1.0)
            .overlay(
                RoundedRectangle(cornerRadius: size.cornerRadius)
                    .stroke(Color.accentColor, lineWidth: isSelected ? 3 : 0)
                    .padding(-2)
            )
        }
        .frame(width: size.size.width, height: size.size.height)
        .aspectRatio(1.586, contentMode: .fit)
    }

    @ViewBuilder
    private func cardContent(for size: CardSize) -> some View {
        switch size {
        case .micro:
            // Just the gradient, maybe issuer initial
            EmptyView()

        case .small:
            // Issuer initial or small logo
            VStack {
                Spacer()
                HStack {
                    Text(card.issuer.displayName.prefix(1))
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(theme.logoColor)
                    Spacer()
                }
                .padding(6)
            }

        case .medium:
            // Full card with issuer, name, network, annual fee
            VStack(alignment: .leading, spacing: 0) {
                // Top row: Issuer logo area + Network
                HStack(alignment: .top) {
                    // Issuer initial/logo
                    Text(card.issuer.displayName.prefix(2).uppercased())
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(theme.logoColor.opacity(0.9))
                        .padding(6)
                        .background(.white.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 4))

                    Spacer()

                    // Network logo
                    networkLogo(size: 28)
                }
                .padding(.horizontal, 12)
                .padding(.top, 12)

                Spacer()

                // Bottom: Card name + Annual fee
                HStack(alignment: .bottom) {
                    Text(card.name)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(.white)
                        .shadow(color: .black.opacity(0.3), radius: 1, x: 0, y: 1)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)

                    Spacer()

                    if showAnnualFee, card.annualFee > 0 {
                        Text("$\(card.annualFee)/yr")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundStyle(.white.opacity(0.9))
                            .padding(.horizontal, 6)
                            .padding(.vertical, 3)
                            .background(.white.opacity(0.2))
                            .clipShape(Capsule())
                    }
                }
                .padding(.horizontal, 12)
                .padding(.bottom, 12)
            }

        case .large, .extraLarge:
            // Rich card with all details
            VStack(alignment: .leading, spacing: 0) {
                // Top row
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(card.issuer.displayName)
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(.white.opacity(0.8))
                        Text(card.name)
                            .font(.system(size: 22, weight: .bold))
                            .foregroundStyle(.white)
                            .shadow(color: .black.opacity(0.3), radius: 2, x: 0, y: 1)
                    }

                    Spacer()

                    networkLogo(size: 40)
                }
                .padding(.horizontal, 16)
                .padding(.top, 16)

                Spacer()

                // Chip graphic (optional decorative element)
                HStack {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(
                            LinearGradient(
                                colors: [.yellow.opacity(0.6), .yellow.opacity(0.3)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 40, height: 28)
                        .overlay(
                            Rectangle()
                                .stroke(.white.opacity(0.3), lineWidth: 0.5)
                        )
                    Spacer()
                }
                .padding(.horizontal, 16)

                Spacer()

                // Bottom row with stats
                HStack {
                    if showAnnualFee {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Annual Fee")
                                .font(.system(size: 10, weight: .medium))
                                .foregroundStyle(.white.opacity(0.7))
                            Text("$\(card.annualFee)")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundStyle(.white)
                        }
                    }

                    Spacer()

                    if let bonus = card.signupBonus, bonus.points > 0 {
                        VStack(alignment: .trailing, spacing: 2) {
                            Text("Bonus")
                                .font(.system(size: 10, weight: .medium))
                                .foregroundStyle(.white.opacity(0.7))
                            Text("\(bonus.points.formatted()) pts")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundStyle(.white)
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 16)
            }
        }
    }

    @ViewBuilder
    private func networkLogo(size: CGFloat) -> some View {
        switch card.network {
        case .visa:
            Text("VISA")
                .font(.system(size: size * 0.4, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
                .italic()
        case .mastercard:
            HStack(spacing: -size * 0.15) {
                Circle()
                    .fill(.red.opacity(0.9))
                    .frame(width: size * 0.5, height: size * 0.5)
                Circle()
                    .fill(.orange.opacity(0.9))
                    .frame(width: size * 0.5, height: size * 0.5)
            }
        case .amex:
            Text("AMEX")
                .font(.system(size: size * 0.35, weight: .bold))
                .foregroundStyle(.white)
        case .discover:
            Text("DISCOVER")
                .font(.system(size: size * 0.25, weight: .bold))
                .foregroundStyle(.white)
        }
    }
}

// MARK: - Mini Card Icon (for lists and widgets)

struct MiniCardIcon: View {
    let issuer: Issuer
    let cardName: String
    var size: CGFloat = 44
    var showInitial: Bool = true

    private var theme: IssuerTheme {
        IssuerGradients.theme(for: issuer, cardName: cardName)
    }

    private var height: CGFloat { size * 0.636 } // 16:10 ratio

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: size * 0.12)
                .fill(theme.gradient)

            if showInitial {
                Text(issuer.displayName.prefix(1))
                    .font(.system(size: size * 0.35, weight: .bold))
                    .foregroundStyle(theme.logoColor)
            }
        }
        .frame(width: size, height: height)
        .cardShadow(CardShadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2))
    }
}

// MARK: - Card Detail Header

struct CardDetailHeader: View {
    let card: CreditCard
    let userCard: UserCard?
    var height: CGFloat = 180

    private var theme: IssuerTheme {
        IssuerGradients.theme(for: card.issuer, cardName: card.name)
    }

    var body: some View {
        ZStack {
            // Gradient background
            theme.gradient
                .ignoresSafeArea(edges: .top)

            // Glossy overlay
            LinearGradient(
                colors: [
                    .white.opacity(0.1),
                    .clear,
                    .black.opacity(0.15)
                ],
                startPoint: .top,
                endPoint: .bottom
            )

            // Content
            VStack(alignment: .leading, spacing: 4) {
                Spacer()

                Text(card.issuer.displayName)
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.8))

                Text(card.name)
                    .font(.system(size: 24, weight: .bold))
                    .foregroundStyle(.white)
                    .shadow(color: .black.opacity(0.3), radius: 2, x: 0, y: 1)

                HStack(spacing: 16) {
                    if card.annualFee > 0 {
                        Label("$\(card.annualFee)/yr", systemImage: "dollarsign.circle")
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.9))
                    }

                    if let openDate = userCard?.openDate {
                        Label(openDate.formatted(date: .abbreviated, time: .omitted), systemImage: "calendar")
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.9))
                    }

                    if let userCard = userCard {
                        let isActive = userCard.closedDate == nil
                        StatusBadge(
                            text: isActive ? "Active" : "Closed",
                            style: isActive ? .active : .inactive
                        )
                    }
                }
                .padding(.top, 8)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 20)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(height: height)
    }
}

// MARK: - Preview

#Preview("Card Sizes") {
    let sampleCard = CreditCard(
        id: "sapphire-preferred",
        name: "Sapphire Preferred",
        issuer: .chase,
        network: .visa,
        annualFee: 95,
        signupBonus: SignupBonus(points: 60000, currency: "Ultimate Rewards", spendRequired: 4000, timeframeDays: 90, expirationDate: nil),
        earningRates: [],
        benefits: [],
        transferPartners: [],
        churnRules: ChurnRuleRef(issuerRules: [], cardSpecificRules: []),
        referralLink: nil,
        imageURL: nil,
        lastUpdated: Date()
    )

    ScrollView {
        VStack(spacing: 32) {
            Group {
                Text("Micro").font(.caption)
                CreditCardView(card: sampleCard, size: .micro)
            }

            Group {
                Text("Small").font(.caption)
                CreditCardView(card: sampleCard, size: .small)
            }

            Group {
                Text("Medium").font(.caption)
                CreditCardView(card: sampleCard, size: .medium)
            }

            Group {
                Text("Large").font(.caption)
                CreditCardView(card: sampleCard, size: .large)
            }

            Group {
                Text("Mini Icon").font(.caption)
                MiniCardIcon(issuer: .chase, cardName: "Sapphire Preferred")
            }
        }
        .padding()
    }
}

#Preview("Issuer Themes") {
    let issuers: [(Issuer, String)] = [
        (.chase, "Sapphire Preferred"),
        (.chase, "Freedom Unlimited"),
        (.amex, "Gold Card"),
        (.amex, "Platinum Card"),
        (.capitalOne, "Venture X"),
        (.citi, "Premier"),
        (.discover, "it Cash Back"),
        (.bankOfAmerica, "Premium Rewards"),
    ]

    ScrollView {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
            ForEach(issuers, id: \.1) { issuer, name in
                VStack {
                    MiniCardIcon(issuer: issuer, cardName: name, size: 64)
                    Text(name)
                        .font(.caption2)
                        .lineLimit(1)
                }
            }
        }
        .padding()
    }
}
