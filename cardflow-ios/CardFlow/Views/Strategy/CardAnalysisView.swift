import SwiftUI

struct CardAnalysisView: View {
    let analysis: [String: Any]

    private var recommendation: String {
        analysis["recommendation"] as? String ?? "UNKNOWN"
    }

    private var recommendationColor: Color {
        switch recommendation {
        case "APPLY": return ColorTheme.green
        case "WAIT": return ColorTheme.gold
        case "SKIP": return ColorTheme.red
        default: return ColorTheme.textMuted
        }
    }

    private var signupBonusValue: Double? {
        analysis["signupBonusValue"] as? Double
    }

    private var firstYearValue: Double? {
        analysis["firstYearValue"] as? Double
    }

    private var ongoingAnnualValue: Double? {
        analysis["ongoingAnnualValue"] as? Double
    }

    private var pros: [String] {
        analysis["pros"] as? [String] ?? []
    }

    private var cons: [String] {
        analysis["cons"] as? [String] ?? []
    }

    private var timing: String? {
        analysis["timing"] as? String
    }

    private var spendStrategy: String? {
        analysis["spendStrategy"] as? String
    }

    private var keepOrChurn: String? {
        analysis["keepOrChurn"] as? String
    }

    private var summary: String? {
        analysis["summary"] as? String
    }

    private var alternativeCards: [String]? {
        analysis["alternativeCards"] as? [String]
    }

    var body: some View {
        VStack(spacing: 16) {
            // Recommendation Badge
            VStack(spacing: 8) {
                Text(recommendation)
                    .font(.title2.weight(.bold))
                    .foregroundColor(recommendationColor)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 8)
                    .background(recommendationColor.opacity(0.15))
                    .cornerRadius(12)

                if let summary = summary {
                    Text(summary)
                        .font(.subheadline)
                        .foregroundColor(ColorTheme.textSecondary)
                        .multilineTextAlignment(.center)
                }
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(ColorTheme.cardBg)
            .cornerRadius(16)

            // Value Metrics
            HStack(spacing: 12) {
                if let value = signupBonusValue {
                    valueMetric(title: "Bonus Value", amount: value, color: ColorTheme.gold)
                }
                if let value = firstYearValue {
                    valueMetric(title: "First Year", amount: value, color: ColorTheme.green)
                }
                if let value = ongoingAnnualValue {
                    valueMetric(title: "Ongoing/yr", amount: value, color: value >= 0 ? ColorTheme.blue : ColorTheme.red)
                }
            }

            // Pros & Cons
            if !pros.isEmpty || !cons.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    if !pros.isEmpty {
                        Text("Pros")
                            .font(.subheadline.weight(.semibold))
                            .foregroundColor(ColorTheme.green)
                        ForEach(Array(pros.enumerated()), id: \.offset) { _, pro in
                            HStack(alignment: .top, spacing: 8) {
                                Image(systemName: "plus.circle.fill")
                                    .font(.caption)
                                    .foregroundColor(ColorTheme.green)
                                    .padding(.top, 2)
                                Text(pro)
                                    .font(.caption)
                                    .foregroundColor(ColorTheme.textPrimary)
                            }
                        }
                    }

                    if !pros.isEmpty && !cons.isEmpty {
                        Divider().overlay(ColorTheme.border)
                    }

                    if !cons.isEmpty {
                        Text("Cons")
                            .font(.subheadline.weight(.semibold))
                            .foregroundColor(ColorTheme.red)
                        ForEach(Array(cons.enumerated()), id: \.offset) { _, con in
                            HStack(alignment: .top, spacing: 8) {
                                Image(systemName: "minus.circle.fill")
                                    .font(.caption)
                                    .foregroundColor(ColorTheme.red)
                                    .padding(.top, 2)
                                Text(con)
                                    .font(.caption)
                                    .foregroundColor(ColorTheme.textPrimary)
                            }
                        }
                    }
                }
                .padding()
                .background(ColorTheme.cardBg)
                .cornerRadius(12)
            }

            // Timing & Strategy
            VStack(alignment: .leading, spacing: 12) {
                if let timing = timing {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack(spacing: 6) {
                            Image(systemName: "clock.fill")
                                .font(.caption)
                                .foregroundColor(ColorTheme.blue)
                            Text("Timing")
                                .font(.subheadline.weight(.semibold))
                                .foregroundColor(ColorTheme.textPrimary)
                        }
                        Text(timing)
                            .font(.caption)
                            .foregroundColor(ColorTheme.textSecondary)
                    }
                }

                if let spend = spendStrategy {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack(spacing: 6) {
                            Image(systemName: "dollarsign.circle.fill")
                                .font(.caption)
                                .foregroundColor(ColorTheme.gold)
                            Text("Spend Strategy")
                                .font(.subheadline.weight(.semibold))
                                .foregroundColor(ColorTheme.textPrimary)
                        }
                        Text(spend)
                            .font(.caption)
                            .foregroundColor(ColorTheme.textSecondary)
                    }
                }

                if let keepChurn = keepOrChurn {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack(spacing: 6) {
                            Image(systemName: keepChurn == "KEEP" ? "checkmark.seal.fill" : "arrow.triangle.2.circlepath")
                                .font(.caption)
                                .foregroundColor(keepChurn == "KEEP" ? ColorTheme.green : ColorTheme.gold)
                            Text("Long-term")
                                .font(.subheadline.weight(.semibold))
                                .foregroundColor(ColorTheme.textPrimary)
                        }
                        Text(keepChurn == "KEEP" ? "This card is worth keeping long-term." : "Consider cancelling or downgrading after the first year bonus.")
                            .font(.caption)
                            .foregroundColor(ColorTheme.textSecondary)
                    }
                }
            }
            .padding()
            .background(ColorTheme.cardBg)
            .cornerRadius(12)

            // Alternative Cards
            if let alternatives = alternativeCards, !alternatives.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Alternatives to Consider")
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(ColorTheme.textPrimary)
                    ForEach(Array(alternatives.enumerated()), id: \.offset) { _, card in
                        HStack(spacing: 8) {
                            Image(systemName: "arrow.right.circle")
                                .font(.caption)
                                .foregroundColor(ColorTheme.blue)
                            Text(card)
                                .font(.caption)
                                .foregroundColor(ColorTheme.textSecondary)
                        }
                    }
                }
                .padding()
                .background(ColorTheme.cardBg)
                .cornerRadius(12)
            }
        }
    }

    @ViewBuilder
    private func valueMetric(title: String, amount: Double, color: Color) -> some View {
        VStack(spacing: 4) {
            Text(title)
                .font(.caption2)
                .foregroundColor(ColorTheme.textMuted)
            Text(Formatters.formatCurrency(amount))
                .font(.subheadline.weight(.bold))
                .foregroundColor(color)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(ColorTheme.cardBg)
        .cornerRadius(10)
        .overlay(RoundedRectangle(cornerRadius: 10).stroke(ColorTheme.border, lineWidth: 1))
    }
}
