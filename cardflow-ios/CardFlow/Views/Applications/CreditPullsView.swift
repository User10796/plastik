import SwiftUI

struct CreditPullsView: View {
    @Environment(DataStore.self) private var store
    @State private var showAddPull = false
    @State private var newBureau = "Experian"
    @State private var newCreditor = ""
    @State private var newDate = Date()
    @State private var newType = "Hard"

    private let bureaus = ["Experian", "Equifax", "TransUnion"]
    private let pullTypes = ["Hard", "Soft"]

    private var pullsByBureau: [(bureau: String, pulls: [CreditPull])] {
        let grouped = Dictionary(grouping: store.creditPulls) { $0.bureau }
        return bureaus.compactMap { bureau in
            guard let pulls = grouped[bureau], !pulls.isEmpty else { return nil }
            let sorted = pulls.sorted { $0.date > $1.date }
            return (bureau: bureau, pulls: sorted)
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            if store.creditPulls.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "doc.text.magnifyingglass")
                        .font(.system(size: 40))
                        .foregroundColor(ColorTheme.textMuted)
                    Text("No Credit Pulls")
                        .font(.headline)
                        .foregroundColor(ColorTheme.textSecondary)
                    Text("Tap + to add a hard inquiry")
                        .font(.subheadline)
                        .foregroundColor(ColorTheme.textMuted)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding(.top, 40)
            } else {
                ScrollView {
                    LazyVStack(spacing: 16) {
                        ForEach(pullsByBureau, id: \.bureau) { group in
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Text(group.bureau)
                                        .font(.subheadline.weight(.semibold))
                                        .foregroundColor(ColorTheme.textPrimary)
                                    Spacer()
                                    Text("\(group.pulls.count) pull\(group.pulls.count == 1 ? "" : "s")")
                                        .font(.caption)
                                        .foregroundColor(ColorTheme.textMuted)
                                }
                                .padding(.horizontal)

                                ForEach(group.pulls) { pull in
                                    HStack {
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(pull.creditor)
                                                .font(.subheadline.weight(.medium))
                                                .foregroundColor(ColorTheme.textPrimary)
                                            Text(Formatters.formatDate(pull.date))
                                                .font(.caption)
                                                .foregroundColor(ColorTheme.textMuted)
                                        }
                                        Spacer()
                                        Text(pull.type)
                                            .font(.caption.weight(.medium))
                                            .foregroundColor(pull.type == "Hard" ? ColorTheme.red : ColorTheme.textSecondary)
                                            .padding(.horizontal, 8)
                                            .padding(.vertical, 4)
                                            .background(pull.type == "Hard" ? ColorTheme.red.opacity(0.15) : ColorTheme.surfaceBg)
                                            .cornerRadius(6)
                                    }
                                    .padding()
                                    .background(ColorTheme.cardBg)
                                    .cornerRadius(10)
                                    .swipeActions(edge: .trailing) {
                                        Button(role: .destructive) {
                                            store.deleteCreditPull(pull)
                                        } label: {
                                            Label("Delete", systemImage: "trash")
                                        }
                                    }
                                }
                            }
                        }
                    }
                    .padding()
                }
            }
        }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button(action: { showAddPull = true }) {
                    Image(systemName: "plus.circle.fill")
                        .foregroundColor(ColorTheme.gold)
                }
            }
        }
        .sheet(isPresented: $showAddPull) {
            addPullSheet
        }
    }

    private var addPullSheet: some View {
        NavigationStack {
            Form {
                Picker("Bureau", selection: $newBureau) {
                    ForEach(bureaus, id: \.self) { Text($0) }
                }

                TextField("Creditor", text: $newCreditor)

                DatePicker("Date", selection: $newDate, displayedComponents: .date)

                Picker("Type", selection: $newType) {
                    ForEach(pullTypes, id: \.self) { Text($0) }
                }
            }
            .scrollContentBackground(.hidden)
            .background(ColorTheme.background)
            .navigationTitle("Add Credit Pull")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        resetAddForm()
                        showAddPull = false
                    }
                    .foregroundColor(ColorTheme.textSecondary)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        let pull = CreditPull(
                            bureau: newBureau,
                            creditor: newCreditor,
                            date: Formatters.dateISO.string(from: newDate),
                            type: newType
                        )
                        store.addCreditPulls([pull])
                        resetAddForm()
                        showAddPull = false
                    }
                    .disabled(newCreditor.trimmingCharacters(in: .whitespaces).isEmpty)
                    .foregroundColor(ColorTheme.gold)
                }
            }
        }
        .presentationDetents([.medium])
    }

    private func resetAddForm() {
        newBureau = "Experian"
        newCreditor = ""
        newDate = Date()
        newType = "Hard"
    }
}
