import StoreKit
import SwiftUI
import UIKit

struct SettingsView: View {
    var body: some View {
        ZStack {
            AcademyScreenBackdrop()
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text("Support & legal")
                        .font(.title2.bold())
                        .foregroundStyle(Color.appTextPrimary)

                    Text("Enjoying the lessons? Leave a rating or read our policies.")
                        .font(.subheadline)
                        .foregroundStyle(Color.appTextSecondary)

                    VStack(spacing: 12) {
                        settingsButton(title: "Rate us", systemImage: "star.fill") {
                            rateApp()
                        }

                        ForEach(AppExternalLink.allCases) { link in
                            settingsButton(title: link.settingsTitle, systemImage: icon(for: link)) {
                                openPolicy(link)
                            }
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 20)
            }
        }
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func icon(for link: AppExternalLink) -> String {
        switch link {
        case .privacyPolicy:
            return "hand.raised.fill"
        case .termsOfUse:
            return "doc.plaintext.fill"
        }
    }

    private func settingsButton(title: String, systemImage: String, action: @escaping () -> Void) -> some View {
        Button {
            Haptics.lightImpact()
            action()
        } label: {
            HStack(spacing: 14) {
                Image(systemName: systemImage)
                    .font(.title3)
                    .foregroundStyle(Color.appAccent)
                    .frame(width: 40, height: 40)
                    .background {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.appPrimary.opacity(0.2))
                    }
                Text(title)
                    .font(.headline)
                    .foregroundStyle(Color.appTextPrimary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
                Spacer(minLength: 8)
                Image(systemName: "chevron.right")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color.appTextSecondary)
            }
            .padding(16)
            .academyElevatedCard(cornerRadius: AcademyDepth.cornerStandard, elevated: true)
        }
        .buttonStyle(.plain)
    }

    private func openPolicy(_ link: AppExternalLink) {
        if let url = link.url {
            UIApplication.shared.open(url)
        }
    }

    private func rateApp() {
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
            SKStoreReviewController.requestReview(in: windowScene)
        }
    }
}
