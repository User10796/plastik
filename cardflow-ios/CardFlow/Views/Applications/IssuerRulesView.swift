import SwiftUI

struct IssuerRulesView: View {
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(IssuerRules.all) { issuer in
                    DisclosureGroup {
                        VStack(alignment: .leading, spacing: 12) {
                            // Rules
                            if !issuer.rules.isEmpty {
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("Rules")
                                        .font(.caption.weight(.semibold))
                                        .foregroundColor(ColorTheme.textSecondary)

                                    ForEach(issuer.rules) { rule in
                                        HStack(alignment: .top, spacing: 8) {
                                            Text(rule.name)
                                                .font(.caption.weight(.bold))
                                                .foregroundColor(ColorTheme.gold)
                                                .frame(width: 80, alignment: .leading)

                                            Text(rule.description)
                                                .font(.caption)
                                                .foregroundColor(ColorTheme.textSecondary)
                                                .fixedSize(horizontal: false, vertical: true)
                                        }
                                    }
                                }
                            }

                            // Bureau Pulls
                            VStack(alignment: .leading, spacing: 6) {
                                Text("Bureau Pulls")
                                    .font(.caption.weight(.semibold))
                                    .foregroundColor(ColorTheme.textSecondary)

                                HStack(spacing: 6) {
                                    ForEach(issuer.pullsBureau, id: \.self) { bureau in
                                        Text(bureau)
                                            .font(.caption2.weight(.medium))
                                            .foregroundColor(ColorTheme.blue)
                                            .padding(.horizontal, 8)
                                            .padding(.vertical, 4)
                                            .background(ColorTheme.blue.opacity(0.15))
                                            .cornerRadius(6)
                                    }
                                }
                            }

                            // Notes
                            if !issuer.notes.isEmpty {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Notes")
                                        .font(.caption.weight(.semibold))
                                        .foregroundColor(ColorTheme.textSecondary)

                                    Text(issuer.notes)
                                        .font(.caption)
                                        .foregroundColor(ColorTheme.textMuted)
                                        .fixedSize(horizontal: false, vertical: true)
                                }
                            }
                        }
                        .padding(.top, 8)
                    } label: {
                        HStack {
                            Text(issuer.name)
                                .font(.subheadline.weight(.semibold))
                                .foregroundColor(ColorTheme.textPrimary)
                            Spacer()
                            Text("\(issuer.rules.count) rules")
                                .font(.caption)
                                .foregroundColor(ColorTheme.textMuted)
                        }
                    }
                    .tint(ColorTheme.textSecondary)
                    .padding()
                    .background(ColorTheme.cardBg)
                    .cornerRadius(12)
                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(ColorTheme.border, lineWidth: 1))
                }
            }
            .padding()
        }
    }
}
