import SwiftUI

struct LevelGridView: View {
    let route: DifficultyRoute
    @Binding var path: NavigationPath
    @EnvironmentObject private var store: AcademyProgressStore

    private let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]

    var body: some View {
        ZStack {
            AcademyScreenBackdrop()
            ScrollView {
                LazyVGrid(columns: columns, spacing: 12) {
                    ForEach(0 ..< LevelAddress.levelsPerTrack, id: \.self) { index in
                        let address = LevelAddress(activity: route.activity, difficulty: route.tier, levelIndex: index)
                        levelCell(address: address)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 18)
            }
        }
        .navigationTitle(route.activity.titleKey)
        .navigationBarTitleDisplayMode(.inline)
    }

    private func levelCell(address: LevelAddress) -> some View {
        let unlocked = store.isLevelUnlocked(address)
        let stars = store.stars(for: address)
        return Button {
            guard unlocked else {
                Haptics.warning()
                return
            }
            Haptics.lightImpact()
            path.append(PlayDestination(address: address))
        } label: {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text("Lesson \(address.levelIndex + 1)")
                        .font(.headline)
                        .foregroundStyle(unlocked ? Color.appTextPrimary : Color.appTextSecondary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                    Spacer()
                    Image(systemName: unlocked ? "lock.open.fill" : "lock.fill")
                        .foregroundStyle(Color.appAccent.opacity(unlocked ? 0.9 : 0.45))
                }

                HStack(spacing: 4) {
                    ForEach(0 ..< 3, id: \.self) { idx in
                        StarShape()
                            .fill(idx < stars ? Color.appPrimary : Color.appSurface.opacity(0.5))
                            .frame(width: 18, height: 18)
                            .overlay {
                                StarShape()
                                    .stroke(Color.appAccent.opacity(idx < stars ? 0.9 : 0.3), lineWidth: 1)
                            }
                    }
                }
            }
            .padding(14)
            .frame(maxWidth: .infinity, minHeight: 96, alignment: .leading)
            .academyElevatedCard(cornerRadius: AcademyDepth.cornerStandard, elevated: unlocked)
        }
        .buttonStyle(.plain)
        .disabled(!unlocked)
        .accessibilityLabel(Text(unlocked ? "Open lesson \(address.levelIndex + 1)" : "Locked lesson \(address.levelIndex + 1)"))
    }
}
