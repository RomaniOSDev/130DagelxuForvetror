import SwiftUI

struct AcademyFilledButton: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline.weight(.semibold))
            .foregroundStyle(Color.appBackground)
            .frame(maxWidth: .infinity)
            .frame(minHeight: 48)
            .background {
                RoundedRectangle(cornerRadius: 14)
                    .fill(configuration.isPressed ? AcademyGradients.primaryCTAPressed : AcademyGradients.primaryCTA)
                    .shadow(color: Color.appPrimary.opacity(0.38), radius: configuration.isPressed ? 6 : 12, x: 0, y: configuration.isPressed ? 4 : 8)
                    .shadow(color: Color.appAccent.opacity(0.2), radius: 4, x: 0, y: 2)
            }
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .animation(.easeInOut(duration: 0.18), value: configuration.isPressed)
    }
}

struct AcademySecondaryButton: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline.weight(.semibold))
            .foregroundStyle(Color.appTextPrimary)
            .frame(maxWidth: .infinity)
            .frame(minHeight: 48)
            .background {
                RoundedRectangle(cornerRadius: 14)
                    .fill(AcademyGradients.surfaceCard)
                    .shadow(color: Color.appPrimary.opacity(0.14), radius: 10, x: 0, y: 6)
                    .shadow(color: Color.appBackground.opacity(0.55), radius: 3, x: 0, y: 2)
            }
            .overlay {
                RoundedRectangle(cornerRadius: 14)
                    .stroke(AcademyGradients.cardBorder, lineWidth: 2)
            }
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .animation(.easeInOut(duration: 0.18), value: configuration.isPressed)
    }
}

extension View {
    func academyButtonLabel() -> some View {
        lineLimit(1)
            .minimumScaleFactor(0.7)
            .multilineTextAlignment(.center)
    }
}
