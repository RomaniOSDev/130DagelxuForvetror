import SwiftUI

struct ActivityResultView: View {
    let payload: ResultPayload
    @Binding var path: NavigationPath
    @EnvironmentObject private var store: AcademyProgressStore

    @State private var animatedStars = 0
    @State private var showBanner = false

    var body: some View {
        ZStack {
            AcademyScreenBackdrop()
            ScrollView {
                VStack(spacing: 20) {
                    if showBanner, let achievement = payload.freshAchievements.first {
                        achievementBanner(achievement)
                            .transition(.move(edge: .top).combined(with: .opacity))
                    }

                    Text(payload.summary.passed ? "Lesson complete" : "Not quite there yet")
                        .font(.title2.bold())
                        .foregroundStyle(Color.appTextPrimary)
                        .multilineTextAlignment(.center)

                    Text(subtitle)
                        .font(.body)
                        .foregroundStyle(Color.appTextSecondary)
                        .multilineTextAlignment(.center)

                    HStack(spacing: 14) {
                        ForEach(0 ..< 3, id: \.self) { index in
                            let filled = index < payload.summary.starsEarned
                            StarShape()
                                .fill(filled ? Color.appPrimary : Color.appSurface.opacity(0.55))
                                .overlay {
                                    StarShape()
                                        .stroke(Color.appAccent.opacity(filled ? 1 : 0.35), lineWidth: 2)
                                }
                                .frame(width: 56, height: 56)
                                .shadow(color: filled ? Color.appAccent.opacity(0.65) : .clear, radius: filled ? 12 : 0)
                                .scaleEffect(animatedStars > index ? 1 : 0.2)
                                .opacity(animatedStars > index ? 1 : 0.25)
                        }
                    }
                    .padding(.vertical, 8)

                    VStack(alignment: .leading, spacing: 10) {
                        statRow(title: "Accuracy", value: "\(payload.summary.accuracyPercent)%")
                        statRow(
                            title: "Time",
                            value: String(format: "%.1f s", payload.summary.durationSeconds)
                        )
                        statRow(
                            title: "Stars this lesson",
                            value: "\(payload.summary.starsEarned)"
                        )
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(16)
                    .academyElevatedCard(cornerRadius: AcademyDepth.cornerStandard, elevated: true)

                    actionButtons
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 24)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .onAppear {
            animateStarsSequentially()
            if !payload.freshAchievements.isEmpty {
                withAnimation(.spring(response: 0.55, dampingFraction: 0.82).delay(0.05)) {
                    showBanner = true
                }
            }
        }
    }

    private var subtitle: String {
        if payload.summary.passed {
            return "Accuracy and pacing feed directly into the stars you unlocked."
        }
        return "Try a calmer pace, read prompts twice, then jump back in."
    }

    private func achievementBanner(_ achievement: AchievementDef) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("New recognition")
                .font(.caption.weight(.semibold))
                .foregroundStyle(Color.appBackground)
            Text(achievement.title)
                .font(.headline)
                .foregroundStyle(Color.appBackground)
            Text(achievement.detail)
                .font(.subheadline)
                .foregroundStyle(Color.appBackground.opacity(0.85))
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background {
            RoundedRectangle(cornerRadius: 18)
                .fill(AcademyGradients.achievementBanner)
                .shadow(color: Color.appPrimary.opacity(0.45), radius: 14, x: 0, y: 8)
                .shadow(color: Color.appAccent.opacity(0.28), radius: 6, x: 0, y: 3)
        }
        .overlay {
            RoundedRectangle(cornerRadius: 18)
                .stroke(Color.appAccent.opacity(0.35), lineWidth: 1)
        }
    }

    private func statRow(title: String, value: String) -> some View {
        HStack {
            Text(title)
                .foregroundStyle(Color.appTextSecondary)
            Spacer()
            Text(value)
                .font(.headline)
                .foregroundStyle(Color.appTextPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
    }

    private var actionButtons: some View {
        VStack(spacing: 12) {
            if let next = nextAddress, payload.summary.passed {
                Button {
                    Haptics.lightImpact()
                    path.removeLast()
                    path.removeLast()
                    path.append(PlayDestination(address: next))
                } label: {
                    Text("Next Level")
                        .academyButtonLabel()
                }
                .buttonStyle(AcademyFilledButton())
                .opacity(store.isLevelUnlocked(next) ? 1 : 0.45)
                .disabled(!store.isLevelUnlocked(next))
            }

            Button {
                Haptics.lightImpact()
                path.removeLast()
                path.removeLast()
                path.append(PlayDestination(address: payload.address))
            } label: {
                Text("Retry")
                    .academyButtonLabel()
            }
            .buttonStyle(AcademySecondaryButton())

            Button {
                Haptics.lightImpact()
                if path.count >= 2 {
                    path.removeLast(2)
                }
            } label: {
                Text("Back to Levels")
                    .academyButtonLabel()
            }
            .buttonStyle(AcademySecondaryButton())
        }
    }

    private var nextAddress: LevelAddress? {
        let nextIndex = payload.address.levelIndex + 1
        guard nextIndex < LevelAddress.levelsPerTrack else { return nil }
        return LevelAddress(
            activity: payload.address.activity,
            difficulty: payload.address.difficulty,
            levelIndex: nextIndex
        )
    }

    private func animateStarsSequentially() {
        for index in 0 ..< 3 {
            let delay = 0.15 * Double(index)
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                withAnimation(.spring(response: 0.55, dampingFraction: 0.58)) {
                    animatedStars = index + 1
                }
            }
        }
    }
}
