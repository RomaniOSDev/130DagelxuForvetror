import SwiftUI

struct ActivityHubView: View {
    @Binding var path: NavigationPath

    var body: some View {
        ZStack {
            AcademyScreenBackdrop()
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    Text("Activity Wing")
                        .font(.title.bold())
                        .foregroundStyle(Color.appTextPrimary)

                    Text("Choose a subject, pick a challenge tier, then unlock desks one lesson at a time.")
                        .font(.body)
                        .foregroundStyle(Color.appTextSecondary)

                    VStack(spacing: 14) {
                        ForEach(ActivityKind.allCases, id: \.self) { kind in
                            Button {
                                Haptics.lightImpact()
                                path.append(kind)
                            } label: {
                                HStack {
                                    Text(kind.titleKey)
                                        .font(.headline)
                                        .foregroundStyle(Color.appBackground)
                                        .lineLimit(1)
                                        .minimumScaleFactor(0.7)
                                    Spacer()
                                    Image(systemName: "arrow.right.circle.fill")
                                        .foregroundStyle(Color.appBackground.opacity(0.85))
                                }
                                .padding(.horizontal, 18)
                                .padding(.vertical, 16)
                                .background {
                                    RoundedRectangle(cornerRadius: 18)
                                        .fill(AcademyGradients.primaryCTA)
                                        .shadow(color: Color.appPrimary.opacity(0.42), radius: 14, x: 0, y: 8)
                                        .shadow(color: Color.appAccent.opacity(0.22), radius: 6, x: 0, y: 3)
                                }
                                .overlay {
                                    RoundedRectangle(cornerRadius: 18)
                                        .stroke(Color.appAccent.opacity(0.35), lineWidth: 1)
                                }
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel(Text("Open \(kind.titleKey)"))
                        }
                    }

                    Spacer(minLength: 8)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 20)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
    }
}
