import SwiftUI

struct AchievementsView: View {
    @EnvironmentObject private var store: AcademyProgressStore

    var body: some View {
        ZStack {
            AcademyScreenBackdrop()
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    headerIntro

                    Text("Recognitions")
                        .font(.largeTitle.bold())
                        .foregroundStyle(Color.appTextPrimary)

                    Text("These unlock automatically as you explore lessons and gather stars.")
                        .font(.body)
                        .foregroundStyle(Color.appTextSecondary)

                    LazyVStack(spacing: 12) {
                        ForEach(AchievementDef.allCases) { achievement in
                            achievementRow(achievement)
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 20)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
    }

    private var headerIntro: some View {
        HStack(spacing: 12) {
            Image(systemName: "trophy.fill")
                .font(.title2)
                .foregroundStyle(Color.appAccent)
                .frame(width: 48, height: 48)
                .background {
                    Circle()
                        .fill(AcademyGradients.surfaceCard)
                        .shadow(color: Color.appPrimary.opacity(0.22), radius: 8, x: 0, y: 4)
                }
                .overlay {
                    Circle()
                        .stroke(AcademyGradients.cardBorder, lineWidth: 1)
                }
            VStack(alignment: .leading, spacing: 4) {
                Text("Hall honors")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color.appAccent)
                Text("Keep learning to light every badge.")
                    .font(.caption)
                    .foregroundStyle(Color.appTextSecondary)
            }
            Spacer(minLength: 0)
        }
        .padding(14)
        .academyElevatedCard(cornerRadius: AcademyDepth.cornerMedium, elevated: false)
    }

    private func achievementRow(_ achievement: AchievementDef) -> some View {
        let unlocked = store.isAchievementUnlocked(achievement)
        return HStack(alignment: .top, spacing: 14) {
            ZStack {
                Group {
                    if unlocked {
                        Circle()
                            .fill(AcademyGradients.iconBadge)
                    } else {
                        Circle()
                            .fill(Color.appSurface)
                    }
                }
                .frame(width: 48, height: 48)
                .shadow(color: unlocked ? Color.appPrimary.opacity(0.35) : Color.clear, radius: 8, y: 4)
                Image(systemName: unlocked ? "star.fill" : "lock.fill")
                    .foregroundStyle(unlocked ? Color.appPrimary : Color.appTextSecondary)
            }
            VStack(alignment: .leading, spacing: 6) {
                Text(achievement.title)
                    .font(.headline)
                    .foregroundStyle(Color.appTextPrimary)
                Text(achievement.detail)
                    .font(.subheadline)
                    .foregroundStyle(Color.appTextSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
        }
        .padding(16)
        .academyElevatedCard(cornerRadius: AcademyDepth.cornerStandard, elevated: unlocked)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(Text("\(achievement.title), \(unlocked ? "unlocked" : "locked")"))
    }
}
