import Foundation

/// Central place for outbound URLs (privacy, terms, etc.).
enum AppExternalLink: String, CaseIterable, Identifiable {
    case privacyPolicy
    case termsOfUse

    var id: String { rawValue }

    /// Replace with your live URLs before release.
    private var urlString: String {
        switch self {
        case .privacyPolicy:
            return "https://dagelxu130forvetror.site/privacy/80"
        case .termsOfUse:
            return "https://dagelxu130forvetror.site/terms/80"
        }
    }

    var url: URL? {
        URL(string: urlString)
    }

    var settingsTitle: String {
        switch self {
        case .privacyPolicy:
            return "Privacy Policy"
        case .termsOfUse:
            return "Terms of Use"
        }
    }
}
