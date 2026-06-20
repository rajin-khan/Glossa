import SwiftUI

struct MenuBarPermission {
    let title: String
    let detail: String
}

struct MenuBarLineCard: View {
    let languageName: String
    let translatedText: String?
    let sourceText: String?
    let subtitleID: UUID?

    var body: some View {
        VStack(alignment: .leading, spacing: 7) {
            HStack {
                Label("Current line", systemImage: "captions.bubble")
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.secondary)
                Spacer()
                Text(languageName)
                    .font(.caption2.weight(.medium))
                    .foregroundStyle(.secondary)
            }

            Text(translatedText ?? "Waiting for speech...")
                .font(.system(size: 15, weight: .semibold, design: .rounded))
                .lineLimit(3)
                .minimumScaleFactor(0.80)
                .id(subtitleID)
                .transition(.opacity.combined(with: .scale(scale: 0.985)))

            if let sourceText {
                Text(sourceText)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
                    .transition(.opacity)
            }
        }
        .padding(11)
        .frame(maxWidth: .infinity, minHeight: 82, alignment: .leading)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
        .animation(.smooth(duration: 0.28), value: subtitleID)
    }
}

struct MenuBarPermissionCard: View {
    let permission: MenuBarPermission
    let request: () -> Void

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(.yellow)

            VStack(alignment: .leading, spacing: 2) {
                Text(permission.title)
                    .font(.callout.weight(.semibold))
                Text(permission.detail)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }

            Spacer()
            Button("Open", action: request)
        }
        .padding(11)
        .background(.yellow.opacity(0.10), in: RoundedRectangle(cornerRadius: 12))
    }
}
