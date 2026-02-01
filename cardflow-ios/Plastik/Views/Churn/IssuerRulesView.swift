import SwiftUI

struct IssuerRulesView: View {
    @Environment(DataFeedService.self) private var feedService
    let issuer: Issuer

    private var rules: [ChurnRule] {
        feedService.churnRules.filter { $0.issuer == issuer }
    }

    var body: some View {
        List {
            ForEach(rules) { rule in
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: rule.category.icon)
                            .foregroundStyle(.orange)
                        Text(rule.name)
                            .font(.headline)
                        Spacer()
                        HStack(spacing: 4) {
                            Text(rule.ruleType.displayName)
                                .font(.caption2)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 3)
                                .background(rule.ruleType == .applicationEligibility ? .blue.opacity(0.15) : .orange.opacity(0.15))
                                .foregroundStyle(rule.ruleType == .applicationEligibility ? .blue : .orange)
                                .clipShape(RoundedRectangle(cornerRadius: 4))

                            Text(rule.category.displayName)
                                .font(.caption2)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 3)
                                .background(.secondary.opacity(0.15))
                                .clipShape(RoundedRectangle(cornerRadius: 4))
                        }
                    }

                    Text(rule.description)
                        .font(.subheadline)

                    Text(rule.details)
                        .font(.body)
                        .foregroundStyle(.secondary)

                    if let months = rule.windowMonths, let max = rule.maxCards {
                        HStack(spacing: 12) {
                            Label("\(max) cards / \(months) months", systemImage: "calendar")
                                .font(.caption)
                                .foregroundStyle(.blue)
                            if rule.countsAllIssuers == true {
                                Text("All issuers")
                                    .font(.caption2)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(.red.opacity(0.1))
                                    .foregroundStyle(.red)
                                    .clipShape(RoundedRectangle(cornerRadius: 4))
                            }
                        }
                    }

                    if let cooldown = rule.cooldownMonths {
                        Label("\(cooldown)-month cooldown", systemImage: "clock.arrow.circlepath")
                            .font(.caption)
                            .foregroundStyle(.orange)
                    }
                }
                .padding(.vertical, 4)
            }
        }
        .navigationTitle("\(issuer.displayName) Rules")
    }
}
