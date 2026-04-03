import SwiftUI

struct ProfileView: View {
    @EnvironmentObject private var store: AcademyProgressStore
    @State private var confirmReset = false

    var body: some View {
        ZStack {
            AcademyScreenBackdrop()
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    profileHeaderCard

                    Text("Your desk")
                        .font(.largeTitle.bold())
                        .foregroundStyle(Color.appTextPrimary)

                    Text("Track learning habits here. No accounts are needed—everything stays on this device.")
                        .font(.body)
                        .foregroundStyle(Color.appTextSecondary)

                    NavigationLink {
                        SettingsView()
                    } label: {
                        HStack(spacing: 14) {
                            Image(systemName: "gearshape.fill")
                                .font(.title2)
                                .foregroundStyle(Color.appAccent)
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Settings")
                                    .font(.headline)
                                    .foregroundStyle(Color.appTextPrimary)
                                Text("Rate us, Privacy, Terms")
                                    .font(.caption)
                                    .foregroundStyle(Color.appTextSecondary)
                            }
                            Spacer(minLength: 0)
                            Image(systemName: "chevron.right")
                                .foregroundStyle(Color.appTextSecondary)
                        }
                        .padding(16)
                        .academyElevatedCard(cornerRadius: AcademyDepth.cornerMedium, elevated: true)
                    }
                    .buttonStyle(.plain)

                    VStack(spacing: 12) {
                        statBlock(title: "Total learning time", value: formattedPlaytime)
                        statBlock(title: "Lessons attempted", value: "\(store.sessionsPlayed)")
                        statBlock(title: "Total stars", value: "\(store.totalStarsCount())")
                        statBlock(
                            title: "Lessons cleared",
                            value: "\(completedLessonsAcrossTracks)"
                        )
                    }

                    Button(role: .destructive) {
                        confirmReset = true
                    } label: {
                        Text("Reset All Progress")
                            .academyButtonLabel()
                    }
                    .buttonStyle(AcademySecondaryButton())
                    .padding(.top, 8)
                    .confirmationDialog(
                        "Reset all saved lessons, stars, and recognitions?",
                        isPresented: $confirmReset,
                        titleVisibility: .visible
                    ) {
                        Button("Reset Everything", role: .destructive) {
                            Haptics.warning()
                            store.resetAllProgress()
                        }
                        Button("Cancel", role: .cancel) {}
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 20)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
    }

    private var profileHeaderCard: some View {
        HStack(spacing: 14) {
            Image(systemName: "person.crop.circle.fill")
                .font(.system(size: 40))
                .foregroundStyle(
                    LinearGradient(
                        colors: [Color.appAccent, Color.appPrimary],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .shadow(color: Color.appPrimary.opacity(0.3), radius: 8, y: 4)
            VStack(alignment: .leading, spacing: 4) {
                Text("Learner space")
                    .font(.headline)
                    .foregroundStyle(Color.appTextPrimary)
                Text("Private, on-device progress only.")
                    .font(.caption)
                    .foregroundStyle(Color.appTextSecondary)
            }
            Spacer(minLength: 0)
        }
        .padding(16)
        .academyElevatedCard(cornerRadius: AcademyDepth.cornerMedium, elevated: true)
    }

    private var formattedPlaytime: String {
        let seconds = Int(store.totalPlaySeconds.rounded())
        let minutes = seconds / 60
        let remainder = seconds % 60
        if minutes == 0 {
            return "\(seconds) sec"
        }
        return "\(minutes) min \(remainder) sec"
    }

    private var completedLessonsAcrossTracks: Int {
        ActivityKind.allCases.reduce(0) { partial, kind in
            partial + store.completedLevelsCount(activity: kind)
        }
    }

    private func statBlock(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Color.appTextSecondary)
            Text(value)
                .font(.title2.weight(.bold))
                .foregroundStyle(Color.appTextPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .academyElevatedCard(cornerRadius: AcademyDepth.cornerStandard, elevated: false)
    }
}
