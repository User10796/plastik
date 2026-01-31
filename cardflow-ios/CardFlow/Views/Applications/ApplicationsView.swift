import SwiftUI

struct ApplicationsView: View {
    @Environment(DataStore.self) private var store
    @State private var selectedTab = 0
    @State private var showAddApp = false
    @State private var newCardName = ""
    @State private var newIssuer = "Chase"
    @State private var newHolder = ""
    @State private var newDate = Date()
    @State private var newStatus = "Pending"

    private let issuers = IssuerRules.all.map(\.name)
    private let statuses = ["Approved", "Pending", "Denied"]

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Segmented Control
                Picker("Section", selection: $selectedTab) {
                    Text("Applications").tag(0)
                    Text("Hard Inquiries").tag(1)
                    Text("Issuer Rules").tag(2)
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)
                .padding(.vertical, 8)

                // Tab Content
                switch selectedTab {
                case 0:
                    applicationsListView
                case 1:
                    CreditPullsView()
                case 2:
                    IssuerRulesView()
                default:
                    EmptyView()
                }
            }
            .background(ColorTheme.background)
            .navigationTitle("Applications")
            .toolbar {
                if selectedTab == 0 {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button(action: { showAddApp = true }) {
                            Image(systemName: "plus.circle.fill")
                                .foregroundColor(ColorTheme.gold)
                        }
                    }
                }
            }
            .sheet(isPresented: $showAddApp) {
                addApplicationSheet
            }
        }
    }

    // MARK: - Applications List

    private var applicationsListView: some View {
        Group {
            if store.applications.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "doc.text")
                        .font(.system(size: 48))
                        .foregroundColor(ColorTheme.textMuted)
                    Text("No Applications")
                        .font(.headline)
                        .foregroundColor(ColorTheme.textSecondary)
                    Text("Tap + to track a card application")
                        .font(.subheadline)
                        .foregroundColor(ColorTheme.textMuted)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding(.top, 40)
            } else {
                ScrollView {
                    LazyVStack(spacing: 10) {
                        ForEach(store.applications.sorted(by: { $0.applicationDate > $1.applicationDate })) { app in
                            applicationRow(app)
                        }
                    }
                    .padding()
                }
            }
        }
    }

    private func applicationRow(_ app: CardApplication) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 8) {
                    Text("\(app.issuer) \(app.cardName)")
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(ColorTheme.textPrimary)
                        .lineLimit(1)

                    statusBadge(app.status)
                }

                HStack(spacing: 12) {
                    if !app.holder.isEmpty {
                        Text(app.holder)
                            .font(.caption)
                            .foregroundColor(ColorTheme.textSecondary)
                    }
                    Text(Formatters.formatDate(app.applicationDate))
                        .font(.caption)
                        .foregroundColor(ColorTheme.textMuted)
                }

                if app.signupBonus > 0 {
                    Text("SUB: \(formatPoints(app.signupBonus)) pts / \(Formatters.formatCurrency(app.signupSpend)) spend")
                        .font(.caption)
                        .foregroundColor(ColorTheme.goldLight)
                }
            }
            Spacer()
            if app.creditLimit > 0 {
                Text(Formatters.formatCurrency(app.creditLimit))
                    .font(.caption.weight(.medium))
                    .foregroundColor(ColorTheme.textSecondary)
            }
        }
        .padding()
        .background(ColorTheme.cardBg)
        .cornerRadius(12)
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(ColorTheme.border, lineWidth: 1))
        .swipeActions(edge: .trailing) {
            Button(role: .destructive) {
                store.deleteApplication(app)
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
    }

    private func statusBadge(_ status: String) -> some View {
        let colors = ColorTheme.statusColor(status)
        return Text(status)
            .font(.caption2.weight(.semibold))
            .foregroundColor(colors.text)
            .padding(.horizontal, 8)
            .padding(.vertical, 2)
            .background(colors.bg)
            .cornerRadius(6)
    }

    // MARK: - Add Application Sheet

    private var addApplicationSheet: some View {
        NavigationStack {
            Form {
                Section("Card Details") {
                    TextField("Card Name", text: $newCardName)

                    Picker("Issuer", selection: $newIssuer) {
                        ForEach(issuers, id: \.self) { Text($0) }
                    }

                    if !store.holders.isEmpty {
                        Picker("Holder", selection: $newHolder) {
                            Text("Select...").tag("")
                            ForEach(store.holders, id: \.self) { Text($0).tag($0) }
                        }
                    }
                }

                Section("Application Info") {
                    DatePicker("Date", selection: $newDate, displayedComponents: .date)

                    Picker("Status", selection: $newStatus) {
                        ForEach(statuses, id: \.self) { Text($0) }
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .background(ColorTheme.background)
            .navigationTitle("Add Application")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        resetAddForm()
                        showAddApp = false
                    }
                    .foregroundColor(ColorTheme.textSecondary)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        let app = CardApplication(
                            cardName: newCardName,
                            issuer: newIssuer,
                            holder: newHolder,
                            applicationDate: Formatters.dateISO.string(from: newDate),
                            status: newStatus
                        )
                        store.addApplication(app)
                        resetAddForm()
                        showAddApp = false
                    }
                    .disabled(newCardName.trimmingCharacters(in: .whitespaces).isEmpty)
                    .foregroundColor(ColorTheme.gold)
                }
            }
            .onAppear {
                if newHolder.isEmpty, let first = store.holders.first {
                    newHolder = first
                }
            }
        }
    }

    private func resetAddForm() {
        newCardName = ""
        newIssuer = "Chase"
        newHolder = store.holders.first ?? ""
        newDate = Date()
        newStatus = "Pending"
    }

    private func formatPoints(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: value)) ?? "0"
    }
}
