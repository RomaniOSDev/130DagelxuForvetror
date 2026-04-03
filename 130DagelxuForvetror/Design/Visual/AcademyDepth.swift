import SwiftUI

// MARK: - Layout

enum AcademyDepth {
    static let cornerLarge: CGFloat = 26
    static let cornerMedium: CGFloat = 20
    static let cornerStandard: CGFloat = 18
    static let cornerSmall: CGFloat = 14
}

// MARK: - Gradients (palette only)

enum AcademyGradients {
    static var screenBase: LinearGradient {
        LinearGradient(
            colors: [
                Color.appBackground,
                Color.appBackground,
                Color.appSurface.opacity(0.42)
            ],
            startPoint: .top,
            endPoint: .bottom
        )
    }

    static var screenGlowLeading: RadialGradient {
        RadialGradient(
            colors: [Color.appPrimary.opacity(0.26), Color.clear],
            center: .topLeading,
            startRadius: 8,
            endRadius: 440
        )
    }

    static var screenGlowTrailing: RadialGradient {
        RadialGradient(
            colors: [Color.appAccent.opacity(0.2), Color.clear],
            center: .bottomTrailing,
            startRadius: 24,
            endRadius: 380
        )
    }

    /// Cards, panels, stat blocks
    static var surfaceCard: LinearGradient {
        LinearGradient(
            colors: [
                Color.appSurface.opacity(0.99),
                Color.appSurface,
                Color.appPrimary.opacity(0.07)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    /// Primary CTAs, answer chips
    static var primaryCTA: LinearGradient {
        LinearGradient(
            colors: [Color.appAccent, Color.appPrimary],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    static var primaryCTAPressed: LinearGradient {
        LinearGradient(
            colors: [Color.appPrimary.opacity(0.92), Color.appAccent.opacity(0.88)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    static var cardBorder: LinearGradient {
        LinearGradient(
            colors: [Color.appAccent.opacity(0.55), Color.appPrimary.opacity(0.25)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    static var achievementBanner: LinearGradient {
        LinearGradient(
            colors: [Color.appAccent, Color.appPrimary.opacity(0.9)],
            startPoint: .leading,
            endPoint: .trailing
        )
    }

    static var iconBadge: RadialGradient {
        RadialGradient(
            colors: [Color.appAccent.opacity(0.45), Color.appPrimary.opacity(0.18)],
            center: .topLeading,
            startRadius: 2,
            endRadius: 56
        )
    }
}

// MARK: - Screen chrome

struct AcademyScreenBackdrop: View {
    var body: some View {
        ZStack {
            Color.appBackground
            AcademyGradients.screenBase
            AcademyGradients.screenGlowLeading
            AcademyGradients.screenGlowTrailing
        }
        .ignoresSafeArea()
    }
}

// MARK: - View extensions

extension View {
    /// Gradient fill, dual shadow stack, and luminous border for cards.
    func academyElevatedCard(
        cornerRadius: CGFloat = AcademyDepth.cornerStandard,
        elevated: Bool = true
    ) -> some View {
        let lift: CGFloat = elevated ? 12 : 7
        let spread: CGFloat = elevated ? 18 : 11
        return self
            .background {
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(AcademyGradients.surfaceCard)
                    .shadow(color: Color.appPrimary.opacity(elevated ? 0.28 : 0.16), radius: spread, x: 0, y: lift)
                    .shadow(color: Color.appBackground.opacity(0.65), radius: 4, x: 0, y: 3)
            }
            .overlay {
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(AcademyGradients.cardBorder, lineWidth: 1)
            }
    }

    func academyInsetWell(cornerRadius: CGFloat = AcademyDepth.cornerMedium) -> some View {
        background {
            RoundedRectangle(cornerRadius: cornerRadius)
                .fill(
                    LinearGradient(
                        colors: [
                            Color.appBackground.opacity(0.55),
                            Color.appSurface.opacity(0.92)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .overlay {
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .stroke(Color.appAccent.opacity(0.22), lineWidth: 1)
                }
                .shadow(color: Color.appBackground.opacity(0.45), radius: 2, x: 0, y: 2)
        }
    }

    func academyFloatingCapsule() -> some View {
        background {
            Capsule()
                .fill(AcademyGradients.primaryCTA)
                .shadow(color: Color.appPrimary.opacity(0.35), radius: 10, x: 0, y: 6)
                .shadow(color: Color.appAccent.opacity(0.22), radius: 4, x: 0, y: 2)
        }
    }
}
