import SwiftUI

struct PayoffCalculatorView: View {
    @State private var balance: String = ""
    @State private var apr: String = ""
    @State private var monthlyPayment: String = ""
    @State private var calculationResult: PayoffResult?

    struct PayoffResult {
        let months: Int
        let totalInterest: Double
        let totalPaid: Double
    }

    var body: some View {
        Form {
            Section("Card Details") {
                HStack {
                    Text("Current Balance")
                    Spacer()
                    TextField("$0", text: $balance)
                        .multilineTextAlignment(.trailing)
                        #if os(iOS)
                        .keyboardType(.decimalPad)
                        #endif
                }

                HStack {
                    Text("APR")
                    Spacer()
                    TextField("0%", text: $apr)
                        .multilineTextAlignment(.trailing)
                        #if os(iOS)
                        .keyboardType(.decimalPad)
                        #endif
                }

                HStack {
                    Text("Monthly Payment")
                    Spacer()
                    TextField("$0", text: $monthlyPayment)
                        .multilineTextAlignment(.trailing)
                        #if os(iOS)
                        .keyboardType(.decimalPad)
                        #endif
                }
            }

            Section {
                Button("Calculate Payoff") {
                    calculatePayoff()
                }
                .frame(maxWidth: .infinity)
                .disabled(!isValidInput)
            }

            if let result = calculationResult {
                Section("Results") {
                    LabeledContent("Time to Pay Off") {
                        Text("\(result.months) months")
                            .font(.headline)
                            .foregroundStyle(.blue)
                    }

                    LabeledContent("Total Interest") {
                        Text("$\(String(format: "%.2f", result.totalInterest))")
                            .foregroundStyle(.red)
                    }

                    LabeledContent("Total Amount Paid") {
                        Text("$\(String(format: "%.2f", result.totalPaid))")
                    }
                }

                Section("Payoff Strategies") {
                    StrategyRow(
                        title: "Increase Monthly Payment",
                        detail: "Pay $50 more/month to save \(savingsWithExtra50) in interest",
                        icon: "arrow.up.circle"
                    )

                    StrategyRow(
                        title: "Balance Transfer",
                        detail: "Transfer to a 0% APR card to eliminate interest",
                        icon: "arrow.left.arrow.right.circle"
                    )

                    StrategyRow(
                        title: "Debt Avalanche",
                        detail: "Pay highest APR cards first to minimize interest",
                        icon: "chart.line.downtrend.xyaxis"
                    )
                }
            }

            Section("Tips") {
                VStack(alignment: .leading, spacing: 8) {
                    Text("• Always pay more than the minimum")
                        .font(.caption)
                    Text("• Consider balance transfer offers for high-APR debt")
                        .font(.caption)
                    Text("• Set up autopay to avoid late fees")
                        .font(.caption)
                    Text("• Pay before statement close for better utilization")
                        .font(.caption)
                }
                .foregroundStyle(.secondary)
            }
        }
        .navigationTitle("Payoff Calculator")
    }

    private var isValidInput: Bool {
        guard let bal = Double(balance), bal > 0,
              let rate = Double(apr), rate > 0,
              let payment = Double(monthlyPayment), payment > 0 else {
            return false
        }
        return payment > (bal * (rate / 100 / 12)) // Payment must exceed monthly interest
    }

    private func calculatePayoff() {
        guard let bal = Double(balance),
              let rate = Double(apr),
              let payment = Double(monthlyPayment) else {
            return
        }

        let monthlyRate = rate / 100 / 12
        var remaining = bal
        var months = 0
        var totalInterest = 0.0

        while remaining > 0 && months < 360 { // Max 30 years
            let interest = remaining * monthlyRate
            totalInterest += interest
            remaining = remaining + interest - payment
            months += 1

            if remaining < 0 {
                remaining = 0
            }
        }

        calculationResult = PayoffResult(
            months: months,
            totalInterest: totalInterest,
            totalPaid: bal + totalInterest
        )
    }

    private var savingsWithExtra50: String {
        guard let result = calculationResult,
              let bal = Double(balance),
              let rate = Double(apr),
              let payment = Double(monthlyPayment) else {
            return "$0"
        }

        let monthlyRate = rate / 100 / 12
        var remaining = bal
        var months = 0
        var totalInterest = 0.0
        let newPayment = payment + 50

        while remaining > 0 && months < 360 {
            let interest = remaining * monthlyRate
            totalInterest += interest
            remaining = remaining + interest - newPayment
            months += 1

            if remaining < 0 {
                remaining = 0
            }
        }

        let savings = result.totalInterest - totalInterest
        return "$\(String(format: "%.0f", max(0, savings)))"
    }
}

struct StrategyRow: View {
    let title: String
    let detail: String
    let icon: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(.green)
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline.bold())
                Text(detail)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 2)
    }
}

#Preview {
    NavigationStack {
        PayoffCalculatorView()
    }
}
