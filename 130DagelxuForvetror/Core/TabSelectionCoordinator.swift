import Combine
import SwiftUI

@MainActor
final class TabSelectionCoordinator: ObservableObject {
    @Published var selectedTab: Int = 0
}
