import SwiftUI

struct EditCardView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(CardViewModel.self) private var viewModel
    @Environment(DataFeedService.self) private var feedService

    @Binding var userCard: UserCard
    let catalogCard: CreditCard?

    // Edit state
    @State private var nickname: String = ""
    @State private var lastFourDigits: String = ""
    @State private var selectedIssuer: Issuer?
    @State private var productName: String = ""
    @State private var selectedNetwork: CardNetwork = .visa
    @State private var annualFee: String = ""
    @State private var foreignTransactionFee: String = ""
    @State private var openDate: Date = Date()
    @State private var cardStatus: CardStatus = .active
    @State private var notes: String = ""

    // Signup bonus state
    @State private var bonusAmount: String = ""
    @State private var bonusType: RewardType = .points
    @State private var spendRequirement: String = ""
    @State private var timeframeDays: String = "90"
    @State private var bonusEarned: BonusEarnedStatus = .inProgress

    // Reward categories
    @State private var rewardCategories: [UserRewardCategory] = []
    @State private var showAddCategory = false
    @State private var editingCategory: UserRewardCategory?

    // Card icon color
    @State private var cardIconColor: String = ""
    @State private var showColorPicker = false

    // Report sheet
    @State private var showReportSheet = false

    // Preset card icon colors
    private let presetColors: [(name: String, hex: String)] = [
        ("Blue", "004879"),
        ("Navy", "1a1a2e"),
        ("Purple", "7B2D8B"),
        ("Red", "CC2222"),
        ("Gold", "B4975A"),
        ("Silver", "A9A9A9"),
        ("Green", "1B5E3C"),
        ("Teal", "008080"),
        ("Orange", "E35205"),
        ("Black", "1a1a1a"),
        ("Rose", "C4536A"),
        ("Sky", "00AEEF"),
    ]

    init(userCard: Binding<UserCard>, catalogCard: CreditCard?) {
        self._userCard = userCard
        self.catalogCard = catalogCard
    }

    var body: some View {
        NavigationStack {
            Form {
                basicInfoSection
                cardIconColorSection
                feesSection
                signupBonusSection
                rewardCategoriesSection
                cardInfoSection
                reportSection
            }
            #if os(macOS)
            .formStyle(.grouped)
            .frame(minWidth: 500, minHeight: 600)
            #endif
            .navigationTitle("Edit Card")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveChanges()
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
            .onAppear {
                loadCurrentValues()
            }
            .sheet(isPresented: $showAddCategory) {
                EditCategorySheet(
                    category: nil,
                    onSave: { newCategory in
                        rewardCategories.append(newCategory)
                    }
                )
            }
            .sheet(item: $editingCategory) { category in
                EditCategorySheet(
                    category: category,
                    onSave: { updatedCategory in
                        if let index = rewardCategories.firstIndex(where: { $0.id == updatedCategory.id }) {
                            rewardCategories[index] = updatedCategory
                        }
                    }
                )
            }
            .sheet(isPresented: $showReportSheet) {
                ReportDataIssueView(
                    cardName: catalogCard?.name ?? userCard.nickname ?? "Unknown Card",
                    issuerName: catalogCard?.issuer.displayName ?? selectedIssuer?.displayName ?? "Unknown",
                    catalogId: userCard.cardId
                )
            }
        }
    }

    // MARK: - Card Icon Color Section

    private var cardIconColorSection: some View {
        Section {
            VStack(alignment: .leading, spacing: 8) {
                Text("Choose a color for the card icon throughout the app and widget.")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                // Color preview
                HStack(spacing: 12) {
                    RoundedRectangle(cornerRadius: 6)
                        .fill(
                            cardIconColor.isEmpty
                                ? LinearGradient(colors: defaultGradientColors, startPoint: .topLeading, endPoint: .bottomTrailing)
                                : LinearGradient(colors: [Color(hex: cardIconColor), Color(hex: cardIconColor).opacity(0.7)], startPoint: .topLeading, endPoint: .bottomTrailing)
                        )
                        .frame(width: 48, height: 30)
                        .shadow(color: .black.opacity(0.15), radius: 2, x: 0, y: 1)

                    Text(cardIconColor.isEmpty ? "Default (issuer color)" : "Custom")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    Spacer()

                    if !cardIconColor.isEmpty {
                        Button("Reset") {
                            cardIconColor = ""
                        }
                        .font(.caption)
                    }
                }

                // Preset color grid
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 6), spacing: 8) {
                    ForEach(presetColors, id: \.hex) { preset in
                        Button {
                            cardIconColor = preset.hex
                        } label: {
                            VStack(spacing: 2) {
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(Color(hex: preset.hex))
                                    .frame(height: 28)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 4)
                                            .stroke(cardIconColor == preset.hex ? Color.blue : Color.clear, lineWidth: 2)
                                    )
                                Text(preset.name)
                                    .font(.system(size: 9))
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .padding(.vertical, 4)
        } header: {
            Text("Card Icon Color")
        }
    }

    private var defaultGradientColors: [Color] {
        if let card = catalogCard {
            // Simplified fallback - just use issuer color
            switch card.issuer {
            case .chase: return [Color(hex: "004879"), Color(hex: "1a6bb3")]
            case .amex: return [Color(hex: "006FCF"), Color(hex: "00A1E4")]
            case .capitalOne: return [Color(hex: "D03027"), Color(hex: "a02620")]
            case .citi: return [Color(hex: "003B70"), Color(hex: "0066b2")]
            default: return [Color(hex: "4a5568"), Color(hex: "2d3748")]
            }
        }
        return [Color(hex: "4a5568"), Color(hex: "2d3748")]
    }

    // MARK: - Basic Info Section

    private var basicInfoSection: some View {
        Section {
            #if os(macOS)
            TextField("Card Nickname", text: $nickname)
                .textFieldStyle(.roundedBorder)
            #else
            TextField("Card Nickname", text: $nickname)
            #endif

            Picker("Issuer", selection: $selectedIssuer) {
                Text("Select Issuer").tag(nil as Issuer?)
                ForEach(Issuer.allCases) { issuer in
                    Text(issuer.displayName).tag(issuer as Issuer?)
                }
            }

            #if os(macOS)
            TextField("Product Name", text: $productName)
                .autocorrectionDisabled()
                .textFieldStyle(.roundedBorder)
            #else
            TextField("Product Name", text: $productName)
                .autocorrectionDisabled()
            #endif

            Picker("Network", selection: $selectedNetwork) {
                ForEach(CardNetwork.allCases, id: \.self) { network in
                    Text(network.displayName).tag(network)
                }
            }

            DatePicker("Card Opened", selection: $openDate, displayedComponents: .date)
        } header: {
            Text("Basic Info")
        } footer: {
            if catalogCard != nil {
                Text("Override catalog values if they're incorrect.")
            }
        }
    }

    // MARK: - Fees Section

    private var feesSection: some View {
        Section("Fees") {
            LabeledContent("Annual Fee") {
                HStack(spacing: 4) {
                    Text("$")
                        .foregroundStyle(.secondary)
                    TextField("0", text: $annualFee)
                        .multilineTextAlignment(.trailing)
                        .frame(width: 80)
                        #if os(iOS)
                        .keyboardType(.numberPad)
                        #else
                        .textFieldStyle(.roundedBorder)
                        #endif
                }
            }

            LabeledContent("Foreign Transaction Fee") {
                HStack(spacing: 4) {
                    TextField("0", text: $foreignTransactionFee)
                        .multilineTextAlignment(.trailing)
                        .frame(width: 60)
                        #if os(iOS)
                        .keyboardType(.decimalPad)
                        #else
                        .textFieldStyle(.roundedBorder)
                        #endif
                    Text("%")
                        .foregroundStyle(.secondary)
                }
            }

            if let catalog = catalogCard {
                HStack {
                    Image(systemName: "info.circle")
                        .foregroundStyle(.blue)
                        .font(.caption)
                    Text("Catalog: $\(catalog.annualFee) annual fee")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    // MARK: - Signup Bonus Section

    private var signupBonusSection: some View {
        Section {
            Picker("Bonus Type", selection: $bonusType) {
                ForEach(RewardType.allCases, id: \.self) { type in
                    Text(type.displayName).tag(type)
                }
            }

            LabeledContent("Bonus Amount") {
                HStack(spacing: 4) {
                    TextField("0", text: $bonusAmount)
                        .multilineTextAlignment(.trailing)
                        .frame(width: 100)
                        #if os(iOS)
                        .keyboardType(.numberPad)
                        #else
                        .textFieldStyle(.roundedBorder)
                        #endif
                    Text(bonusType == .cashBack ? "$" : "pts")
                        .foregroundStyle(.secondary)
                        .frame(width: 30)
                }
            }

            LabeledContent("Spend Requirement") {
                HStack(spacing: 4) {
                    Text("$")
                        .foregroundStyle(.secondary)
                    TextField("0", text: $spendRequirement)
                        .multilineTextAlignment(.trailing)
                        .frame(width: 80)
                        #if os(iOS)
                        .keyboardType(.numberPad)
                        #else
                        .textFieldStyle(.roundedBorder)
                        #endif
                }
            }

            LabeledContent("Timeframe") {
                HStack(spacing: 4) {
                    TextField("90", text: $timeframeDays)
                        .multilineTextAlignment(.trailing)
                        .frame(width: 60)
                        #if os(iOS)
                        .keyboardType(.numberPad)
                        #else
                        .textFieldStyle(.roundedBorder)
                        #endif
                    Text("days")
                        .foregroundStyle(.secondary)
                }
            }

            Picker("Bonus Status", selection: $bonusEarned) {
                ForEach(BonusEarnedStatus.allCases, id: \.self) { status in
                    Text(status.displayName).tag(status)
                }
            }

            if let catalog = catalogCard, let bonus = catalog.signupBonus {
                HStack {
                    Image(systemName: "info.circle")
                        .foregroundStyle(.blue)
                        .font(.caption)
                    Text("Catalog: \(bonus.points.commaFormatted) \(bonus.currency) after $\(bonus.spendRequired.commaFormatted) in \(bonus.timeframeDays) days")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        } header: {
            Text("Signup Bonus")
        }
    }

    // MARK: - Reward Categories Section

    private var rewardCategoriesSection: some View {
        Section {
            if rewardCategories.isEmpty {
                HStack {
                    Spacer()
                    VStack(spacing: 8) {
                        Image(systemName: "rectangle.stack.badge.plus")
                            .font(.title2)
                            .foregroundStyle(.secondary)
                        Text("No custom categories")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 12)
                    Spacer()
                }
            } else {
                ForEach(rewardCategories) { category in
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(category.categoryName)
                                .font(.body)
                            if let cap = category.formattedCap {
                                Text("Cap: \(cap)")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }

                        Spacer()

                        Text(category.formattedRate)
                            .font(.headline)
                            .foregroundStyle(.blue)

                        Text(category.rewardType.displayName.lowercased())
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        editingCategory = category
                    }
                }
                .onDelete { indexSet in
                    rewardCategories.remove(atOffsets: indexSet)
                }
            }

            Button {
                showAddCategory = true
            } label: {
                Label("Add Category", systemImage: "plus")
            }

            if let catalog = catalogCard, !catalog.earningRates.isEmpty {
                DisclosureGroup {
                    ForEach(catalog.earningRates) { rate in
                        HStack {
                            Image(systemName: rate.category.icon)
                                .frame(width: 24)
                                .foregroundStyle(.blue)
                            Text(rate.category.displayName)
                            Spacer()
                            Text(rate.multiplier.multiplierFormatted)
                                .foregroundStyle(.secondary)
                        }
                        .font(.caption)
                    }
                } label: {
                    HStack {
                        Image(systemName: "info.circle")
                            .foregroundStyle(.blue)
                        Text("Catalog Earning Rates")
                    }
                    .font(.caption)
                }
            }
        } header: {
            Text("Bonus Categories")
        } footer: {
            Text("Add custom reward categories to override or supplement catalog data.")
        }
    }

    // MARK: - Card Info Section

    private var cardInfoSection: some View {
        Section("Additional Details") {
            TextField("Last 4 Digits", text: $lastFourDigits)
                #if os(iOS)
                .keyboardType(.numberPad)
                #else
                .textFieldStyle(.roundedBorder)
                #endif

            Picker("Status", selection: $cardStatus) {
                ForEach(CardStatus.allCases, id: \.self) { status in
                    Label(status.displayName, systemImage: status.icon)
                        .tag(status)
                }
            }

            VStack(alignment: .leading, spacing: 4) {
                Text("Notes")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                TextEditor(text: $notes)
                    .frame(minHeight: 80)
                    #if os(iOS)
                    .scrollContentBackground(.hidden)
                    .background(Color(.tertiarySystemBackground))
                    #else
                    .scrollContentBackground(.hidden)
                    .background(Color(nsColor: .textBackgroundColor))
                    #endif
                    .cornerRadius(8)
            }
        }
    }

    // MARK: - Report Section

    private var reportSection: some View {
        Section {
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 8) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(.orange)
                    Text("Report Incorrect Catalog Data")
                        .font(.headline)
                }

                Text("Found an error in the default card info? Let us know so we can fix it for everyone.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                Button {
                    showReportSheet = true
                } label: {
                    Text("Report Data Issue")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
            }
            .padding(.vertical, 8)
        }
    }

    // MARK: - Load/Save

    private func loadCurrentValues() {
        // Load from user card or catalog
        nickname = userCard.nickname ?? ""
        lastFourDigits = userCard.lastFourDigits ?? ""
        openDate = userCard.openDate
        cardStatus = userCard.cardStatus
        notes = userCard.notes ?? ""

        // Issuer
        if let override = userCard.issuerOverride, let issuer = Issuer(rawValue: override) {
            selectedIssuer = issuer
        } else if let catalog = catalogCard {
            selectedIssuer = catalog.issuer
        }

        // Product name
        productName = userCard.productNameOverride ?? catalogCard?.name ?? ""

        // Network
        if let override = userCard.networkOverride, let network = CardNetwork(rawValue: override) {
            selectedNetwork = network
        } else if let catalog = catalogCard {
            selectedNetwork = catalog.network
        }

        // Annual fee
        if let override = userCard.annualFeeOverride {
            annualFee = "\(override)"
        } else if let catalog = catalogCard {
            annualFee = "\(catalog.annualFee)"
        }

        // Foreign transaction fee
        if let override = userCard.foreignTransactionFeeOverride {
            foreignTransactionFee = String(format: "%.1f", override)
        }

        // Signup bonus
        if let override = userCard.signupBonusOverride {
            bonusAmount = "\(override.bonusAmount)"
            bonusType = override.bonusType
            spendRequirement = "\(override.spendRequirement)"
            timeframeDays = "\(override.timeframeDays)"
            bonusEarned = override.bonusEarned
        } else if let catalog = catalogCard, let bonus = catalog.signupBonus {
            bonusAmount = "\(bonus.points)"
            bonusType = .points // Catalog always uses points
            spendRequirement = "\(bonus.spendRequired)"
            timeframeDays = "\(bonus.timeframeDays)"
            bonusEarned = userCard.signupBonusProgress?.completed == true ? .yes : .inProgress
        }

        // Reward categories
        rewardCategories = userCard.rewardCategoriesOverride ?? []

        // Card icon color
        cardIconColor = userCard.cardIconColor ?? ""
    }

    private func saveChanges() {
        // Basic info
        userCard.nickname = nickname.isEmpty ? nil : nickname
        userCard.lastFourDigits = lastFourDigits.isEmpty ? nil : lastFourDigits
        userCard.openDate = openDate
        userCard.cardStatus = cardStatus
        userCard.notes = notes.isEmpty ? nil : notes
        userCard.isActive = cardStatus == .active

        // Handle closed date based on status
        if cardStatus == .closed && userCard.closedDate == nil {
            userCard.closedDate = Date()
        } else if cardStatus == .active {
            userCard.closedDate = nil
        }

        // Overrides - only save if different from catalog
        if let catalog = catalogCard {
            // Issuer override
            if let selected = selectedIssuer, selected != catalog.issuer {
                userCard.issuerOverride = selected.rawValue
            } else {
                userCard.issuerOverride = nil
            }

            // Product name override
            if productName != catalog.name && !productName.isEmpty {
                userCard.productNameOverride = productName
            } else {
                userCard.productNameOverride = nil
            }

            // Network override
            if selectedNetwork != catalog.network {
                userCard.networkOverride = selectedNetwork.rawValue
            } else {
                userCard.networkOverride = nil
            }

            // Annual fee override
            if let feeValue = Int(annualFee), feeValue != catalog.annualFee {
                userCard.annualFeeOverride = feeValue
            } else {
                userCard.annualFeeOverride = nil
            }
        } else {
            // No catalog card - save all values as overrides
            userCard.issuerOverride = selectedIssuer?.rawValue
            userCard.productNameOverride = productName.isEmpty ? nil : productName
            userCard.networkOverride = selectedNetwork.rawValue
            userCard.annualFeeOverride = Int(annualFee)
        }

        // Foreign transaction fee (always override since catalog doesn't have this)
        if let feeValue = Double(foreignTransactionFee), feeValue >= 0 {
            userCard.foreignTransactionFeeOverride = feeValue
        } else {
            userCard.foreignTransactionFeeOverride = nil
        }

        // Signup bonus override
        if let amount = Int(bonusAmount), amount > 0 {
            userCard.signupBonusOverride = SignupBonusOverride(
                bonusAmount: amount,
                bonusType: bonusType,
                spendRequirement: Int(spendRequirement) ?? 0,
                timeframeDays: Int(timeframeDays) ?? 90,
                expirationDate: nil,
                bonusEarned: bonusEarned
            )
        } else {
            userCard.signupBonusOverride = nil
        }

        // Reward categories
        if !rewardCategories.isEmpty {
            userCard.rewardCategoriesOverride = rewardCategories
        } else {
            userCard.rewardCategoriesOverride = nil
        }

        // Card icon color
        userCard.cardIconColor = cardIconColor.isEmpty ? nil : cardIconColor

        userCard.lastModified = Date()
        viewModel.updateCard(userCard)
    }
}

// MARK: - Edit Category Sheet

struct EditCategorySheet: View {
    @Environment(\.dismiss) private var dismiss

    let category: UserRewardCategory?
    let onSave: (UserRewardCategory) -> Void

    @State private var categoryName: String = ""
    @State private var customCategoryName: String = ""
    @State private var rewardRate: String = ""
    @State private var rewardType: RewardType = .points
    @State private var hasCap: Bool = false
    @State private var capAmount: String = ""
    @State private var capPeriod: CapPeriodType = .quarterly
    @State private var notes: String = ""

    private let presetCategories = [
        "Dining", "Groceries", "Travel", "Gas", "Streaming",
        "Hotels", "Airlines", "Uber/Lyft", "Online Shopping",
        "Drugstores", "Home Improvement", "Entertainment", "Other"
    ]

    var body: some View {
        NavigationStack {
            Form {
                Section("Category") {
                    Picker("Category", selection: $categoryName) {
                        Text("Select...").tag("")
                        ForEach(presetCategories, id: \.self) { cat in
                            Text(cat).tag(cat)
                        }
                        Text("Custom...").tag("__custom__")
                    }

                    if categoryName == "__custom__" {
                        TextField("Custom Category Name", text: $customCategoryName)
                            #if os(macOS)
                            .textFieldStyle(.roundedBorder)
                            #endif
                    }
                }

                Section("Reward") {
                    LabeledContent("Rate") {
                        HStack(spacing: 4) {
                            TextField("0", text: $rewardRate)
                                .multilineTextAlignment(.trailing)
                                .frame(width: 60)
                                #if os(iOS)
                                .keyboardType(.decimalPad)
                                #else
                                .textFieldStyle(.roundedBorder)
                                #endif
                            Text(rewardType == .cashBack ? "%" : "x")
                                .foregroundStyle(.secondary)
                        }
                    }

                    Picker("Type", selection: $rewardType) {
                        ForEach(RewardType.allCases, id: \.self) { type in
                            Text(type.displayName).tag(type)
                        }
                    }
                }

                Section {
                    Toggle("Has Spending Cap", isOn: $hasCap)

                    if hasCap {
                        LabeledContent("Cap Amount") {
                            HStack(spacing: 4) {
                                Text("$")
                                    .foregroundStyle(.secondary)
                                TextField("0", text: $capAmount)
                                    .multilineTextAlignment(.trailing)
                                    .frame(width: 80)
                                    #if os(iOS)
                                    .keyboardType(.numberPad)
                                    #else
                                    .textFieldStyle(.roundedBorder)
                                    #endif
                            }
                        }

                        Picker("Cap Period", selection: $capPeriod) {
                            ForEach(CapPeriodType.allCases, id: \.self) { period in
                                Text(period.displayName).tag(period)
                            }
                        }
                    }
                } header: {
                    Text("Spending Cap")
                } footer: {
                    Text("Some cards limit bonus earnings to a maximum spend amount per period.")
                }

                Section("Notes (Optional)") {
                    TextField("e.g., Online groceries only", text: $notes)
                        #if os(macOS)
                        .textFieldStyle(.roundedBorder)
                        #endif
                }
            }
            #if os(macOS)
            .formStyle(.grouped)
            .frame(minWidth: 400, minHeight: 400)
            #endif
            .navigationTitle(category == nil ? "Add Category" : "Edit Category")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveCategory()
                        dismiss()
                    }
                    .disabled(!isValid)
                }
            }
            .onAppear {
                loadCategory()
            }
        }
    }

    private var isValid: Bool {
        let name = categoryName == "__custom__" ? customCategoryName : categoryName
        return !name.isEmpty && (Double(rewardRate) ?? 0) > 0
    }

    private func loadCategory() {
        guard let category = category else { return }

        if presetCategories.contains(category.categoryName) {
            categoryName = category.categoryName
        } else {
            categoryName = "__custom__"
            customCategoryName = category.categoryName
        }

        rewardRate = String(format: "%.1f", category.rewardRate)
        rewardType = category.rewardType

        if let cap = category.capAmount {
            hasCap = true
            capAmount = "\(cap)"
            capPeriod = category.capPeriod ?? .quarterly
        }

        notes = category.notes ?? ""
    }

    private func saveCategory() {
        let name = categoryName == "__custom__" ? customCategoryName : categoryName
        let rate = Double(rewardRate) ?? 0

        let newCategory = UserRewardCategory(
            id: category?.id ?? UUID(),
            categoryName: name,
            rewardRate: rate,
            rewardType: rewardType,
            capAmount: hasCap ? Int(capAmount) : nil,
            capPeriod: hasCap ? capPeriod : nil,
            notes: notes.isEmpty ? nil : notes
        )

        onSave(newCategory)
    }
}

// MARK: - Report Data Issue View

struct ReportDataIssueView: View {
    @Environment(\.dismiss) private var dismiss

    let cardName: String
    let issuerName: String
    let catalogId: String

    @State private var issueTypes: Set<IssueType> = []
    @State private var correctValues: String = ""
    @State private var sourceURL: String = ""
    @State private var userEmail: String = ""
    @State private var showMailComposer = false

    enum IssueType: String, CaseIterable, Identifiable {
        case annualFee = "Annual fee"
        case signupBonus = "Signup bonus"
        case bonusCategories = "Bonus categories"
        case rewardRates = "Reward rates"
        case cardNetwork = "Card network"
        case other = "Other"

        var id: String { rawValue }
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    LabeledContent("Card", value: cardName)
                    LabeledContent("Issuer", value: issuerName)
                }

                Section {
                    ForEach(IssueType.allCases) { issue in
                        Toggle(issue.rawValue, isOn: Binding(
                            get: { issueTypes.contains(issue) },
                            set: { isOn in
                                if isOn {
                                    issueTypes.insert(issue)
                                } else {
                                    issueTypes.remove(issue)
                                }
                            }
                        ))
                    }
                } header: {
                    Text("What's incorrect?")
                } footer: {
                    Text("Select all that apply")
                }

                Section("Correct Values (Optional)") {
                    TextEditor(text: $correctValues)
                        .frame(minHeight: 80)
                        #if os(iOS)
                        .scrollContentBackground(.hidden)
                        .background(Color(.tertiarySystemBackground))
                        #else
                        .scrollContentBackground(.hidden)
                        .background(Color(nsColor: .textBackgroundColor))
                        #endif
                        .cornerRadius(8)
                }

                Section("Source URL (Optional)") {
                    TextField("https://...", text: $sourceURL)
                        .autocorrectionDisabled()
                        #if os(iOS)
                        .textInputAutocapitalization(.never)
                        .keyboardType(.URL)
                        #else
                        .textFieldStyle(.roundedBorder)
                        #endif
                }

                Section("Your Email (Optional)") {
                    TextField("For follow-up questions", text: $userEmail)
                        .autocorrectionDisabled()
                        #if os(iOS)
                        .textInputAutocapitalization(.never)
                        .keyboardType(.emailAddress)
                        #else
                        .textFieldStyle(.roundedBorder)
                        #endif
                }
            }
            #if os(macOS)
            .formStyle(.grouped)
            .frame(minWidth: 450, minHeight: 500)
            #endif
            .navigationTitle("Report Issue")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Send") {
                        sendReport()
                    }
                    .disabled(issueTypes.isEmpty)
                }
            }
        }
    }

    private func sendReport() {
        let subject = "Plastik Data Report: \(issuerName) \(cardName)"
        let issueList = issueTypes.map { $0.rawValue }.joined(separator: ", ")

        let body = """
        Card: \(issuerName) \(cardName)
        Catalog ID: \(catalogId)

        Issues reported:
        \(issueList)

        Correct values:
        \(correctValues.isEmpty ? "(not provided)" : correctValues)

        Source URL:
        \(sourceURL.isEmpty ? "(not provided)" : sourceURL)

        Reporter email:
        \(userEmail.isEmpty ? "(not provided)" : userEmail)
        """

        // Encode for mailto URL
        let encodedSubject = subject.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        let encodedBody = body.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        let mailtoString = "mailto:plastik-data@example.com?subject=\(encodedSubject)&body=\(encodedBody)"

        if let mailtoURL = URL(string: mailtoString) {
            #if os(iOS)
            UIApplication.shared.open(mailtoURL)
            #elseif os(macOS)
            NSWorkspace.shared.open(mailtoURL)
            #endif
        }

        dismiss()
    }
}

// MARK: - Preview

#Preview {
    EditCardView(
        userCard: .constant(UserCard(cardId: "chase-sapphire-preferred")),
        catalogCard: nil
    )
    .environment(CardViewModel())
    .environment(DataFeedService())
}
