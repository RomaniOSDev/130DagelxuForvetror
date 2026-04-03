import SwiftUI

struct DifficultySelectView: View {
    let activity: ActivityKind
    @Binding var path: NavigationPath

    var body: some View {
        ZStack {
            AcademyScreenBackdrop()
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Select challenge")
                            .font(.title2.bold())
                            .foregroundStyle(Color.appTextPrimary)
                        Text(descriptionCopy)
                            .font(.body)
                            .foregroundStyle(Color.appTextSecondary)
                    }
                    .padding(16)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .academyElevatedCard(cornerRadius: AcademyDepth.cornerMedium, elevated: true)

                    VStack(spacing: 12) {
                        ForEach(DifficultyTier.allCases, id: \.self) { tier in
                            Button {
                                Haptics.lightImpact()
                                path.append(DifficultyRoute(activity: activity, tier: tier))
                            } label: {
                                VStack(alignment: .leading, spacing: 8) {
                                    Text(tier.title)
                                        .font(.headline)
                                        .foregroundStyle(Color.appTextPrimary)
                                        .lineLimit(1)
                                        .minimumScaleFactor(0.7)
                                    Text(tierBlurb(tier))
                                        .font(.subheadline)
                                        .foregroundStyle(Color.appTextSecondary)
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(16)
                                .academyElevatedCard(cornerRadius: AcademyDepth.cornerStandard, elevated: true)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 18)
            }
        }
        .navigationTitle(activity.titleKey)
        .navigationBarTitleDisplayMode(.inline)
    }

    private var descriptionCopy: String {
        switch activity {
        case .mathExplorer:
            return "Easy keeps drills relaxed, Normal adds rhythm, Hard stacks multiple steps."
        case .scienceLab:
            return "Easy snaps tools into place, Normal tracks animated readings, Hard mixes hypotheses with sliders."
        case .languageAdventure:
            return "Easy highlights gentle vocabulary, Normal scrambles sentences, Hard leans on context riddles."
        }
    }

    private func tierBlurb(_ tier: DifficultyTier) -> String {
        switch tier {
        case .easy:
            return "Generous hints, forgiving scoring, perfect for warmup."
        case .normal:
            return "Lively pacing with timers or extra precision."
        case .hard:
            return "Fewer misses allowed and trickier prompts."
        }
    }
}
