import SwiftUI

struct HomeView: View {
    @EnvironmentObject private var store: AcademyProgressStore
    @EnvironmentObject private var tabCoordinator: TabSelectionCoordinator

    @State private var heroShown = false

    private var totalLevelSlots: Int {
        ActivityKind.allCases.count * DifficultyTier.allCases.count * LevelAddress.levelsPerTrack
    }

    private var completedLevels: Int {
        ActivityKind.allCases.reduce(0) { partial, kind in
            partial + store.completedLevelsCount(activity: kind)
        }
    }

    private var overallProgress: Double {
        guard totalLevelSlots > 0 else { return 0 }
        return Double(completedLevels) / Double(totalLevelSlots)
    }

    private var unlockedAchievements: Int {
        AchievementDef.allCases.filter { store.isAchievementUnlocked($0) }.count
    }

    private var greeting: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5 ..< 12: return "Good morning"
        case 12 ..< 17: return "Good afternoon"
        case 17 ..< 22: return "Good evening"
        default: return "Welcome back"
        }
    }

    private var suggestedSubject: ActivityKind? {
        for kind in ActivityKind.allCases {
            for tier in DifficultyTier.allCases {
                for index in 0 ..< LevelAddress.levelsPerTrack {
                    let address = LevelAddress(activity: kind, difficulty: tier, levelIndex: index)
                    if store.isLevelUnlocked(address), !store.isLevelCompleted(address) {
                        return kind
                    }
                }
            }
        }
        return nil
    }

    private var learningMinutes: Int {
        Int(store.totalPlaySeconds / 60)
    }

    var body: some View {
        ZStack {
            AcademyScreenBackdrop()
            ScrollView(.vertical, showsIndicators: false) {
                VStack(alignment: .leading, spacing: 22) {
                    heroHeader
                        .opacity(heroShown ? 1 : 0)
                        .offset(y: heroShown ? 0 : 12)
                        .animation(.spring(response: 0.55, dampingFraction: 0.82), value: heroShown)

                    progressPanel

                    quickActionsRow

                    if let kind = suggestedSubject {
                        continueCard(for: kind)
                    } else if completedLevels >= totalLevelSlots, totalLevelSlots > 0 {
                        completionCelebrationCard
                    }

                    Text("Your subjects")
                        .font(.title3.bold())
                        .foregroundStyle(Color.appTextPrimary)

                    VStack(spacing: 14) {
                        ForEach(ActivityKind.allCases, id: \.self) { kind in
                            NavigationLink {
                                HomeSubjectFlowView(kind: kind)
                            } label: {
                                subjectRow(kind: kind)
                            }
                            .buttonStyle(.plain)
                        }
                    }

                    tipCard

                    Spacer(minLength: 28)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 20)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            heroShown = true
        }
    }

    private var heroHeader: some View {
        ZStack(alignment: .bottomLeading) {
            RoundedRectangle(cornerRadius: 26)
                .fill(
                    LinearGradient(
                        colors: [
                            Color.appSurface,
                            Color.appSurface.opacity(0.92),
                            Color.appPrimary.opacity(0.18)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay {
                    RoundedRectangle(cornerRadius: 26)
                        .stroke(AcademyGradients.cardBorder, lineWidth: 1)
                }
                .shadow(color: Color.appPrimary.opacity(0.22), radius: 24, x: 0, y: 14)
                .shadow(color: Color.appBackground.opacity(0.55), radius: 5, x: 0, y: 3)
                .frame(minHeight: 148)

            HStack(alignment: .bottom) {
                VStack(alignment: .leading, spacing: 8) {
                    Text(greeting)
                        .font(.title.bold())
                        .foregroundStyle(Color.appTextPrimary)
                    Text("Your hall is open—pick a subject or jump to the full activity wing.")
                        .font(.subheadline)
                        .foregroundStyle(Color.appTextSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                heroIllustration
                    .frame(width: 100, height: 100)
            }
            .padding(18)
        }
    }

    private var heroIllustration: some View {
        Canvas { context, size in
            let w = size.width
            let h = size.height
            var dome = Path()
            dome.addArc(
                center: CGPoint(x: w * 0.52, y: h * 0.55),
                radius: w * 0.38,
                startAngle: .degrees(200),
                endAngle: .degrees(-20),
                clockwise: true
            )
            context.stroke(dome, with: .color(Color.appAccent.opacity(0.9)), lineWidth: 3)

            let window = Path(roundedRect: CGRect(x: w * 0.35, y: h * 0.38, width: w * 0.34, height: h * 0.26), cornerSize: CGSize(width: 4, height: 4))
            context.fill(window, with: .color(Color.appBackground.opacity(0.55)))
            context.stroke(window, with: .color(Color.appPrimary.opacity(0.85)), lineWidth: 2)

            let sun = Path(ellipseIn: CGRect(x: w * 0.68, y: h * 0.08, width: w * 0.22, height: w * 0.22))
            context.fill(sun, with: .color(Color.appPrimary.opacity(0.95)))
            context.stroke(sun, with: .color(Color.appAccent.opacity(0.5)), lineWidth: 2)
        }
    }

    private var progressPanel: some View {
        HStack(alignment: .center, spacing: 18) {
            OverallProgressRing(fraction: overallProgress)
                .frame(width: 86, height: 86)

            VStack(alignment: .leading, spacing: 10) {
                Text("Overall progress")
                    .font(.headline)
                    .foregroundStyle(Color.appTextPrimary)
                Text("\(completedLevels) of \(totalLevelSlots) lessons cleared")
                    .font(.subheadline)
                    .foregroundStyle(Color.appTextSecondary)
                    .lineLimit(2)
                    .minimumScaleFactor(0.75)
                ProgressView(value: overallProgress)
                    .tint(Color.appAccent)
                    .scaleEffect(x: 1, y: 1.35, anchor: .center)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(18)
        .academyElevatedCard(cornerRadius: AcademyDepth.cornerLarge, elevated: true)
    }

    private var quickActionsRow: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Shortcuts")
                .font(.headline)
                .foregroundStyle(Color.appTextPrimary)

            HStack(spacing: 12) {
                Button {
                    Haptics.lightImpact()
                    tabCoordinator.selectedTab = 1
                } label: {
                    Label("Activity Wing", systemImage: "puzzlepiece.extension.fill")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Color.appBackground)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                        .frame(maxWidth: .infinity, minHeight: 48)
                        .background {
                            RoundedRectangle(cornerRadius: 16)
                                .fill(AcademyGradients.primaryCTA)
                                .shadow(color: Color.appPrimary.opacity(0.4), radius: 12, x: 0, y: 7)
                                .shadow(color: Color.appAccent.opacity(0.22), radius: 5, x: 0, y: 2)
                        }
                        .overlay {
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(Color.appAccent.opacity(0.35), lineWidth: 1)
                        }
                }
                .buttonStyle(.plain)

                Button {
                    Haptics.lightImpact()
                    tabCoordinator.selectedTab = 2
                } label: {
                    Label("Recognitions", systemImage: "star.circle.fill")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Color.appTextPrimary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                        .frame(maxWidth: .infinity, minHeight: 48)
                        .background {
                            RoundedRectangle(cornerRadius: 16)
                                .fill(AcademyGradients.surfaceCard)
                                .shadow(color: Color.appPrimary.opacity(0.14), radius: 10, x: 0, y: 5)
                        }
                        .overlay {
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(AcademyGradients.cardBorder, lineWidth: 2)
                        }
                }
                .buttonStyle(.plain)
            }

            metricsStrip
        }
    }

    private var metricsStrip: some View {
        HStack(spacing: 10) {
            metricChip(icon: "star.fill", title: "Stars", value: "\(store.totalStarsCount())")
            metricChip(icon: "flame.fill", title: "Sessions", value: "\(store.sessionsPlayed)")
            metricChip(icon: "rosette", title: "Badges", value: "\(unlockedAchievements)/\(AchievementDef.allCases.count)")
            metricChip(icon: "clock.fill", title: "Minutes", value: "\(learningMinutes)")
        }
    }

    private func metricChip(icon: String, title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundStyle(Color.appAccent)
            Text(title)
                .font(.caption2.weight(.medium))
                .foregroundStyle(Color.appTextSecondary)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
            Text(value)
                .font(.caption.weight(.bold))
                .foregroundStyle(Color.appTextPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(10)
        .academyElevatedCard(cornerRadius: AcademyDepth.cornerSmall, elevated: false)
    }

    private func continueCard(for kind: ActivityKind) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Continue learning")
                .font(.headline)
                .foregroundStyle(Color.appTextPrimary)
            Text("You have an open lesson in \(kind.titleKey). Tap to choose difficulty and resume.")
                .font(.subheadline)
                .foregroundStyle(Color.appTextSecondary)
                .fixedSize(horizontal: false, vertical: true)
            NavigationLink {
                HomeSubjectFlowView(kind: kind)
            } label: {
                Text("Open \(kind.titleKey)")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color.appBackground)
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
                    .frame(maxWidth: .infinity, minHeight: 48)
                    .background {
                        RoundedRectangle(cornerRadius: 16)
                            .fill(AcademyGradients.primaryCTA)
                            .shadow(color: Color.appPrimary.opacity(0.38), radius: 12, x: 0, y: 7)
                    }
                    .overlay {
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.appAccent.opacity(0.4), lineWidth: 1)
                    }
            }
            .buttonStyle(.plain)
        }
        .padding(18)
        .background {
            RoundedRectangle(cornerRadius: 22)
                .fill(
                    LinearGradient(
                        colors: [
                            Color.appPrimary.opacity(0.32),
                            Color.appSurface.opacity(0.95),
                            Color.appAccent.opacity(0.12)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .shadow(color: Color.appPrimary.opacity(0.25), radius: 18, x: 0, y: 10)
        }
        .overlay {
            RoundedRectangle(cornerRadius: 22)
                .stroke(AcademyGradients.cardBorder, lineWidth: 1.5)
        }
    }

    private var completionCelebrationCard: some View {
        HStack(spacing: 14) {
            StarShape()
                .fill(Color.appPrimary)
                .frame(width: 36, height: 36)
                .overlay {
                    StarShape()
                        .stroke(Color.appAccent, lineWidth: 1.5)
                }
            VStack(alignment: .leading, spacing: 6) {
                Text("Hall completed")
                    .font(.headline)
                    .foregroundStyle(Color.appTextPrimary)
                Text("Every lesson is cleared once. Replay harder tiers or chase three stars everywhere.")
                    .font(.caption)
                    .foregroundStyle(Color.appTextSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .academyElevatedCard(cornerRadius: AcademyDepth.cornerMedium, elevated: true)
    }

    private func subjectRow(kind: ActivityKind) -> some View {
        let stars = totalStars(for: kind)
        let done = store.completedLevelsCount(activity: kind)
        let total = DifficultyTier.allCases.count * LevelAddress.levelsPerTrack
        let ratio = total > 0 ? Double(done) / Double(total) : 0

        return VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 14) {
                subjectIcon(for: kind)
                    .frame(width: 56, height: 56)
                    .background {
                        RoundedRectangle(cornerRadius: 16)
                            .fill(
                                LinearGradient(
                                    colors: [Color.appBackground.opacity(0.5), Color.appSurface.opacity(0.55)],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                            .shadow(color: Color.appPrimary.opacity(0.12), radius: 6, y: 3)
                    }
                    .overlay {
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.appAccent.opacity(0.28), lineWidth: 1)
                    }

                VStack(alignment: .leading, spacing: 6) {
                    Text(kind.titleKey)
                        .font(.headline)
                        .foregroundStyle(Color.appTextPrimary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.75)
                    Text(subjectTagline(kind))
                        .font(.caption)
                        .foregroundStyle(Color.appTextSecondary)
                        .lineLimit(2)
                        .minimumScaleFactor(0.85)
                }
                Spacer(minLength: 8)
                VStack(alignment: .trailing, spacing: 6) {
                    HStack(spacing: 3) {
                        ForEach(0 ..< 3, id: \.self) { i in
                            StarShape()
                                .fill(stars > i * 18 ? Color.appPrimary : Color.appSurface.opacity(0.45))
                                .frame(width: 12, height: 12)
                        }
                    }
                    Text("\(stars) stars")
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(Color.appAccent)
                }
                Image(systemName: "chevron.right.circle.fill")
                    .font(.title2)
                    .foregroundStyle(Color.appAccent.opacity(0.9))
            }

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("Lessons cleared")
                        .font(.caption2.weight(.medium))
                        .foregroundStyle(Color.appTextSecondary)
                    Spacer()
                    Text("\(done)/\(total)")
                        .font(.caption2.weight(.bold))
                        .foregroundStyle(Color.appTextPrimary)
                }
                ProgressView(value: ratio)
                    .tint(Color.appAccent)
            }
        }
        .padding(16)
        .academyElevatedCard(cornerRadius: AcademyDepth.cornerLarge, elevated: true)
    }

    private var tipCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Tip for today", systemImage: "lightbulb.fill")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Color.appPrimary)
            Text("Short sessions beat long cramming—try one lesson per subject and compare your star counts on the results screen.")
                .font(.caption)
                .foregroundStyle(Color.appTextSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .academyElevatedCard(cornerRadius: AcademyDepth.cornerStandard, elevated: false)
    }

    private func subjectTagline(_ kind: ActivityKind) -> String {
        switch kind {
        case .mathExplorer:
            return "Numbers, patterns, and quick recall challenges."
        case .scienceLab:
            return "Hands-on mixing, gauges, and variable puzzles."
        case .languageAdventure:
            return "Words, order, and context clues."
        }
    }

    private func totalStars(for kind: ActivityKind) -> Int {
        var sum = 0
        for tier in DifficultyTier.allCases {
            for index in 0 ..< LevelAddress.levelsPerTrack {
                let address = LevelAddress(activity: kind, difficulty: tier, levelIndex: index)
                sum += store.stars(for: address)
            }
        }
        return sum
    }

    @ViewBuilder
    private func subjectIcon(for kind: ActivityKind) -> some View {
        switch kind {
        case .mathExplorer:
            Canvas { context, size in
                let rect = CGRect(origin: .zero, size: size)
                let grid = Path { path in
                    for offset in stride(from: 0, to: Int(size.width), by: 10) {
                        path.move(to: CGPoint(x: CGFloat(offset), y: 0))
                        path.addLine(to: CGPoint(x: CGFloat(offset), y: size.height))
                    }
                }
                context.stroke(grid, with: .color(Color.appPrimary.opacity(0.5)), lineWidth: 1.2)
                let bubble = Path(ellipseIn: rect.insetBy(dx: 10, dy: 10))
                context.fill(bubble, with: .color(Color.appAccent.opacity(0.28)))
            }
        case .scienceLab:
            Canvas { context, size in
                let tube = Path { path in
                    path.addRoundedRect(
                        in: CGRect(x: size.width * 0.3, y: size.height * 0.16, width: size.width * 0.4, height: size.height * 0.6),
                        cornerSize: CGSize(width: 10, height: 10)
                    )
                }
                context.fill(tube, with: .color(Color.appPrimary.opacity(0.4)))
                let flame = Path { path in
                    path.move(to: CGPoint(x: size.width * 0.5, y: size.height * 0.86))
                    path.addQuadCurve(
                        to: CGPoint(x: size.width * 0.5, y: size.height * 0.6),
                        control: CGPoint(x: size.width * 0.36, y: size.height * 0.72)
                    )
                    path.addQuadCurve(
                        to: CGPoint(x: size.width * 0.5, y: size.height * 0.86),
                        control: CGPoint(x: size.width * 0.64, y: size.height * 0.72)
                    )
                }
                context.fill(flame, with: .color(Color.appAccent.opacity(0.88)))
            }
        case .languageAdventure:
            Canvas { context, size in
                let book = Path { path in
                    path.addRoundedRect(
                        in: CGRect(x: size.width * 0.18, y: size.height * 0.2, width: size.width * 0.64, height: size.height * 0.58),
                        cornerSize: CGSize(width: 8, height: 8)
                    )
                }
                context.fill(book, with: .color(Color.appSurface))
                context.stroke(book, with: .color(Color.appAccent), lineWidth: 3)
                let line = Path { path in
                    path.move(to: CGPoint(x: size.width * 0.26, y: size.height * 0.42))
                    path.addLine(to: CGPoint(x: size.width * 0.74, y: size.height * 0.42))
                }
                context.stroke(line, with: .color(Color.appPrimary.opacity(0.85)), lineWidth: 3)
            }
        }
    }
}

private struct OverallProgressRing: View {
    let fraction: Double

    var body: some View {
        ZStack {
            Circle()
                .fill(
                    RadialGradient(
                        colors: [Color.appSurface.opacity(0.9), Color.appBackground.opacity(0.5)],
                        center: .center,
                        startRadius: 10,
                        endRadius: 48
                    )
                )
                .shadow(color: Color.appPrimary.opacity(0.2), radius: 8, y: 4)
            Circle()
                .stroke(Color.appBackground.opacity(0.55), lineWidth: 9)
            Circle()
                .trim(from: 0, to: CGFloat(min(1, max(0, fraction))))
                .stroke(
                    AngularGradient(
                        colors: [Color.appAccent, Color.appPrimary, Color.appAccent],
                        center: .center
                    ),
                    style: StrokeStyle(lineWidth: 9, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .shadow(color: Color.appAccent.opacity(0.35), radius: 4, y: 2)
            Text("\(Int(round(min(1, max(0, fraction)) * 100)))%")
                .font(.caption.weight(.bold))
                .foregroundStyle(Color.appTextPrimary)
        }
    }
}
