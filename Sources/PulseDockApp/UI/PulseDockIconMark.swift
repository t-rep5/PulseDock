import SwiftUI

struct PulseDockIconMark: View {
    let size: CGFloat

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: size * 0.24, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            Color(red: 0.08, green: 0.12, blue: 0.18),
                            Color(red: 0.09, green: 0.24, blue: 0.28)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            Circle()
                .fill(Color(red: 0.11, green: 0.82, blue: 0.72).opacity(0.34))
                .blur(radius: size * 0.13)
                .offset(x: size * 0.23, y: -size * 0.22)

            PulseLine()
                .stroke(
                    LinearGradient(
                        colors: [.white, Color(red: 0.36, green: 1.0, blue: 0.84)],
                        startPoint: .leading,
                        endPoint: .trailing
                    ),
                    style: StrokeStyle(lineWidth: max(size * 0.075, 2), lineCap: .round, lineJoin: .round)
                )
                .padding(size * 0.22)
        }
        .frame(width: size, height: size)
        .shadow(color: Color.black.opacity(0.12), radius: size * 0.08, x: 0, y: size * 0.04)
    }
}

private struct PulseLine: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let midY = rect.midY
        let width = rect.width
        let height = rect.height

        path.move(to: CGPoint(x: rect.minX, y: midY))
        path.addLine(to: CGPoint(x: rect.minX + width * 0.20, y: midY))
        path.addLine(to: CGPoint(x: rect.minX + width * 0.32, y: midY - height * 0.30))
        path.addLine(to: CGPoint(x: rect.minX + width * 0.45, y: midY + height * 0.33))
        path.addLine(to: CGPoint(x: rect.minX + width * 0.58, y: midY - height * 0.47))
        path.addLine(to: CGPoint(x: rect.minX + width * 0.72, y: midY))
        path.addLine(to: CGPoint(x: rect.maxX, y: midY))
        return path
    }
}
