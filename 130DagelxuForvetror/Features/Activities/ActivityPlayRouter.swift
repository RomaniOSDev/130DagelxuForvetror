import SwiftUI

struct ActivityPlayRouter: View {
    let destination: PlayDestination
    @Binding var path: NavigationPath

    var body: some View {
        Group {
            switch destination.address.activity {
            case .mathExplorer:
                MathExplorerView(address: destination.address, path: $path)
            case .scienceLab:
                ScienceLabView(address: destination.address, path: $path)
            case .languageAdventure:
                LanguageAdventureView(address: destination.address, path: $path)
            }
        }
    }
}
