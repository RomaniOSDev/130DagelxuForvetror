import SwiftUI

struct StarShape: Shape {
    func path(in rect: CGRect) -> Path {
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let radius = min(rect.width, rect.height) / 2
        var path = Path()
        let points = 5
        let adjustment = -CGFloat.pi / 2
        for index in 0 ..< points * 2 {
            let angle = adjustment + CGFloat(index) * .pi / CGFloat(points)
            let r = index.isMultiple(of: 2) ? radius : radius * 0.45
            let point = CGPoint(
                x: center.x + cos(angle) * r,
                y: center.y + sin(angle) * r
            )
            if index == 0 {
                path.move(to: point)
            } else {
                path.addLine(to: point)
            }
        }
        path.closeSubpath()
        return path
    }
}

struct GlowingStarView: View {
    let filled: Bool
    let size: CGFloat
    @State private var scale: CGFloat = 0.01
    @State private var glow: CGFloat = 0

    var body: some View {
        ZStack {
            StarShape()
                .fill(Color.appAccent.opacity(0.35))
                .frame(width: size * 1.35, height: size * 1.35)
                .blur(radius: glow)

            StarShape()
                .fill(filled ? Color.appPrimary : Color.appSurface)
                .overlay {
                    StarShape()
                        .stroke(Color.appAccent.opacity(filled ? 0.9 : 0.35), lineWidth: 2)
                }
                .frame(width: size, height: size)
        }
        .scaleEffect(scale)
        .onAppear {
            withAnimation(.spring(response: 0.55, dampingFraction: 0.55)) {
                scale = 1
                glow = filled ? 6 : 2
            }
        }
    }
}
