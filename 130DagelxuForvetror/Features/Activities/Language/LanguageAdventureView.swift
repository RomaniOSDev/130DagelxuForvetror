import SwiftUI

struct LanguageAdventureView: View {
    @StateObject private var viewModel: LanguageAdventureViewModel
    @Binding var path: NavigationPath
    @EnvironmentObject private var store: AcademyProgressStore
    private let address: LevelAddress

    @State private var didRoute = false

    init(address: LevelAddress, path: Binding<NavigationPath>) {
        self.address = address
        _viewModel = StateObject(wrappedValue: LanguageAdventureViewModel(address: address))
        _path = path
    }

    var body: some View {
        ZStack {
            AcademyScreenBackdrop()
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    Text("Lesson \(address.levelIndex + 1) · \(address.difficulty.title)")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Color.appTextSecondary)
                        .padding(14)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .academyElevatedCard(cornerRadius: AcademyDepth.cornerMedium, elevated: false)

                    challengeCard

                    controls
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 18)
            }
        }
        .navigationTitle("Language Adventure")
        .navigationBarTitleDisplayMode(.inline)
        .onChange(of: viewModel.phase) { phase in
            if case let .finished(summary) = phase, !didRoute {
                didRoute = true
                commit(summary)
            }
        }
    }

    private var challengeCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            if address.difficulty == .normal {
                Text("Rebuild the sentence")
                    .font(.headline)
                    .foregroundStyle(Color.appTextSecondary)
                ForEach(Array(viewModel.orderedWords.enumerated()), id: \.offset) { index, word in
                    HStack {
                        Text(word)
                            .font(.body.weight(.semibold))
                            .foregroundStyle(Color.appTextPrimary)
                            .lineLimit(2)
                            .minimumScaleFactor(0.7)
                        Spacer()
                        Button {
                            viewModel.moveWordUp(at: index)
                            Haptics.lightImpact()
                        } label: {
                            Image(systemName: "chevron.up.circle.fill")
                                .font(.title3)
                                .foregroundStyle(Color.appAccent)
                                .frame(minWidth: 44, minHeight: 44)
                        }
                        .buttonStyle(.plain)
                        Button {
                            viewModel.moveWordDown(at: index)
                            Haptics.lightImpact()
                        } label: {
                            Image(systemName: "chevron.down.circle.fill")
                                .font(.title3)
                                .foregroundStyle(Color.appAccent)
                                .frame(minWidth: 44, minHeight: 44)
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(12)
                    .academyInsetWell(cornerRadius: 14)
                    .animation(.easeInOut(duration: 0.2), value: viewModel.orderedWords)
                }
            } else {
                Text(viewModel.current.sentence)
                    .font(.title3.weight(.bold))
                    .foregroundStyle(Color.appTextPrimary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .academyElevatedCard(cornerRadius: AcademyDepth.cornerMedium, elevated: true)
        .animation(.spring(response: 0.5, dampingFraction: 0.86), value: viewModel.current.id)
    }

    private var controls: some View {
        Group {
            switch address.difficulty {
            case .easy, .hard:
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                    ForEach(viewModel.current.options, id: \.self) { option in
                        Button {
                            viewModel.selectedOption = option
                            withAnimation(.spring(response: 0.35, dampingFraction: 0.72)) {}
                            Haptics.lightImpact()
                        } label: {
                            Text(option)
                                .font(.headline)
                                .foregroundStyle(Color.appBackground)
                                .frame(maxWidth: .infinity, minHeight: 48)
                                .background {
                                    RoundedRectangle(cornerRadius: 16)
                                        .fill(
                                            viewModel.selectedOption == option
                                                ? AcademyGradients.primaryCTA
                                                : LinearGradient(
                                                    colors: [Color.appPrimary.opacity(0.9), Color.appPrimary],
                                                    startPoint: .topLeading,
                                                    endPoint: .bottomTrailing
                                                )
                                        )
                                        .shadow(color: Color.appPrimary.opacity(0.28), radius: 10, x: 0, y: 5)
                                }
                                .overlay {
                                    RoundedRectangle(cornerRadius: 16)
                                        .stroke(Color.appAccent.opacity(0.35), lineWidth: 1)
                                }
                                .scaleEffect(viewModel.selectedOption == option ? 1.02 : 1)
                                .opacity(viewModel.selectedOption == option ? 1 : 0.85)
                        }
                        .buttonStyle(.plain)
                    }
                }
                Button {
                    viewModel.submitEasyOrHardSelection()
                } label: {
                    Text("Submit answer")
                        .academyButtonLabel()
                }
                .buttonStyle(AcademyFilledButton())

            case .normal:
                Button {
                    viewModel.submitScrambled()
                } label: {
                    Text("Check sentence")
                        .academyButtonLabel()
                }
                .buttonStyle(AcademyFilledButton())
            }
        }
    }

    private func commit(_ summary: ActivitySessionSummary) {
        let prior = store.unlockedAchievementIds
        store.recordSession(summary)
        let fresh = AchievementDef.allCases.filter { store.isAchievementUnlocked($0) && !prior.contains($0.rawValue) }
        path.append(ResultPayload(summary: summary, address: address, freshAchievements: fresh))
    }
}
