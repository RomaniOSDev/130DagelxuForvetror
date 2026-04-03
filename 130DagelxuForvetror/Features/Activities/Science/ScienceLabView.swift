import SwiftUI

struct ScienceLabView: View {
    @StateObject private var viewModel: ScienceLabViewModel
    @Binding var path: NavigationPath
    @EnvironmentObject private var store: AcademyProgressStore
    private let address: LevelAddress

    @State private var dragAnchor = CGSize.zero
    @State private var didRoute = false

    init(address: LevelAddress, path: Binding<NavigationPath>) {
        self.address = address
        _viewModel = StateObject(wrappedValue: ScienceLabViewModel(address: address))
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
                    Group {
                        switch address.difficulty {
                        case .easy:
                            easyLab
                        case .normal:
                            normalLab
                        case .hard:
                            hardLab
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 18)
            }
        }
        .navigationTitle("Science Lab")
        .navigationBarTitleDisplayMode(.inline)
        .onChange(of: viewModel.beakerOffset) { newValue in
            if newValue == .zero {
                dragAnchor = .zero
            }
        }
        .onChange(of: viewModel.phase) { phase in
            if case let .finished(summary) = phase, !didRoute {
                didRoute = true
                commit(summary)
            }
        }
    }

    private var easyLab: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Drag the beaker onto the glowing pad to pour each sample.")
                .foregroundStyle(Color.appTextSecondary)
            Text("Progress: \(viewModel.roundsCompleted)/\(viewModel.goalRounds)")
                .font(.footnote.weight(.semibold))
                .foregroundStyle(Color.appAccent)
            ZStack {
                RoundedRectangle(cornerRadius: 24)
                    .fill(AcademyGradients.surfaceCard)
                    .frame(height: 240)
                    .shadow(color: Color.appPrimary.opacity(0.2), radius: 16, x: 0, y: 10)
                    .shadow(color: Color.appBackground.opacity(0.55), radius: 4, x: 0, y: 2)
                    .overlay {
                        RoundedRectangle(cornerRadius: 24)
                            .stroke(AcademyGradients.cardBorder, lineWidth: 2)
                    }

                burnerFlame
                    .offset(y: 110)
                    .allowsHitTesting(false)

                Ellipse()
                    .stroke(Color.appAccent, lineWidth: 4)
                    .frame(width: 110, height: 46)
                    .offset(x: viewModel.snapTarget.x, y: viewModel.snapTarget.y)
                    .allowsHitTesting(false)

                RoundedRectangle(cornerRadius: 16)
                    .fill(AcademyGradients.primaryCTA)
                    .frame(width: 64, height: 104)
                    .shadow(color: Color.appPrimary.opacity(0.45), radius: 10, x: 0, y: 6)
                    .overlay {
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.appAccent.opacity(0.45), lineWidth: 2)
                    }
                    .offset(viewModel.beakerOffset)
                    .gesture(
                        DragGesture()
                            .onChanged { value in
                                viewModel.beakerOffset = CGSize(
                                    width: dragAnchor.width + value.translation.width,
                                    height: dragAnchor.height + value.translation.height
                                )
                            }
                            .onEnded { _ in
                                viewModel.dragEnded()
                                dragAnchor = viewModel.beakerOffset
                            }
                    )
            }
        }
    }

    private var normalLab: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("The bar grows and shrinks. Tap Capture when the bright tip sits inside the outlined window in the middle.")
                .foregroundStyle(Color.appTextSecondary)
            Text("Stable readings: \(viewModel.roundsCompleted)/\(viewModel.goalRounds)")
                .font(.footnote.weight(.semibold))
                .foregroundStyle(Color.appAccent)
            TimelineView(.animation(minimumInterval: 1 / 30)) { timeline in
                let time = timeline.date.timeIntervalSinceReferenceDate
                let wave = 0.5 + 0.46 * sin(time * 1.65)
                VStack(spacing: 12) {
                    GeometryReader { geo in
                        let trackWidth = geo.size.width
                        ZStack(alignment: .leading) {
                            Capsule()
                                .fill(Color.appSurface)
                            Capsule()
                                .fill(
                                    LinearGradient(
                                        colors: [Color.appAccent, Color.appPrimary],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .frame(width: max(16, trackWidth * wave))
                            Rectangle()
                                .stroke(Color.appTextPrimary.opacity(0.55), lineWidth: 2)
                                .frame(width: trackWidth * 0.18, height: geo.size.height + 6)
                                .position(x: trackWidth * 0.5, y: geo.size.height / 2)
                        }
                    }
                    .frame(height: 34)
                    .padding(12)
                    .background {
                        RoundedRectangle(cornerRadius: 18)
                            .fill(AcademyGradients.surfaceCard)
                            .shadow(color: Color.appPrimary.opacity(0.12), radius: 10, x: 0, y: 5)
                    }
                    .overlay {
                        RoundedRectangle(cornerRadius: 18)
                            .stroke(Color.appAccent.opacity(0.3), lineWidth: 1)
                    }

                    let inWindow = wave >= 0.41 && wave <= 0.59
                    Button {
                        viewModel.registerNormalHeatHit(isInWindow: inWindow)
                    } label: {
                        Text("Capture stable reading")
                            .academyButtonLabel()
                    }
                    .buttonStyle(AcademyFilledButton())
                }
            }
        }
    }

    private var hardLab: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Pick a hypothesis, dial the variable slider, then run the virtual trial.")
                .foregroundStyle(Color.appTextSecondary)
            Text(
                "Aim for a combined mix near \(viewModel.targetMixPercent)% (hypothesis adds up to 35%, slider adds the rest)."
            )
            .font(.footnote)
            .foregroundStyle(Color.appTextSecondary)
            Text("Runs cleared: \(viewModel.roundsCompleted)/\(viewModel.goalRounds)")
                .font(.footnote.weight(.semibold))
                .foregroundStyle(Color.appAccent)
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                ForEach(0 ..< 3, id: \.self) { idx in
                    Button {
                        viewModel.selectedHypothesisIndex = idx
                        Haptics.lightImpact()
                    } label: {
                        Text("Hypothesis \(idx + 1)")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(Color.appBackground)
                            .frame(maxWidth: .infinity, minHeight: 48)
                            .background {
                                RoundedRectangle(cornerRadius: 14)
                                    .fill(
                                        viewModel.selectedHypothesisIndex == idx
                                            ? AcademyGradients.primaryCTA
                                            : LinearGradient(
                                                colors: [Color.appPrimary.opacity(0.88), Color.appPrimary],
                                                startPoint: .top,
                                                endPoint: .bottom
                                            )
                                    )
                                    .shadow(color: Color.appPrimary.opacity(0.28), radius: 8, x: 0, y: 5)
                            }
                            .overlay {
                                RoundedRectangle(cornerRadius: 14)
                                    .stroke(Color.appAccent.opacity(0.35), lineWidth: 1)
                            }
                    }
                    .buttonStyle(.plain)
                }
            }
            VStack(alignment: .leading) {
                Text("Variable dial")
                    .font(.footnote)
                    .foregroundStyle(Color.appTextSecondary)
                Slider(value: $viewModel.variableSlider, in: 0 ... 1)
                    .tint(Color.appAccent)
            }
            Button {
                viewModel.submitHardExperiment()
            } label: {
                Text("Run experiment")
                    .academyButtonLabel()
            }
            .buttonStyle(AcademySecondaryButton())
        }
    }

    private var burnerFlame: some View {
        Canvas { context, size in
            let path = Path { p in
                p.move(to: CGPoint(x: size.width * 0.5, y: size.height * 0.95))
                p.addQuadCurve(
                    to: CGPoint(x: size.width * 0.5, y: size.height * 0.2),
                    control: CGPoint(x: size.width * 0.2, y: size.height * 0.55)
                )
                p.addQuadCurve(
                    to: CGPoint(x: size.width * 0.5, y: size.height * 0.95),
                    control: CGPoint(x: size.width * 0.82, y: size.height * 0.55)
                )
            }
            context.fill(path, with: .color(Color.appAccent.opacity(0.85)))
        }
        .frame(width: 120, height: 120)
    }

    private func commit(_ summary: ActivitySessionSummary) {
        let prior = store.unlockedAchievementIds
        store.recordSession(summary)
        let fresh = AchievementDef.allCases.filter { store.isAchievementUnlocked($0) && !prior.contains($0.rawValue) }
        path.append(ResultPayload(summary: summary, address: address, freshAchievements: fresh))
    }
}
