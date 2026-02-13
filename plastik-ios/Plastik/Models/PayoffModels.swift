import Foundation

// MARK: - Payoff Strategy

enum PayoffStrategy: String, CaseIterable, Identifiable {
    case snowball = "Snowball"
    case avalanche = "Avalanche"
    case savvy = "Savvy"
    case highestPayment = "Cash Flow"
    case cashFlowIndex = "CFI"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .snowball: return "Debt Snowball"
        case .avalanche: return "Debt Avalanche"
        case .savvy: return "Savvy Hybrid"
        case .highestPayment: return "Cash Flow First"
        case .cashFlowIndex: return "Cash Flow Index"
        }
    }

    var icon: String {
        switch self {
        case .snowball: return "target"
        case .avalanche: return "chart.line.downtrend.xyaxis"
        case .savvy: return "brain.head.profile"
        case .highestPayment: return "dollarsign.circle"
        case .cashFlowIndex: return "scale.3d"
        }
    }

    var tagline: String {
        switch self {
        case .snowball: return "Lowest Balance First"
        case .avalanche: return "Highest Interest First"
        case .savvy: return "Best of Both Worlds"
        case .highestPayment: return "Highest Payment First"
        case .cashFlowIndex: return "Optimize Cash Flow"
        }
    }

    var description: String {
        switch self {
        case .snowball:
            return "Pay off your smallest debts first to build momentum. Each win motivates you to tackle the next one."
        case .avalanche:
            return "Attack the highest-interest debt first to minimize total interest paid. Mathematically optimal."
        case .savvy:
            return "Clear small balances quickly for wins, then switch to highest-interest for savings."
        case .highestPayment:
            return "Focus on debts with the largest monthly payments to free up cash flow fastest."
        case .cashFlowIndex:
            return "Pay off debts that trap the most cash flow per dollar owed for maximum flexibility."
        }
    }

    var bestFor: String {
        switch self {
        case .snowball:
            return "People who need motivation and quick wins"
        case .avalanche:
            return "Analytically-minded people focused on savings"
        case .savvy:
            return "Those with a mix of small and large debts"
        case .highestPayment:
            return "People struggling with monthly cash flow"
        case .cashFlowIndex:
            return "Self-employed or variable income earners"
        }
    }

    var tradeoff: String {
        switch self {
        case .snowball:
            return "May pay slightly more interest than Avalanche"
        case .avalanche:
            return "First payoff may take longer, which can be demotivating"
        case .savvy:
            return "Slightly more complex to follow"
        case .highestPayment:
            return "May pay more interest if high-payment debts have low APR"
        case .cashFlowIndex:
            return "Results vary based on payment-to-balance ratios"
        }
    }
}

// MARK: - Payoff Card

struct PayoffCard: Identifiable, Hashable {
    let id: UUID
    let cardId: String?  // Link to Plastik card if applicable
    var name: String
    var issuer: Issuer?
    var balance: Double
    var apr: Double  // As percentage (e.g., 21.9)
    var minimumPayment: Double
    var isFromImport: Bool

    init(id: UUID = UUID(), cardId: String? = nil, name: String, issuer: Issuer? = nil, balance: Double, apr: Double, minimumPayment: Double, isFromImport: Bool = false) {
        self.id = id
        self.cardId = cardId
        self.name = name
        self.issuer = issuer
        self.balance = balance
        self.apr = apr
        self.minimumPayment = minimumPayment
        self.isFromImport = isFromImport
    }

    var cashFlowIndex: Double {
        guard minimumPayment > 0 else { return Double.infinity }
        return balance / minimumPayment
    }
}

// MARK: - Payment Records

struct CardPayment: Identifiable {
    let id = UUID()
    let cardId: UUID
    let cardName: String
    let payment: Double
    let principal: Double
    let interest: Double
    let remainingBalance: Double
    let isPaidOff: Bool
}

struct MonthlyPayment: Identifiable {
    let id = UUID()
    let month: Int
    let date: Date
    let payments: [CardPayment]
    let totalPayment: Double
    let remainingBalance: Double

    var paidOffCards: [CardPayment] {
        payments.filter { $0.isPaidOff }
    }
}

// MARK: - Payoff Plan

struct PayoffPlan {
    let strategy: PayoffStrategy
    let cards: [PayoffCard]
    let extraMonthlyPayment: Double
    let monthlyPayments: [MonthlyPayment]

    var debtFreeDate: Date {
        monthlyPayments.last?.date ?? Date()
    }

    var totalMonths: Int {
        monthlyPayments.count
    }

    var totalInterest: Double {
        monthlyPayments.flatMap { $0.payments }.reduce(0) { $0 + $1.interest }
    }

    var totalPaid: Double {
        monthlyPayments.reduce(0) { $0 + $1.totalPayment }
    }

    var firstPayoffMonth: Int? {
        monthlyPayments.first { !$0.paidOffCards.isEmpty }?.month
    }

    var firstPayoffCard: String? {
        monthlyPayments.first { !$0.paidOffCards.isEmpty }?.paidOffCards.first?.cardName
    }

    var payoffMilestones: [(month: Int, cardName: String, date: Date)] {
        monthlyPayments.compactMap { payment in
            if let paidOff = payment.paidOffCards.first {
                return (payment.month, paidOff.cardName, payment.date)
            }
            return nil
        }
    }
}

// MARK: - Payoff Calculator Engine

class PayoffCalculator {

    static func calculate(cards: [PayoffCard], strategy: PayoffStrategy, extraMonthlyPayment: Double) -> PayoffPlan {
        guard !cards.isEmpty else {
            return PayoffPlan(strategy: strategy, cards: cards, extraMonthlyPayment: extraMonthlyPayment, monthlyPayments: [])
        }

        // Create working copies
        var workingCards = cards.map { PayoffCardState(card: $0) }
        var monthlyPayments: [MonthlyPayment] = []
        var month = 0
        let startDate = Date()
        let calendar = Calendar.current

        // Maximum 360 months (30 years) to prevent infinite loops
        while workingCards.contains(where: { $0.balance > 0.01 }) && month < 360 {
            month += 1
            let paymentDate = calendar.date(byAdding: .month, value: month, to: startDate) ?? startDate

            // Sort cards by strategy
            workingCards = sortCards(workingCards, by: strategy)

            // Calculate interest for each card
            for i in 0..<workingCards.count {
                if workingCards[i].balance > 0 {
                    let monthlyRate = workingCards[i].apr / 100 / 12
                    let interest = workingCards[i].balance * monthlyRate
                    workingCards[i].balance += interest
                    workingCards[i].interestThisMonth = interest
                }
            }

            // Apply payments
            var remainingExtra = extraMonthlyPayment
            var cardPayments: [CardPayment] = []

            for i in 0..<workingCards.count {
                guard workingCards[i].balance > 0 else { continue }

                let minPayment = workingCards[i].minimumPayment
                let availablePayment = minPayment + remainingExtra
                let actualPayment = min(availablePayment, workingCards[i].balance)

                let interest = workingCards[i].interestThisMonth
                let principal = actualPayment - interest

                workingCards[i].balance -= actualPayment
                let isPaidOff = workingCards[i].balance < 0.01

                if isPaidOff {
                    workingCards[i].balance = 0
                    // Roll this card's minimum into extra for next iteration
                    remainingExtra = (availablePayment - actualPayment) + minPayment
                } else {
                    remainingExtra = availablePayment - actualPayment
                }

                cardPayments.append(CardPayment(
                    cardId: workingCards[i].id,
                    cardName: workingCards[i].name,
                    payment: actualPayment,
                    principal: max(0, principal),
                    interest: interest,
                    remainingBalance: workingCards[i].balance,
                    isPaidOff: isPaidOff
                ))

                // Reset interest tracking
                workingCards[i].interestThisMonth = 0
            }

            let totalPayment = cardPayments.reduce(0) { $0 + $1.payment }
            let totalRemaining = workingCards.reduce(0) { $0 + $1.balance }

            monthlyPayments.append(MonthlyPayment(
                month: month,
                date: paymentDate,
                payments: cardPayments,
                totalPayment: totalPayment,
                remainingBalance: totalRemaining
            ))
        }

        return PayoffPlan(
            strategy: strategy,
            cards: cards,
            extraMonthlyPayment: extraMonthlyPayment,
            monthlyPayments: monthlyPayments
        )
    }

    private static func sortCards(_ cards: [PayoffCardState], by strategy: PayoffStrategy) -> [PayoffCardState] {
        // Only sort cards that still have balance
        let withBalance = cards.filter { $0.balance > 0.01 }
        let paidOff = cards.filter { $0.balance <= 0.01 }

        let sorted: [PayoffCardState]
        switch strategy {
        case .snowball:
            sorted = withBalance.sorted { $0.balance < $1.balance }
        case .avalanche:
            sorted = withBalance.sorted { $0.apr > $1.apr }
        case .savvy:
            let threshold: Double = 1000
            let small = withBalance.filter { $0.balance <= threshold }.sorted { $0.balance < $1.balance }
            let large = withBalance.filter { $0.balance > threshold }.sorted { $0.apr > $1.apr }
            sorted = small + large
        case .highestPayment:
            sorted = withBalance.sorted { $0.minimumPayment > $1.minimumPayment }
        case .cashFlowIndex:
            sorted = withBalance.sorted {
                let cfi1 = $0.minimumPayment > 0 ? $0.balance / $0.minimumPayment : Double.infinity
                let cfi2 = $1.minimumPayment > 0 ? $1.balance / $1.minimumPayment : Double.infinity
                return cfi1 < cfi2
            }
        }

        return sorted + paidOff
    }

    // Compare all strategies
    static func compareStrategies(cards: [PayoffCard], extraMonthlyPayment: Double) -> [PayoffPlan] {
        PayoffStrategy.allCases.map { strategy in
            calculate(cards: cards, strategy: strategy, extraMonthlyPayment: extraMonthlyPayment)
        }
    }

    // Calculate minimum payments only (baseline comparison)
    static func calculateMinimumOnly(cards: [PayoffCard]) -> PayoffPlan {
        calculate(cards: cards, strategy: .avalanche, extraMonthlyPayment: 0)
    }
}

// Internal state for calculation
private struct PayoffCardState {
    let id: UUID
    let name: String
    var balance: Double
    let apr: Double
    let minimumPayment: Double
    var interestThisMonth: Double = 0

    init(card: PayoffCard) {
        self.id = card.id
        self.name = card.name
        self.balance = card.balance
        self.apr = card.apr
        self.minimumPayment = card.minimumPayment
    }
}
