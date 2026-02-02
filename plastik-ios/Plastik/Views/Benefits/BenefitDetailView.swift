import SwiftUI

struct BenefitDetailView: View {
    let benefit: CardBenefit
    let cardName: String

    var body: some View {
        List {
            Section("Benefit") {
                LabeledContent("Name", value: benefit.name)
                LabeledContent("Value", value: benefit.formattedValue)
                LabeledContent("Category", value: benefit.category.displayName)
                LabeledContent("Reset Period", value: benefit.resetPeriod.displayName)
            }

            Section("Card") {
                LabeledContent("Card", value: cardName)
            }
        }
        .navigationTitle(benefit.name)
    }
}
