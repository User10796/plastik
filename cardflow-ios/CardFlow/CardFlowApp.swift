import SwiftUI

@main
struct CardFlowApp: App {
    @State private var store = DataStore()

    var body: some Scene {
        WindowGroup {
            MainTabView()
                .environment(store)
                .onAppear {
                    store.load()
                }
                .preferredColorScheme(.dark)
        }
    }
}
