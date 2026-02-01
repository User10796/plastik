import SwiftUI

// MARK: - Strategy View

struct StrategyView: View {
    @Environment(CardViewModel.self) private var cardViewModel
    @Environment(DataFeedService.self) private var feedService

    private let retentionService = RetentionAnalysisService()

    private var analyses: [CardRetentionAnalysis] {
        cardViewModel.userCards
            .filter { $0.isActive }
            .compactMap { userCard -> CardRetentionAnalysis? in
                guard let card = feedService.card(for: userCard.cardId) else { return nil }
                return retentionService.analyzeCard(userCard: userCard, card: card, feedService: feedService)
            }
    }

    private var upcomingDecisions: [CardRetentionAnalysis] {
        let sixtyDaysFromNow = Calendar.current.date(byAdding: .day, value: 60, to: Date()) ?? Date()
        return analyses.filter { analysis in
            guard let feeDate = analysis.userCard.annualFeeDate else { return false }
            return feeDate > Date() && feeDate <= sixtyDaysFromNow
        }
        .sorted { ($0.userCard.annualFeeDate ?? .distantFuture) < ($1.userCard.annualFeeDate ?? .distantFuture) }
    }

    private var worthKeeping: [CardRetentionAnalysis] {
        analyses.filter { $0.recommendation == .keep }
    }

    private var considerAction: [CardRetentionAnalysis] {
        analyses.filter { $0.recommendation == .cancel || $0.recommendation == .downgrade || $0.recommendation == .callRetention }
    }

    private var rechurnOpportunities: [CardRetentionAnalysis] {
        analyses.filter { $0.rechurnAnalysis?.canRechurn == true }
    }

    var body: some View {
        List {
            upcomingDecisionsSection
            worthKeepingSection
            considerActionSection
            rechurnOpportunitiesSection
        }
        .navigationTitle("Keep or Cancel")
        .navigationDestination(for: String.self) { analysisId in
            if let analysis = analyses.first(where: { $0.id == analysisId }) {
                RetentionDetailView(analysis: analysis)
            }
        }
    }

    // MARK: - Upcoming Decisions

    @ViewBuilder
    private var upcomingDecisionsSection: some View {
        Section("Upcoming Decisions") {
            if upcomingDecisions.isEmpty {
                Text("No annual fee decisions in the next 60 days.")
                    .foregroundStyle(.secondary)
                    .font(.subheadline)
            } else {
                ForEach(upcomingDecisions) { analysis in
                    NavigationLink(value: analysis.id) {
                        AnnualFeeDecisionRow(analysis: analysis)
                    }
                }
            }
        }
    }

    // MARK: - Worth Keeping

    @ViewBuilder
    private var worthKeepingSection: some View {
        if !worthKeeping.isEmpty {
            Section("Worth Keeping") {
                ForEach(worthKeeping) { analysis in
                    NavigationLink(value: analysis.id) {
                        RetentionSummaryRow(analysis: analysis)
                    }
                }
            }
        }
    }

    // MARK: - Consider Action

    @ViewBuilder
    private var considerActionSection: some View {
        if !considerAction.isEmpty {
            Section("Consider Action") {
                ForEach(considerAction) { analysis in
                    NavigationLink(value: analysis.id) {
                        RetentionSummaryRow(analysis: analysis)
                    }
                }
            }
        }
    }

    // MARK: - Rechurn Opportunities

    @ViewBuilder
    private var rechurnOpportunitiesSection: some View {
        if !rechurnOpportunities.isEmpty {
            Section("Rechurn Opportunities") {
                ForEach(rechurnOpportunities) { analysis in
                    NavigationLink(value: analysis.id) {
                        RechurnRow(analysis: analysis)
                    }
                }
            }
        }
    }
}

// MARK: - Annual Fee Decision Row

struct AnnualFeeDecisionRow: View {
    let analysis: CardRetentionAnalysis

    private var daysUntilFee: Int {
        guard let feeDate = analysis.userCard.annualFeeDate else { return 0 }
        return feeDate.daysFrom(Date())
    }

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(analysis.userCard.nickname ?? analysis.card.name)
                    .font(.body.bold())
                HStack(spacing: 8) {
                    if let feeDate = analysis.userCard.annualFeeDate {
                        Text("Fee: \(feeDate.shortFormatted)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Text("\(daysUntilFee) days")
                        .font(.caption.bold())
                        .foregroundStyle(daysUntilFee <= 30 ? .red : .orange)
                }
                Text("Net: \(analysis.netValue.currencyFormatted)")
                    .font(.caption)
                    .foregroundStyle(analysis.netValue >= 0 ? .green : .red)
            }

            Spacer()

            RecommendationBadge(recommendation: analysis.recommendation)
        }
        .padding(.vertical, 2)
    }
}

// MARK: - Retention Summary Row

struct RetentionSummaryRow: View {
    let analysis: CardRetentionAnalysis

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(analysis.userCard.nickname ?? analysis.card.name)
                    .font(.body.bold())
                Text("\(analysis.card.issuer.displayName) \u{00B7} \(analysis.annualFee.currencyFormatted) fee")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text("Net: \(analysis.netValue.currencyFormatted)")
                    .font(.caption)
                    .foregroundStyle(analysis.netValue >= 0 ? .green : .red)
            }

            Spacer()

            RecommendationBadge(recommendation: analysis.recommendation)
        }
        .padding(.vertical, 2)
    }
}

// MARK: - Rechurn Row

struct RechurnRow: View {
    let analysis: CardRetentionAnalysis

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(analysis.userCard.nickname ?? analysis.card.name)
                    .font(.body.bold())
                if let rechurn = analysis.rechurnAnalysis {
                    if let date = rechurn.bonusEligibleDate {
                        if date <= Date() {
                            Text("Bonus eligible now")
                                .font(.caption.bold())
                                .foregroundStyle(.green)
                        } else {
                            Text("Eligible \(date.shortFormatted)")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    Text("Historical: \(rechurn.historicalBonusRange)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            Image(systemName: "arrow.trianglehead.2.clockwise")
                .font(.title3)
                .foregroundStyle(.blue)
        }
        .padding(.vertical, 2)
    }
}

// MARK: - Recommendation Badge

struct RecommendationBadge: View {
    let recommendation: RetentionRecommendation

    var body: some View {
        Text(recommendation.displayText)
            .font(.caption2.bold())
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(recommendation.color.opacity(0.15))
            .foregroundStyle(recommendation.color)
            .clipShape(RoundedRectangle(cornerRadius: 6))
    }
}

// MARK: - Retention Detail View

struct RetentionDetailView: View {
    let analysis: CardRetentionAnalysis

    var body: some View {
        List {
            overviewSection
            reasoningSection
            alternativesSection
            rechurnSection
        }
        .navigationTitle(analysis.card.name)
        .navigationBarTitleDisplayMode(.inline)
    }

    @ViewBuilder
    private var overviewSection: some View {
        Section("Overview") {
            HStack {
                Text("Annual Fee")
                Spacer()
                Text(analysis.annualFee.currencyFormatted)
                    .foregroundStyle(.secondary)
            }
            HStack {
                Text("Benefit Value")
                Spacer()
                Text(analysis.totalBenefitValue.currencyFormatted)
                    .foregroundStyle(.secondary)
            }
            HStack {
                Text("Net Value")
                Spacer()
                Text(analysis.netValue.currencyFormatted)
                    .bold()
                    .foregroundStyle(analysis.netValue >= 0 ? .green : .red)
            }
            HStack {
                Text("Recommendation")
                Spacer()
                RecommendationBadge(recommendation: analysis.recommendation)
            }
        }
    }

    @ViewBuilder
    private var reasoningSection: some View {
        Section("Analysis") {
            Text(analysis.reasoning)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }

    @ViewBuilder
    private var alternativesSection: some View {
        if !analysis.alternatives.isEmpty {
            Section("Options") {
                ForEach(analysis.alternatives) { alternative in
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Image(systemName: iconForAction(alternative.action))
                                .foregroundStyle(colorForAction(alternative.action))
                                .frame(width: 20)
                            Text(alternative.benefit)
                                .font(.subheadline.bold())
                        }
                        ForEach(alternative.considerations, id: \.self) { consideration in
                            HStack(alignment: .top, spacing: 6) {
                                Text("\u{2022}")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                Text(consideration)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
        }
    }

    @ViewBuilder
    private var rechurnSection: some View {
        if let rechurn = analysis.rechurnAnalysis {
            Section("Rechurn Potential") {
                HStack {
                    Text("Can Rechurn")
                    Spacer()
                    Image(systemName: rechurn.canRechurn ? "checkmark.circle.fill" : "xmark.circle.fill")
                        .foregroundStyle(rechurn.canRechurn ? .green : .red)
                }
                if let date = rechurn.bonusEligibleDate {
                    HStack {
                        Text("Bonus Eligible")
                        Spacer()
                        Text(date.shortFormatted)
                            .foregroundStyle(.secondary)
                    }
                }
                HStack {
                    Text("Historical Bonus")
                    Spacer()
                    Text(rechurn.historicalBonusRange)
                        .foregroundStyle(.secondary)
                }
                Text(rechurn.recommendation)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private func iconForAction(_ action: RetentionAction) -> String {
        switch action {
        case .productChange: return "arrow.triangle.swap"
        case .cancel: return "xmark.circle"
        case .keep: return "checkmark.circle"
        case .requestRetentionOffer: return "phone.circle"
        }
    }

    private func colorForAction(_ action: RetentionAction) -> Color {
        switch action {
        case .productChange: return .orange
        case .cancel: return .red
        case .keep: return .green
        case .requestRetentionOffer: return .yellow
        }
    }
}
