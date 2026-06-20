import AppKit
import SwiftUI

enum GlossaBrandAssets {
    static func appIconImage() -> NSImage? {
        loadImage(candidates: [
            ("Glossa-AppIcon", "png"),
            ("Glossa", "icns")
        ])
    }

    static func templateMarkImage() -> NSImage? {
        guard let image = loadImage(candidates: [("Glossa-MarkTemplate", "png")]) else {
            return nil
        }
        image.isTemplate = true
        return image
    }

    static func markImage() -> NSImage? {
        loadImage(candidates: [("Glossa-MarkTemplate", "png")])
    }

    private static func loadImage(candidates: [(String, String)]) -> NSImage? {
        for candidate in candidates {
            if let image = NSImage(named: candidate.0) {
                return image
            }

            if let url = Bundle.main.url(forResource: candidate.0, withExtension: candidate.1),
               let image = NSImage(contentsOf: url) {
                return image
            }

            let workingDirectoryURL = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
            let assetURL = workingDirectoryURL
                .appendingPathComponent("Assets", isDirectory: true)
                .appendingPathComponent("\(candidate.0).\(candidate.1)")
            if let image = NSImage(contentsOf: assetURL) {
                return image
            }
        }

        return nil
    }
}

struct GlossaAppIconView: View {
    var size: CGFloat = 56

    var body: some View {
        Group {
            if let image = GlossaBrandAssets.appIconImage() {
                Image(nsImage: image)
                    .resizable()
                    .interpolation(.high)
                    .antialiased(true)
                    .aspectRatio(contentMode: .fit)
            } else {
                RoundedRectangle(cornerRadius: size * 0.22)
                    .fill(.black)
                    .overlay {
                        GlossaMarkView(size: size * 0.62)
                    }
            }
        }
        .frame(width: size, height: size)
        .shadow(color: .black.opacity(0.40), radius: size * 0.28, y: size * 0.12)
    }
}

struct GlossaMarkView: View {
    var size: CGFloat = 36
    var template = false

    var body: some View {
        Group {
            if template, let image = GlossaBrandAssets.templateMarkImage() {
                Image(nsImage: image)
                    .resizable()
                    .renderingMode(.template)
                    .interpolation(.high)
                    .antialiased(true)
                    .aspectRatio(contentMode: .fit)
            } else if let image = GlossaBrandAssets.markImage() {
                Image(nsImage: image)
                    .resizable()
                    .interpolation(.high)
                    .antialiased(true)
                    .aspectRatio(contentMode: .fit)
            } else {
                BirdRibbonMarkView(size: size, isMenuBar: template)
            }
        }
        .frame(width: size, height: size)
    }
}

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
