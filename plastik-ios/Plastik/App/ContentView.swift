import SwiftUI

struct ContentView: View {
    var body: some View {
        #if os(macOS)
        MacContentView()
        #else
        MobileContentView()
        #endif
    }
}

// MARK: - iOS Tab View (Dashboard, Cards, Points, Strategy, More)

struct MobileContentView: View {
    var body: some View {
        TabView {
            NavigationStack {
                DashboardView()
            }
            .tabItem {
                Label("Dashboard", systemImage: "square.grid.2x2")
            }

            NavigationStack {
                CardListView()
            }
            .tabItem {
                Label("Cards", systemImage: "creditcard.fill")
            }

            NavigationStack {
                PointsView()
            }
            .tabItem {
                Label("Points", systemImage: "star.fill")
            }

            NavigationStack {
                StrategyTabView()
            }
            .tabItem {
                Label("Strategy", systemImage: "lightbulb.fill")
            }

            NavigationStack {
                MoreTabView()
            }
            .tabItem {
                Label("More", systemImage: "ellipsis")
            }
        }
    }
}

// MARK: - iOS Strategy Tab

struct StrategyTabView: View {
    var body: some View {
        List {
            NavigationLink(destination: RecommendationsView()) {
                Label("Recommendations", systemImage: "lightbulb.fill")
            }
            NavigationLink(destination: TransferPartnerMapView()) {
                Label("Transfer Partners", systemImage: "arrow.triangle.swap")
            }
            NavigationLink(destination: ChurnTrackerView()) {
                Label("Churn Tracker", systemImage: "chart.bar.fill")
            }
        }
        .navigationTitle("Strategy")
    }
}

// MARK: - iOS More Tab (Tools, Wallet extras, History, Settings)

struct MoreTabView: View {
    var body: some View {
        List {
            Section("Wallet") {
                NavigationLink(destination: CompanionPassView()) {
                    Label("Companion Passes", systemImage: "person.2.fill")
                }
            }

            Section("Tools") {
                NavigationLink(destination: ImportView()) {
                    Label("Import", systemImage: "square.and.arrow.down")
                }
                NavigationLink(destination: PayoffCalculatorView()) {
                    Label("Payoff Calculator", systemImage: "function")
                }
            }

            Section("History") {
                NavigationLink(destination: ApplicationsView()) {
                    Label("Applications", systemImage: "doc.text")
                }
                NavigationLink(destination: CreditPullsView()) {
                    Label("Credit Pulls", systemImage: "magnifyingglass")
                }
            }

            Section {
                NavigationLink(destination: SettingsView()) {
                    Label("Settings", systemImage: "gear")
                }
            }
        }
        .navigationTitle("More")
    }
}

// MARK: - macOS Three-Column Layout with Grouped Sidebar

enum SidebarItem: String, CaseIterable, Hashable {
    // Dashboard
    case dashboard = "Dashboard"

    // Wallet
    case cards = "Cards"
    case points = "Points"
    case companionPasses = "Companion Passes"

    // Strategy
    case recommendations = "Recommendations"
    case transferPartners = "Transfer Partners"
    case churnTracker = "Churn Tracker"

    // Tools
    case importData = "Import"
    case payoffCalculator = "Payoff Calculator"

    // History
    case applications = "Applications"
    case creditPulls = "Credit Pulls"

    // Settings
    case settings = "Settings"

    var icon: String {
        switch self {
        case .dashboard: return "square.grid.2x2"
        case .cards: return "creditcard.fill"
        case .points: return "star.fill"
        case .companionPasses: return "person.2.fill"
        case .recommendations: return "lightbulb.fill"
        case .transferPartners: return "arrow.triangle.swap"
        case .churnTracker: return "chart.bar.fill"
        case .importData: return "square.and.arrow.down"
        case .payoffCalculator: return "function"
        case .applications: return "doc.text"
        case .creditPulls: return "magnifyingglass"
        case .settings: return "gear"
        }
    }
}

struct MacContentView: View {
    @Environment(CardViewModel.self) private var cardViewModel
    @Environment(DataFeedService.self) private var feedService

    @State private var selectedItem: SidebarItem? = .dashboard
    @State private var selectedCard: UserCard?

    var body: some View {
        NavigationSplitView {
            // SIDEBAR with grouped sections
            List(selection: $selectedItem) {
                // Dashboard (top level, no group)
                NavigationLink(value: SidebarItem.dashboard) {
                    Label("Dashboard", systemImage: "square.grid.2x2")
                }

                // Wallet Group
                Section("Wallet") {
                    NavigationLink(value: SidebarItem.cards) {
                        Label("Cards", systemImage: "creditcard.fill")
                    }
                    NavigationLink(value: SidebarItem.points) {
                        Label("Points", systemImage: "star.fill")
                    }
                    NavigationLink(value: SidebarItem.companionPasses) {
                        Label("Companion Passes", systemImage: "person.2.fill")
                    }
                }

                // Strategy Group
                Section("Strategy") {
                    NavigationLink(value: SidebarItem.recommendations) {
                        Label("Recommendations", systemImage: "lightbulb.fill")
                    }
                    NavigationLink(value: SidebarItem.transferPartners) {
                        Label("Transfer Partners", systemImage: "arrow.triangle.swap")
                    }
                    NavigationLink(value: SidebarItem.churnTracker) {
                        Label("Churn Tracker", systemImage: "chart.bar.fill")
                    }
                }

                // Tools Group
                Section("Tools") {
                    NavigationLink(value: SidebarItem.importData) {
                        Label("Import", systemImage: "square.and.arrow.down")
                    }
                    NavigationLink(value: SidebarItem.payoffCalculator) {
                        Label("Payoff Calculator", systemImage: "function")
                    }
                }

                // History Group
                Section("History") {
                    NavigationLink(value: SidebarItem.applications) {
                        Label("Applications", systemImage: "doc.text")
                    }
                    NavigationLink(value: SidebarItem.creditPulls) {
                        Label("Credit Pulls", systemImage: "magnifyingglass")
                    }
                }

                // Settings (bottom, with divider)
                Divider()
                NavigationLink(value: SidebarItem.settings) {
                    Label("Settings", systemImage: "gear")
                }
            }
            .navigationSplitViewColumnWidth(min: 200, ideal: 220, max: 280)
            .navigationTitle("Plastik")

        } content: {
            // CONTENT area
            contentView

        } detail: {
            // DETAIL VIEW (for card selection etc.)
            if let card = selectedCard {
                CardDetailView(userCard: card)
            } else {
                ContentUnavailableView(
                    "No Selection",
                    systemImage: "creditcard",
                    description: Text("Select a card to view details")
                )
            }
        }
        .navigationSplitViewStyle(.balanced)
    }

    @ViewBuilder
    private var contentView: some View {
        switch selectedItem {
        case .dashboard:
            DashboardView()
        case .cards:
            CardListView()
        case .points:
            PointsView()
        case .companionPasses:
            CompanionPassView()
        case .recommendations:
            RecommendationsView()
        case .transferPartners:
            TransferPartnerMapView()
        case .churnTracker:
            ChurnTrackerView()
        case .importData:
            ImportView()
        case .payoffCalculator:
            PayoffCalculatorView()
        case .applications:
            ApplicationsView()
        case .creditPulls:
            CreditPullsView()
        case .settings:
            SettingsView()
        case .none:
            ContentUnavailableView(
                "Select an item",
                systemImage: "sidebar.left",
                description: Text("Choose from the sidebar")
            )
        }
    }
}
