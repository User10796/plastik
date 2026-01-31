import SwiftUI

struct PointsView: View {
    @Environment(DataStore.self) private var store
    @State private var editingProgram: String?
    @State private var editValue: String = ""
    @State private var showAddProgram = false
    @State private var newProgramName: String = ""

    private let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]

    var sortedPrograms: [(key: String, value: Double)] {
        store.pointsBalances.sorted { $0.key < $1.key }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    // Summary
                    if !store.pointsBalances.isEmpty {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Total Programs")
                                    .font(.caption)
                                    .foregroundColor(ColorTheme.textSecondary)
                                Text("\(store.pointsBalances.count)")
                                    .font(.title2.weight(.bold))
                                    .foregroundColor(ColorTheme.gold)
                            }
                            Spacer()
                            VStack(alignment: .trailing, spacing: 4) {
                                Text("Total Points")
                                    .font(.caption)
                                    .foregroundColor(ColorTheme.textSecondary)
                                Text(formatPoints(store.pointsBalances.values.reduce(0, +)))
                                    .font(.title2.weight(.bold))
                                    .foregroundColor(ColorTheme.gold)
                            }
                        }
                        .padding()
                        .background(ColorTheme.cardBg)
                        .cornerRadius(16)
                        .overlay(RoundedRectangle(cornerRadius: 16).stroke(ColorTheme.border, lineWidth: 1))
                    }

                    // Points Grid
                    LazyVGrid(columns: columns, spacing: 12) {
                        ForEach(sortedPrograms, id: \.key) { program, balance in
                            pointsTile(program: program, balance: balance)
                        }
                    }

                    if store.pointsBalances.isEmpty {
                        VStack(spacing: 12) {
                            Image(systemName: "star.slash")
                                .font(.system(size: 48))
                                .foregroundColor(ColorTheme.textMuted)
                            Text("No Points Programs")
                                .font(.headline)
                                .foregroundColor(ColorTheme.textSecondary)
                            Text("Tap + to add a rewards program")
                                .font(.subheadline)
                                .foregroundColor(ColorTheme.textMuted)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.top, 60)
                    }
                }
                .padding()
            }
            .background(ColorTheme.background)
            .navigationTitle("Points Balances")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: { showAddProgram = true }) {
                        Image(systemName: "plus.circle.fill")
                            .foregroundColor(ColorTheme.gold)
                    }
                }
            }
            .alert("Add Points Program", isPresented: $showAddProgram) {
                TextField("Program Name (e.g. Chase UR)", text: $newProgramName)
                Button("Cancel", role: .cancel) {
                    newProgramName = ""
                }
                Button("Add") {
                    let name = newProgramName.trimmingCharacters(in: .whitespaces)
                    if !name.isEmpty {
                        store.updatePoints(type: name, balance: 0)
                    }
                    newProgramName = ""
                }
            }
        }
    }

    @ViewBuilder
    private func pointsTile(program: String, balance: Double) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(program)
                .font(.caption.weight(.medium))
                .foregroundColor(ColorTheme.textSecondary)
                .lineLimit(1)

            if editingProgram == program {
                HStack(spacing: 8) {
                    TextField("Balance", text: $editValue)
                        .keyboardType(.decimalPad)
                        .font(.title3.weight(.bold))
                        .foregroundColor(ColorTheme.gold)
                        .textFieldStyle(.plain)
                        .onSubmit { commitEdit(program: program) }

                    Button(action: { commitEdit(program: program) }) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(ColorTheme.green)
                    }
                }
            } else {
                Text(formatPoints(balance))
                    .font(.title3.weight(.bold))
                    .foregroundColor(ColorTheme.gold)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(ColorTheme.cardBg)
        .cornerRadius(12)
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(ColorTheme.border, lineWidth: 1))
        .onTapGesture {
            editingProgram = program
            editValue = balance == 0 ? "" : String(Int(balance))
        }
    }

    private func commitEdit(program: String) {
        let value = Double(editValue) ?? 0
        store.updatePoints(type: program, balance: value)
        editingProgram = nil
        editValue = ""
    }

    private func formatPoints(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: value)) ?? "0"
    }
}
