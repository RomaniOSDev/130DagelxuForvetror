import SwiftUI
import UIKit

struct MainTabView: View {
    @EnvironmentObject private var tabCoordinator: TabSelectionCoordinator

    var body: some View {
        TabView(selection: Binding(
            get: { tabCoordinator.selectedTab },
            set: { tabCoordinator.selectedTab = $0 }
        )) {
            NavigationStack {
                HomeView()
            }
            .tabItem { Label("Home", systemImage: "house.fill") }
            .tag(0)

            ActivitiesContainerView()
                .tabItem { Label("Activities", systemImage: "puzzlepiece.extension.fill") }
                .tag(1)

            NavigationStack {
                AchievementsView()
            }
            .tabItem { Label("Achievements", systemImage: "star.circle.fill") }
            .tag(2)

            NavigationStack {
                ProfileView()
            }
            .tabItem { Label("Profile", systemImage: "person.crop.circle") }
            .tag(3)
        }
        .tint(Color.appPrimary)
        .toolbarBackground(Color.appSurface, for: .tabBar)
        .toolbarBackground(.visible, for: .tabBar)
        .onAppear {
            let appearance = UITabBarAppearance()
            appearance.configureWithOpaqueBackground()
            appearance.backgroundColor = UIColor(Color.appSurface)
            appearance.shadowColor = UIColor(Color.appPrimary.opacity(0.18))
            appearance.stackedLayoutAppearance.selected.iconColor = UIColor(Color.appPrimary)
            appearance.stackedLayoutAppearance.selected.titleTextAttributes = [.foregroundColor: UIColor(Color.appPrimary)]
            appearance.stackedLayoutAppearance.normal.iconColor = UIColor(Color.appTextSecondary)
            appearance.stackedLayoutAppearance.normal.titleTextAttributes = [.foregroundColor: UIColor(Color.appTextSecondary)]
            UITabBar.appearance().standardAppearance = appearance
            UITabBar.appearance().scrollEdgeAppearance = appearance

            let nav = UINavigationBarAppearance()
            nav.configureWithOpaqueBackground()
            nav.backgroundColor = UIColor(Color.appSurface)
            nav.titleTextAttributes = [.foregroundColor: UIColor(Color.appTextPrimary)]
            nav.largeTitleTextAttributes = [.foregroundColor: UIColor(Color.appTextPrimary)]
            nav.shadowColor = UIColor(Color.appAccent.opacity(0.2))
            UINavigationBar.appearance().standardAppearance = nav
            UINavigationBar.appearance().scrollEdgeAppearance = nav
            UINavigationBar.appearance().compactAppearance = nav
        }
    }
}

struct ActivitiesContainerView: View {
    @State private var path = NavigationPath()

    var body: some View {
        NavigationStack(path: $path) {
            ActivityHubView(path: $path)
                .navigationDestination(for: ActivityKind.self) { kind in
                    DifficultySelectView(activity: kind, path: $path)
                }
                .navigationDestination(for: DifficultyRoute.self) { route in
                    LevelGridView(route: route, path: $path)
                }
                .navigationDestination(for: PlayDestination.self) { play in
                    ActivityPlayRouter(destination: play, path: $path)
                }
                .navigationDestination(for: ResultPayload.self) { payload in
                    ActivityResultView(payload: payload, path: $path)
                }
        }
    }
}
