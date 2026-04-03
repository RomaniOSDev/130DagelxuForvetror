import SwiftUI

/// Full subject navigation from Home cards (same destinations as the Activities tab).
struct HomeSubjectFlowView: View {
    let kind: ActivityKind
    @State private var path = NavigationPath()

    var body: some View {
        NavigationStack(path: $path) {
            DifficultySelectView(activity: kind, path: $path)
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
