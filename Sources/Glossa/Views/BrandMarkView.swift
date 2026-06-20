import SwiftUI

struct BirdRibbonMarkView: View {
    var size: CGFloat = 36
    var isMenuBar = false

    var body: some View {
        ZStack {
            BirdSilhouette()
                .fill(markFill)
                .overlay {
                    BirdSilhouette()
                        .stroke(markStroke, lineWidth: isMenuBar ? 0.7 : 1.15)
                }

            RibbonCurve()
                .stroke(
                    markStroke,
                    style: StrokeStyle(
                        lineWidth: isMenuBar ? 1.4 : 2.4,
                        lineCap: .round,
                        lineJoin: .round
                    )
                )
        }
        .frame(width: size, height: size)
        .shadow(color: isMenuBar ? .clear : .white.opacity(0.18), radius: 6)
    }

    private var markFill: LinearGradient {
        LinearGradient(
            colors: isMenuBar
                ? [.primary.opacity(0.92), .primary.opacity(0.62)]
                : [.white.opacity(0.92), .white.opacity(0.52)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    private var markStroke: Color {
        isMenuBar ? .primary.opacity(0.78) : .white.opacity(0.74)
    }
}

private struct BirdSilhouette: Shape {
    func path(in rect: CGRect) -> Path {
        func p(_ x: CGFloat, _ y: CGFloat) -> CGPoint {
            CGPoint(x: rect.minX + rect.width * x, y: rect.minY + rect.height * y)
        }

        var path = Path()
        path.move(to: p(0.12, 0.67))
        path.addCurve(to: p(0.38, 0.56), control1: p(0.24, 0.66), control2: p(0.31, 0.60))
        path.addCurve(to: p(0.30, 0.24), control1: p(0.34, 0.47), control2: p(0.30, 0.35))
        path.addCurve(to: p(0.60, 0.46), control1: p(0.45, 0.29), control2: p(0.54, 0.38))
        path.addCurve(to: p(0.84, 0.39), control1: p(0.68, 0.36), control2: p(0.77, 0.34))
        path.addCurve(to: p(0.71, 0.50), control1: p(0.79, 0.43), control2: p(0.75, 0.47))
        path.addCurve(to: p(0.53, 0.64), control1: p(0.64, 0.55), control2: p(0.60, 0.61))
        path.addCurve(to: p(0.24, 0.85), control1: p(0.43, 0.70), control2: p(0.32, 0.76))
        path.addLine(to: p(0.32, 0.68))
        path.addCurve(to: p(0.12, 0.67), control1: p(0.25, 0.70), control2: p(0.18, 0.70))
        path.closeSubpath()
        return path
    }
}

private struct RibbonCurve: Shape {
    func path(in rect: CGRect) -> Path {
        func p(_ x: CGFloat, _ y: CGFloat) -> CGPoint {
            CGPoint(x: rect.minX + rect.width * x, y: rect.minY + rect.height * y)
        }

        var path = Path()
        path.move(to: p(0.80, 0.43))
        path.addCurve(to: p(0.90, 0.61), control1: p(0.93, 0.45), control2: p(0.95, 0.55))
        path.addCurve(to: p(0.77, 0.75), control1: p(0.85, 0.67), control2: p(0.79, 0.69))
        return path
    }
}

extension Color {
    static let glossaInk = Color(red: 0.02, green: 0.02, blue: 0.022)
    static let glossaFrost = Color(red: 0.88, green: 0.94, blue: 1.0)
}
