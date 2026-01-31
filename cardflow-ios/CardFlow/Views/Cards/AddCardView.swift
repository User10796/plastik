import SwiftUI

struct AddCardView: View {
    @Environment(DataStore.self) private var store
    @Environment(\.dismiss) private var dismiss

    // MARK: - State

    @State private var name = ""
    @State private var issuer = ""
    @State private var holder = ""
    @State private var annualFee: Double = 0
    @State private var apr: Double = 0
    @State private var creditLimit: Double = 0
    @State private var openDate = Date()
    @State private var anniversaryDate = Date()
    @State private var pointsType = ""

    // Optional signup bonus
    @State private var addSignupBonus = false
    @State private var bonusTarget: Double = 0
    @State private var bonusCurrent: Double = 0
    @State private var bonusReward: Double = 0
    @State private var bonusRewardType = "points"
    @State private var bonusDeadline: Date? = nil

    // MARK: - Body

    var body: some View {
        NavigationStack {
            Form {
                cardInfoSection
                financialsSection
                datesSection
                bonusSection
            }
            .scrollContentBackground(.hidden)
            .background(ColorTheme.background)
            .navigationTitle("Add Card")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundColor(ColorTheme.textSecondary)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { saveCard() }
                        .foregroundColor(ColorTheme.gold)
                        .fontWeight(.semibold)
                        .disabled(name.isEmpty || issuer.isEmpty)
                }
            }
            .onAppear {
                if holder.isEmpty, let first = store.holders.first {
                    holder = first
                }
            }
        }
    }

    // MARK: - Sections

    private var cardInfoSection: some View {
        Section {
            styledTextField("Card Name", text: $name, prompt: "e.g. Sapphire Preferred")
            styledTextField("Issuer", text: $issuer, prompt: "e.g. Chase")

            Picker("Holder", selection: $holder) {
                ForEach(store.holders, id: \.self) { h in
                    Text(h).tag(h)
                }
            }
            .listRowBackground(ColorTheme.cardBg)
            .foregroundColor(ColorTheme.textPrimary)

            styledTextField("Points Type", text: $pointsType, prompt: "e.g. Ultimate Rewards")
        } header: {
            Text("Card Info")
                .foregroundColor(ColorTheme.gold)
        }
    }

    private var financialsSection: some View {
        Section {
            currencyField("Annual Fee", value: $annualFee)
            percentField("APR", value: $apr)
            currencyField("Credit Limit", value: $creditLimit)
        } header: {
            Text("Financials")
                .foregroundColor(ColorTheme.gold)
        }
    }

    private var datesSection: some View {
        Section {
            styledDatePicker("Open Date", selection: $openDate)
            styledDatePicker("Anniversary Date", selection: $anniversaryDate)
        } header: {
            Text("Dates")
                .foregroundColor(ColorTheme.gold)
        }
    }

    private var bonusSection: some View {
        Section {
            Toggle("Add Signup Bonus", isOn: $addSignupBonus)
                .listRowBackground(ColorTheme.cardBg)
                .foregroundColor(ColorTheme.textPrimary)
                .tint(ColorTheme.gold)

            if addSignupBonus {
                currencyField("Spend Target", value: $bonusTarget)
                currencyField("Current Spend", value: $bonusCurrent)

                HStack {
                    Text("Reward")
                        .foregroundColor(ColorTheme.textSecondary)
                    Spacer()
                    TextField("0", value: $bonusReward, format: .number)
                        .keyboardType(.decimalPad)
                        .multilineTextAlignment(.trailing)
                        .foregroundColor(ColorTheme.textPrimary)
                }
                .listRowBackground(ColorTheme.cardBg)

                Picker("Reward Type", selection: $bonusRewardType) {
                    Text("Points").tag("points")
                    Text("Miles").tag("miles")
                    Text("Cash Back").tag("cashback")
                    Text("Statement Credit").tag("credit")
                }
                .listRowBackground(ColorTheme.cardBg)
                .foregroundColor(ColorTheme.textPrimary)

                if let deadline = bonusDeadline {
                    styledDatePicker("Deadline", selection: Binding(
                        get: { deadline },
                        set: { bonusDeadline = $0 }
                    ))
                    Button("Remove Deadline") { bonusDeadline = nil }
                        .listRowBackground(ColorTheme.cardBg)
                        .foregroundColor(ColorTheme.red)
                        .font(.caption)
                } else {
                    Button("Set Deadline") {
                        bonusDeadline = Calendar.current.date(byAdding: .month, value: 3, to: Date()) ?? Date()
                    }
                    .listRowBackground(ColorTheme.cardBg)
                    .foregroundColor(ColorTheme.gold)
                }
            }
        } header: {
            Text("Signup Bonus")
                .foregroundColor(ColorTheme.gold)
        }
    }

    // MARK: - Reusable Field Helpers

    private func styledTextField(_ label: String, text: Binding<String>, prompt: String? = nil) -> some View {
        HStack {
            Text(label)
                .foregroundColor(ColorTheme.textSecondary)
            Spacer()
            TextField(prompt ?? label, text: text)
                .multilineTextAlignment(.trailing)
                .foregroundColor(ColorTheme.textPrimary)
        }
        .listRowBackground(ColorTheme.cardBg)
    }

    private func currencyField(_ label: String, value: Binding<Double>) -> some View {
        HStack {
            Text(label)
                .foregroundColor(ColorTheme.textSecondary)
            Spacer()
            TextField("$0.00", value: value, format: .currency(code: "USD"))
                .keyboardType(.decimalPad)
                .multilineTextAlignment(.trailing)
                .foregroundColor(ColorTheme.textPrimary)
        }
        .listRowBackground(ColorTheme.cardBg)
    }

    private func percentField(_ label: String, value: Binding<Double>) -> some View {
        HStack {
            Text(label)
                .foregroundColor(ColorTheme.textSecondary)
            Spacer()
            TextField("0.00", value: value, format: .number)
                .keyboardType(.decimalPad)
                .multilineTextAlignment(.trailing)
                .foregroundColor(ColorTheme.textPrimary)
            Text("%")
                .foregroundColor(ColorTheme.textMuted)
        }
        .listRowBackground(ColorTheme.cardBg)
    }

    private func styledDatePicker(_ label: String, selection: Binding<Date>) -> some View {
        DatePicker(label, selection: selection, displayedComponents: .date)
            .foregroundColor(ColorTheme.textSecondary)
            .tint(ColorTheme.gold)
            .listRowBackground(ColorTheme.cardBg)
    }

    // MARK: - Save

    private func saveCard() {
        let iso = Formatters.dateISO

        var newCard = CreditCard()
        newCard.name = name
        newCard.issuer = issuer
        newCard.holder = holder
        newCard.annualFee = annualFee
        newCard.apr = apr
        newCard.creditLimit = creditLimit
        newCard.openDate = iso.string(from: openDate)
        newCard.anniversaryDate = iso.string(from: anniversaryDate)
        newCard.pointsType = pointsType.isEmpty ? nil : pointsType

        if addSignupBonus {
            var bonus = SignupBonus()
            bonus.target = bonusTarget
            bonus.current = bonusCurrent
            bonus.reward = bonusReward
            bonus.rewardType = bonusRewardType
            bonus.completed = false
            if let dl = bonusDeadline {
                bonus.deadline = iso.string(from: dl)
            }
            newCard.signupBonus = bonus
        }

        store.addCard(newCard)
        dismiss()
    }
}
