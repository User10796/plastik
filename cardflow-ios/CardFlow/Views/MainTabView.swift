import SwiftUI

struct MainTabView: View {
    @Environment(DataStore.self) private var store
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            DashboardView()
                .tabItem {
                    Label("Dashboard", systemImage: "chart.bar.fill")
                }
                .tag(0)

            CardsListView()
                .tabItem {
                    Label("Cards", systemImage: "creditcard.fill")
                }
                .tag(1)

            PointsView()
                .tabItem {
                    Label("Points", systemImage: "star.fill")
                }
                .tag(2)

            ApplicationsView()
                .tabItem {
                    Label("Apps", systemImage: "doc.text.fill")
                }
                .tag(3)

            FeesView()
                .tabItem {
                    Label("Fees", systemImage: "calendar")
                }
                .tag(4)

            ImportView()
                .tabItem {
                    Label("Import", systemImage: "doc.text.viewfinder")
                }
                .tag(5)

            PayoffView()
                .tabItem {
                    Label("Payoff", systemImage: "arrow.down.circle.fill")
                }
                .tag(6)

            StrategyView()
                .tabItem {
                    Label("Strategy", systemImage: "lightbulb.fill")
                }
                .tag(7)
        }
        .tint(ColorTheme.gold)
    }
}
