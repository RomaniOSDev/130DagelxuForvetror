import SwiftUI

struct ContentView: View {
    @StateObject private var store = AcademyProgressStore()
    @StateObject private var tabCoordinator = TabSelectionCoordinator()

    var body: some View {
        Group {
            if store.hasSeenOnboarding {
                MainTabView()
            } else {
                OnboardingFlowView()
            }
        }
        .environmentObject(store)
        .environmentObject(tabCoordinator)
        .onReceive(NotificationCenter.default.publisher(for: ProgressNotifications.progressDidReset)) { _ in
            store.refreshFromDefaults()
        }
    }
}

#Preview {
    ContentView()
}
