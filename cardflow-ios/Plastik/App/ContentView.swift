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

// MARK: - iOS Tab View

struct MobileContentView: View {
    var body: some View {
        TabView {
            NavigationStack {
                WalletView()
            }
            .tabItem {
                Label("Wallet", systemImage: "creditcard.fill")
            }

            NavigationStack {
                CardListView()
            }
            .tabItem {
                Label("Cards", systemImage: "rectangle.stack.fill")
            }

            NavigationStack {
                OffersView()
            }
            .tabItem {
                Label("Offers", systemImage: "tag.fill")
            }

            NavigationStack {
                ChurnTrackerView()
            }
            .tabItem {
                Label("Churn", systemImage: "chart.bar.fill")
            }

            NavigationStack {
                SettingsView()
            }
            .tabItem {
                Label("Settings", systemImage: "gear")
            }
        }
    }
}

// MARK: - macOS Three-Column Layout

struct MacContentView: View {
    @Environment(CardViewModel.self) private var cardViewModel
    @Environment(DataFeedService.self) private var feedService

    @State private var selection: SidebarItem? = .wallet
    @State private var selectedCardId: String?
    @State private var selectedOfferId: String?

    enum SidebarItem: String, CaseIterable, Identifiable {
        case wallet = "Wallet"
        case cards = "Cards"
        case offers = "Offers"
        case churn = "Churn Tracker"
        case partners = "Transfer Partners"
        case settings = "Settings"

        var id: String { rawValue }

        var icon: String {
            switch self {
            case .wallet: return "creditcard.fill"
            case .cards: return "rectangle.stack.fill"
            case .offers: return "tag.fill"
            case .churn: return "chart.bar.fill"
            case .partners: return "arrow.triangle.swap"
            case .settings: return "gear"
            }
        }
    }

    var body: some View {
        NavigationSplitView(columnVisibility: .constant(.all)) {
            // Column 1: Sidebar
            List(SidebarItem.allCases, selection: $selection) { item in
                Label(item.rawValue, systemImage: item.icon)
                    .tag(item)
            }
            .navigationTitle(Constants.appName)
            .navigationSplitViewColumnWidth(min: 180, ideal: 200, max: 240)
        } content: {
            // Column 2: Content list
            switch selection {
            case .wallet:
                WalletView()
            case .cards:
                CardListView()
            case .offers:
                OffersView()
            case .churn:
                ChurnTrackerView()
            case .partners:
                TransferPartnerMapView()
            case .settings:
                SettingsView()
            case .none:
                Text("Select a section")
                    .foregroundStyle(.secondary)
            }
        } detail: {
            // Column 3: Detail view
            Text("Select an item to see details")
                .foregroundStyle(.secondary)
        }
        .navigationSplitViewStyle(.balanced)
    }
}
