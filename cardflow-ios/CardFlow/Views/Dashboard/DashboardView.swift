import SwiftUI

struct DashboardView: View {
    @Environment(DataStore.self) private var store

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    // Summary Cards
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                        SummaryCard(title: "Total Cards", value: "\(store.cards.count)", subtitle: store.holders.map { h in "\(store.cards.filter { $0.holder == h }.count) \(h)" }.joined(separator: " / "), color: ColorTheme.gold)

                        SummaryCard(title: "Total Balance", value: Formatters.formatCurrency(store.totalBalance), subtitle: "\(store.cardsWithBalance.count) cards with balance", color: ColorTheme.red)

                        SummaryCard(title: "Annual Fees", value: Formatters.formatCurrency(store.totalAnnualFees), subtitle: "\(store.cards.filter { $0.annualFee > 0 }.count) cards with fees", color: ColorTheme.blue)

                        SummaryCard(title: "Chase 5/24", value: "\(store.fiveOverTwentyFour)/24", subtitle: store.canApplyChase ? "Can apply for Chase" : "Over 5/24 limit", color: store.canApplyChase ? ColorTheme.green : ColorTheme.red)
                    }

                    // Companion Passes
                    if !store.companionPasses.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Companion Passes")
                                .font(.headline)
                                .foregroundColor(ColorTheme.textPrimary)

                            ForEach(Array(store.companionPasses.enumerated()), id: \.offset) { _, pass in
                                HStack {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(pass.type)
                                            .font(.subheadline.weight(.semibold))
                                            .foregroundColor(ColorTheme.textPrimary)
                                        if let holder = pass.holder {
                                            Text(holder)
                                                .font(.caption)
                                                .foregroundColor(ColorTheme.textSecondary)
                                        }
                                    }
                                    Spacer()
                                    if pass.earned {
                                        Label("Earned", systemImage: "checkmark.circle.fill")
                                            .font(.caption.weight(.semibold))
                                            .foregroundColor(ColorTheme.green)
                                    } else if let progress = pass.progress, let target = pass.target, target > 0 {
                                        VStack(alignment: .trailing, spacing: 4) {
                                            Text("\(Int(progress / target * 100))%")
                                                .font(.caption.weight(.semibold))
                                                .foregroundColor(ColorTheme.gold)
                                            ProgressView(value: progress, total: target)
                                                .tint(ColorTheme.gold)
                                                .frame(width: 80)
                                        }
                                    }
                                }
                                .padding()
                                .background(ColorTheme.cardBg)
                                .cornerRadius(12)
                            }
                        }
                    }

                    // Upcoming Anniversaries
                    if !store.upcomingAnniversaries.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Upcoming Fee Dates")
                                .font(.headline)
                                .foregroundColor(ColorTheme.textPrimary)

                            ForEach(store.upcomingAnniversaries.prefix(5)) { card in
                                HStack {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("\(card.issuer) \(card.name)")
                                            .font(.subheadline.weight(.medium))
                                            .foregroundColor(ColorTheme.textPrimary)
                                        Text(Formatters.formatDate(card.anniversaryDate))
                                            .font(.caption)
                                            .foregroundColor(ColorTheme.textSecondary)
                                    }
                                    Spacer()
                                    VStack(alignment: .trailing, spacing: 2) {
                                        Text(Formatters.formatCurrency(card.annualFee))
                                            .font(.subheadline.weight(.semibold))
                                            .foregroundColor(ColorTheme.gold)
                                        if let days = Formatters.daysUntil(card.anniversaryDate) {
                                            Text(days > 0 ? "\(days) days" : "Past due")
                                                .font(.caption)
                                                .foregroundColor(days <= 30 ? ColorTheme.red : ColorTheme.textMuted)
                                        }
                                    }
                                }
                                .padding()
                                .background(ColorTheme.cardBg)
                                .cornerRadius(12)
                            }
                        }
                    }

                    // iCloud Status
                    HStack(spacing: 8) {
                        Image(systemName: store.iCloudAvailable ? "icloud.fill" : "icloud.slash")
                            .foregroundColor(store.iCloudAvailable ? ColorTheme.green : ColorTheme.textMuted)
                        Text(store.iCloudAvailable ? "iCloud Synced" : "Local Only")
                            .font(.caption)
                            .foregroundColor(ColorTheme.textMuted)
                        if let syncDate = store.lastSyncDate {
                            Text("• \(syncDate.formatted(date: .omitted, time: .shortened))")
                                .font(.caption)
                                .foregroundColor(ColorTheme.textMuted)
                        }
                    }
                    .padding(.top, 8)
                }
                .padding()
            }
            .background(ColorTheme.background)
            .navigationTitle("Dashboard")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    NavigationLink(destination: SettingsView()) {
                        Image(systemName: "gearshape.fill")
                            .foregroundColor(ColorTheme.textSecondary)
                    }
                }
            }
        }
    }
}

struct SummaryCard: View {
    let title: String
    let value: String
    let subtitle: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.caption)
                .foregroundColor(ColorTheme.textSecondary)
            Text(value)
                .font(.title2.weight(.bold))
                .foregroundColor(color)
            Text(subtitle)
                .font(.caption2)
                .foregroundColor(ColorTheme.textMuted)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(ColorTheme.cardBg)
        .cornerRadius(16)
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(ColorTheme.border, lineWidth: 1))
    }
}
