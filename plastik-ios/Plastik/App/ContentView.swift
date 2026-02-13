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
    @State private var selectedItem: SidebarItem? = .dashboard

    var body: some View {
        NavigationSplitView {
            // SIDEBAR with grouped sections - uses NSVisualEffectView automatically
            List(selection: $selectedItem) {
                // Dashboard (top level, no group)
                Label("Dashboard", systemImage: "square.grid.2x2")
                    .font(.system(size: 14))
                    .tag(SidebarItem.dashboard)

                // Wallet Group
                Section {
                    Label("Cards", systemImage: "creditcard.fill")
                        .font(.system(size: 14))
                        .tag(SidebarItem.cards)
                    Label("Points", systemImage: "star.fill")
                        .font(.system(size: 14))
                        .tag(SidebarItem.points)
                    Label("Companion Passes", systemImage: "person.2.fill")
                        .font(.system(size: 14))
                        .tag(SidebarItem.companionPasses)
                } header: {
                    Text("WALLET")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(.secondary)
                        .textCase(.uppercase)
                }

                // Strategy Group
                Section {
                    Label("Recommendations", systemImage: "lightbulb.fill")
                        .font(.system(size: 14))
                        .tag(SidebarItem.recommendations)
                    Label("Transfer Partners", systemImage: "arrow.triangle.swap")
                        .font(.system(size: 14))
                        .tag(SidebarItem.transferPartners)
                    Label("Churn Tracker", systemImage: "chart.bar.fill")
                        .font(.system(size: 14))
                        .tag(SidebarItem.churnTracker)
                } header: {
                    Text("STRATEGY")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(.secondary)
                        .textCase(.uppercase)
                }

                // Tools Group
                Section {
                    Label("Import", systemImage: "square.and.arrow.down")
                        .font(.system(size: 14))
                        .tag(SidebarItem.importData)
                    Label("Payoff Calculator", systemImage: "function")
                        .font(.system(size: 14))
                        .tag(SidebarItem.payoffCalculator)
                } header: {
                    Text("TOOLS")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(.secondary)
                        .textCase(.uppercase)
                }

                // History Group
                Section {
                    Label("Applications", systemImage: "doc.text")
                        .font(.system(size: 14))
                        .tag(SidebarItem.applications)
                    Label("Credit Pulls", systemImage: "magnifyingglass")
                        .font(.system(size: 14))
                        .tag(SidebarItem.creditPulls)
                } header: {
                    Text("HISTORY")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(.secondary)
                        .textCase(.uppercase)
                }

                // Settings (bottom, separated)
                Section {
                    Label("Settings", systemImage: "gear")
                        .font(.system(size: 14))
                        .tag(SidebarItem.settings)
                }
            }
            .navigationSplitViewColumnWidth(min: 200, ideal: 220, max: 280)
            .listStyle(.sidebar)
            .scrollContentBackground(.hidden)
            .background(VisualEffectBackground())

        } detail: {
            // DETAIL area - content based on sidebar selection
            NavigationStack {
                contentView
            }
        }
        .navigationTitle("Plastik")
        #if os(macOS)
        .frame(minWidth: 900, minHeight: 600)
        #endif
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

// MARK: - Visual Effect Background for Translucent Sidebar

#if os(macOS)
struct VisualEffectBackground: NSViewRepresentable {
    func makeNSView(context: Context) -> NSVisualEffectView {
        let view = NSVisualEffectView()
        view.material = .sidebar
        view.blendingMode = .behindWindow
        view.state = .followsWindowActiveState
        return view
    }

    func updateNSView(_ nsView: NSVisualEffectView, context: Context) {
        nsView.material = .sidebar
    }
}
#else
struct VisualEffectBackground: View {
    var body: some View {
        Color.clear
    }
}
#endif
