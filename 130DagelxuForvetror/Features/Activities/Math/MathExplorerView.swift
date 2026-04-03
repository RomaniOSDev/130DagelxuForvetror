import Combine
import SwiftUI

struct MathExplorerView: View {
    @StateObject private var viewModel: MathExplorerViewModel
    @Binding var path: NavigationPath
    @EnvironmentObject private var store: AcademyProgressStore
    private let address: LevelAddress

    @State private var dragOffset: CGSize = .zero
    @State private var didRoute = false

    init(address: LevelAddress, path: Binding<NavigationPath>) {
        self.address = address
        _viewModel = StateObject(wrappedValue: MathExplorerViewModel(address: address))
        _path = path
    }

    var body: some View {
        ZStack {
            AcademyScreenBackdrop()
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    header
                    if let step = viewModel.currentStep {
                        promptCard(step: step)
                        answerGrid(step: step)
                        if address.difficulty == .easy {
                            dragHelperChip(step: step)
                        }
                    } else if case .finished = viewModel.phase {
                        Text("Preparing your report…")
                            .foregroundStyle(Color.appTextSecondary)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 18)
            }
        }
        .navigationTitle("Math Explorer")
        .navigationBarTitleDisplayMode(.inline)
        .onReceive(Timer.publish(every: 0.25, on: .main, in: .common).autoconnect()) { _ in
            viewModel.tickTimer()
        }
        .onChange(of: viewModel.phase) { phase in
            if case let .finished(_, summary) = phase, !didRoute {
                didRoute = true
                commit(summary)
            }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Lesson \(address.levelIndex + 1) · \(address.difficulty.title)")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Color.appTextSecondary)
            HStack {
                Label("Lives \(viewModel.livesRemaining)", systemImage: "heart.fill")
                    .foregroundStyle(Color.appAccent)
                Spacer()
                if address.difficulty != .easy {
                    Label("Timed steps", systemImage: "timer")
                        .foregroundStyle(Color.appPrimary)
                }
            }
            .font(.footnote.weight(.medium))
        }
        .padding(14)
        .academyElevatedCard(cornerRadius: AcademyDepth.cornerMedium, elevated: false)
    }

    private func promptCard(step: MathExplorerViewModel.Step) -> some View {
        Text(step.prompt)
            .font(.title2.bold())
            .foregroundStyle(Color.appTextPrimary)
            .multilineTextAlignment(.leading)
            .padding(18)
            .frame(maxWidth: .infinity, alignment: .leading)
            .academyElevatedCard(cornerRadius: AcademyDepth.cornerMedium, elevated: true)
            .animation(.spring(response: 0.45, dampingFraction: 0.86), value: viewModel.currentIndex)
            .transition(.move(edge: .trailing).combined(with: .opacity))
    }

    private func answerGrid(step: MathExplorerViewModel.Step) -> some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            ForEach(step.choices, id: \.self) { value in
                Button {
                    Haptics.lightImpact()
                    viewModel.registerAnswer(value)
                } label: {
                    Text("\(value)")
                        .font(.title3.weight(.bold))
                        .foregroundStyle(Color.appBackground)
                        .frame(maxWidth: .infinity, minHeight: 52)
                        .background {
                            RoundedRectangle(cornerRadius: 16)
                                .fill(AcademyGradients.primaryCTA)
                                .shadow(color: Color.appPrimary.opacity(0.32), radius: 10, x: 0, y: 6)
                                .shadow(color: Color.appAccent.opacity(0.15), radius: 4, x: 0, y: 2)
                        }
                        .overlay {
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(Color.appAccent.opacity(0.35), lineWidth: 1)
                        }
                }
                .buttonStyle(.plain)
            }
        }
    }

    private func dragHelperChip(step: MathExplorerViewModel.Step) -> some View {
        let target = step.correct
        return VStack(alignment: .leading, spacing: 8) {
            Text("Tip: drag the chip outward and release for a quick answer match")
                .font(.caption)
                .foregroundStyle(Color.appTextSecondary)
            HStack {
                Text("\(target)")
                    .font(.headline)
                    .foregroundStyle(Color.appBackground)
                    .padding(.horizontal, 18)
                    .padding(.vertical, 12)
                    .academyFloatingCapsule()
                    .offset(dragOffset)
                    .gesture(
                        DragGesture()
                            .onChanged { value in
                                dragOffset = value.translation
                            }
                            .onEnded { value in
                                defer { dragOffset = .zero }
                                let magnitude = hypot(value.translation.width, value.translation.height)
                                if magnitude > 64 {
                                    viewModel.registerAnswer(target)
                                }
                            }
                    )
                Spacer()
            }
        }
        .padding(.top, 6)
    }

    private func commit(_ summary: ActivitySessionSummary) {
        let prior = store.unlockedAchievementIds
        store.recordSession(summary)
        let fresh = AchievementDef.allCases.filter { store.isAchievementUnlocked($0) && !prior.contains($0.rawValue) }
        path.append(ResultPayload(summary: summary, address: address, freshAchievements: fresh))
    }
}
