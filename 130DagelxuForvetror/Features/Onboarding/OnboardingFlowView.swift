import SwiftUI

struct OnboardingFlowView: View {
    private static let pageCount = 3

    @EnvironmentObject private var store: AcademyProgressStore
    @State private var page = 0
    @State private var illustrationPulse = false

    var body: some View {
        ZStack {
            AcademyScreenBackdrop()
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Academy tour")
                            .font(.title2.bold())
                            .foregroundStyle(Color.appTextPrimary)
                        Text("Three quick stops before your first lesson.")
                            .font(.subheadline)
                            .foregroundStyle(Color.appTextSecondary)
                    }
                    .padding(.horizontal, 16)

                    VStack(spacing: 16) {
                        TabView(selection: $page) {
                            onboardingPage(
                                step: 1,
                                title: "Welcome to the Academy Hall",
                                detail: "Help classmates crack puzzles in math, lab work, and language quests. Each lesson awards up to three stars for careful thinking.",
                                symbol: .stars
                            )
                            .tag(0)

                            onboardingPage(
                                step: 2,
                                title: "Learn Through Stories",
                                detail: "Every challenge supports a character: build equations for experiments, tune delicate tools, and repair tricky sentences together.",
                                symbol: .classroom
                            )
                            .tag(1)

                            onboardingPage(
                                step: 3,
                                title: "Collect Your Stars",
                                detail: "Replay smarter routes, climb difficulty tiers, and unlock new desks as you improve accuracy and speed.",
                                symbol: .spark
                            )
                            .tag(2)
                        }
                        .tabViewStyle(.page(indexDisplayMode: .never))
                        .frame(height: 460)
                        .onAppear { illustrationPulse.toggle() }

                        onboardingPageDots
                    }
                    .padding(.horizontal, 16)

                    VStack(spacing: 12) {
                        Button {
                            Haptics.success()
                            store.completeOnboarding()
                        } label: {
                            Text("Enter the Academy")
                                .academyButtonLabel()
                        }
                        .buttonStyle(AcademyFilledButton())

                        if page < Self.pageCount - 1 {
                            Button {
                                withAnimation(.spring(response: 0.45, dampingFraction: 0.82)) {
                                    page = min(page + 1, Self.pageCount - 1)
                                }
                                Haptics.lightImpact()
                            } label: {
                                Text("Next chapter")
                                    .academyButtonLabel()
                            }
                            .buttonStyle(AcademySecondaryButton())
                        }
                    }
                    .padding(.horizontal, 16)

                    Spacer(minLength: 12)
                }
                .padding(.vertical, 20)
            }
        }
    }

    private var onboardingPageDots: some View {
        HStack(spacing: 8) {
            ForEach(0 ..< Self.pageCount, id: \.self) { index in
                Capsule()
                    .fill(index == page ? Color.appAccent : Color.appTextSecondary.opacity(0.28))
                    .frame(width: index == page ? 22 : 8, height: 8)
                    .animation(.spring(response: 0.35, dampingFraction: 0.78), value: page)
            }
        }
        .frame(maxWidth: .infinity)
    }

    private enum Illustration {
        case stars
        case classroom
        case spark
    }

    private func onboardingPage(step: Int, title: String, detail: String, symbol: Illustration) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            ZStack {
                symbolView(symbol)
                    .scaleEffect(illustrationPulse ? 1.02 : 0.96)
                    .animation(.easeInOut(duration: 2).repeatForever(autoreverses: true), value: illustrationPulse)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 208)
            .padding(.vertical, 12)
            .padding(.horizontal, 8)
            .academyElevatedCard(cornerRadius: AcademyDepth.cornerLarge, elevated: true)

            Text("Chapter \(step) of \(Self.pageCount)")
                .font(.caption.weight(.semibold))
                .foregroundStyle(Color.appAccent)

            Text(title)
                .font(.title3.bold())
                .foregroundStyle(Color.appTextPrimary)
                .multilineTextAlignment(.leading)
                .frame(maxWidth: .infinity, alignment: .leading)

            Text(detail)
                .font(.subheadline)
                .foregroundStyle(Color.appTextSecondary)
                .multilineTextAlignment(.leading)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    @ViewBuilder
    private func symbolView(_ kind: Illustration) -> some View {
        switch kind {
        case .stars:
            Canvas { context, size in
                let centers: [CGPoint] = [
                    CGPoint(x: size.width * 0.28, y: size.height * 0.42),
                    CGPoint(x: size.width * 0.52, y: size.height * 0.32),
                    CGPoint(x: size.width * 0.74, y: size.height * 0.48)
                ]
                for center in centers {
                    var star = Path()
                    star.addArc(center: center, radius: 22, startAngle: .degrees(0), endAngle: .degrees(360), clockwise: true)
                    context.fill(star, with: .color(Color.appPrimary.opacity(0.35)))
                }
                let ribbon = Path { path in
                    path.move(to: CGPoint(x: size.width * 0.18, y: size.height * 0.68))
                    path.addQuadCurve(
                        to: CGPoint(x: size.width * 0.82, y: size.height * 0.66),
                        control: CGPoint(x: size.width * 0.5, y: size.height * 0.82)
                    )
                }
                context.stroke(ribbon, with: .color(Color.appAccent), lineWidth: 6)
            }
            .frame(height: 200)

        case .classroom:
            Canvas { context, size in
                let board = CGRect(x: size.width * 0.12, y: size.height * 0.12, width: size.width * 0.76, height: size.height * 0.42)
                let boardPath = Path(roundedRect: board, cornerRadius: 14)
                context.fill(boardPath, with: .color(Color.appBackground.opacity(0.85)))
                context.stroke(boardPath, with: .color(Color.appAccent.opacity(0.6)), lineWidth: 4)

                let desk = Path { path in
                    path.addRoundedRect(
                        in: CGRect(x: size.width * 0.2, y: size.height * 0.62, width: size.width * 0.6, height: size.height * 0.12),
                        cornerSize: CGSize(width: 10, height: 10)
                    )
                }
                context.fill(desk, with: .color(Color.appPrimary.opacity(0.8)))

                let bulb = Path(ellipseIn: CGRect(x: size.width * 0.44, y: size.height * 0.08, width: size.width * 0.12, height: size.height * 0.12))
                context.fill(bulb, with: .color(Color.appAccent.opacity(0.85)))
            }
            .frame(height: 200)

        case .spark:
            TimelineView(.animation(minimumInterval: 0.05)) { timeline in
                Canvas { context, size in
                    let t = timeline.date.timeIntervalSinceReferenceDate
                    let wave = sin(t * 6) * 8
                    let center = CGPoint(x: size.width * 0.5, y: size.height * 0.48 + wave)
                    let outer = Path(ellipseIn: CGRect(x: center.x - 46, y: center.y - 46, width: 92, height: 92))
                    context.fill(outer, with: .color(Color.appAccent.opacity(0.2)))
                    let core = Path(ellipseIn: CGRect(x: center.x - 26, y: center.y - 26, width: 52, height: 52))
                    context.fill(core, with: .color(Color.appPrimary))
                }
                .frame(height: 200)
            }
        }
    }
}
