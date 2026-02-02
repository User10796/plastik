import SwiftUI

struct ApplicationsView: View {
    @Environment(CardViewModel.self) private var cardViewModel
    @Environment(DataFeedService.self) private var feedService
    @State private var showAddApplication = false

    var body: some View {
        List {
            Section {
                HStack {
                    VStack(alignment: .leading) {
                        Text("\(recentApplications) Applications")
                            .font(.headline)
                        Text("Last 24 months")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    VStack(alignment: .trailing) {
                        Text("5/24 Status")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text("\(fiveOverTwentyFour)/5")
                            .font(.title2.bold())
                            .foregroundStyle(fiveOverTwentyFour >= 5 ? .red : .green)
                    }
                }
                .padding(.vertical, 4)
            }

            Section("Application History") {
                if applicationHistory.isEmpty {
                    ContentUnavailableView(
                        "No Applications Tracked",
                        systemImage: "doc.text",
                        description: Text("Applications are tracked automatically when you add cards.")
                    )
                } else {
                    ForEach(applicationHistory, id: \.cardId) { application in
                        ApplicationRow(application: application)
                    }
                }
            }

            Section("5/24 Explained") {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Chase's 5/24 Rule")
                        .font(.subheadline.bold())

                    Text("Chase will generally deny applications if you've opened 5 or more credit cards from ANY issuer in the past 24 months.")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Divider()

                    HStack {
                        Image(systemName: fiveOverTwentyFour < 5 ? "checkmark.circle.fill" : "xmark.circle.fill")
                            .foregroundStyle(fiveOverTwentyFour < 5 ? .green : .red)
                        Text(fiveOverTwentyFour < 5
                             ? "You're under 5/24 - eligible for Chase cards"
                             : "You're at or over 5/24 - focus on non-Chase issuers")
                            .font(.caption)
                    }
                }
                .padding(.vertical, 4)
            }

            Section("Tips") {
                TipRow(
                    icon: "lightbulb.fill",
                    title: "Plan your applications",
                    detail: "Space applications 3+ months apart for best approval odds"
                )

                TipRow(
                    icon: "calendar",
                    title: "Track 24-month window",
                    detail: "Cards drop off 5/24 exactly 24 months after opening"
                )

                TipRow(
                    icon: "chart.bar.fill",
                    title: "Prioritize Chase",
                    detail: "Apply for Chase cards first while under 5/24"
                )
            }
        }
        .navigationTitle("Applications")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    showAddApplication = true
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $showAddApplication) {
            AddApplicationSheet()
        }
    }

    private var recentApplications: Int {
        cardViewModel.userCards.filter { card in
            let cutoff = Calendar.current.date(byAdding: .month, value: -24, to: Date()) ?? Date()
            return card.openDate > cutoff
        }.count
    }

    private var fiveOverTwentyFour: Int {
        cardViewModel.totalAnnualCards24Months
    }

    private var applicationHistory: [(cardId: String, cardName: String, issuer: String, date: Date, approved: Bool)] {
        cardViewModel.userCards
            .sorted { $0.openDate > $1.openDate }
            .compactMap { userCard in
                guard let card = feedService.card(for: userCard.cardId) else { return nil }
                return (
                    cardId: userCard.cardId,
                    cardName: userCard.nickname ?? card.name,
                    issuer: card.issuer.displayName,
                    date: userCard.openDate,
                    approved: true
                )
            }
    }
}

struct ApplicationRow: View {
    let application: (cardId: String, cardName: String, issuer: String, date: Date, approved: Bool)

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(application.cardName)
                    .font(.subheadline)
                Text(application.issuer)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Text(application.date.shortFormatted)
                    .font(.caption)
                    .foregroundStyle(.secondary)

                HStack(spacing: 4) {
                    Image(systemName: application.approved ? "checkmark.circle.fill" : "xmark.circle.fill")
                        .foregroundStyle(application.approved ? .green : .red)
                    Text(application.approved ? "Approved" : "Denied")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(.vertical, 2)
    }
}

struct AddApplicationSheet: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Image(systemName: "doc.badge.plus")
                    .font(.system(size: 60))
                    .foregroundStyle(.blue)

                Text("Track Application")
                    .font(.title2.bold())

                Text("Applications are automatically tracked when you add a card to your wallet.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)

                Button("Add a Card Instead") {
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
            }
            .padding()
            .navigationTitle("Add Application")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }
}

#Preview {
    NavigationStack {
        ApplicationsView()
    }
    .environment(CardViewModel())
    .environment(DataFeedService())
}
