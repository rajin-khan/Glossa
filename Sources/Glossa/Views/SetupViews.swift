import SwiftUI

struct PermissionRow: View {
    let title: String
    let detail: String
    let state: CapturePermissionState
    let actionTitle: String
    let action: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(color)
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.callout.weight(.semibold))
                Text(detail)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Text(state.label)
                .font(.caption.weight(.medium))
                .foregroundStyle(color)

            Button(actionTitle, action: action)
                .disabled(state.isReady)
        }
        .padding(12)
        .background(.quaternary.opacity(0.32), in: RoundedRectangle(cornerRadius: 8))
    }

    private var icon: String {
        switch state {
        case .granted:
            "checkmark.circle.fill"
        case .needsPermission:
            "exclamationmark.circle.fill"
        case .denied:
            "xmark.circle.fill"
        case .unknown:
            "questionmark.circle.fill"
        }
    }

    private var color: Color {
        switch state {
        case .granted:
            .teal
        case .needsPermission:
            .yellow
        case .denied:
            .red
        case .unknown:
            .secondary
        }
    }
}

struct LocalModelPreparationView: View {
    @ObservedObject var store: GlossaStore

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Label("Local Speech Model", systemImage: "cpu")
                    .font(.callout.weight(.semibold))
                Spacer()
                Text(store.localModelStatus.label)
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(statusColor)
                    .lineLimit(1)
            }

            if let progress = store.localModelStatus.progress {
                ProgressView(value: progress)
                    .progressViewStyle(.linear)
            }

            HStack {
                Text("The tiny multilingual model is downloaded once and runs entirely on this Mac.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
                Button(store.localModelStatus.preparationActionTitle) {
                    store.prepareLocalModel()
                }
                .disabled(!store.localModelStatus.canPrepare)
            }
        }
        .padding(.vertical, 6)
    }

    private var statusColor: Color {
        switch store.localModelStatus {
        case .notPrepared, .downloaded, .unavailable:
            .secondary
        case .downloading, .loading:
            .yellow
        case .ready:
            .teal
        case .failed:
            .red
        }
    }
}

struct RuntimeIssue {
    let title: String
    let detail: String
    let actionTitle: String?
    let action: (() -> Void)?
}

struct RuntimeIssueBanner: View {
    let issue: RuntimeIssue

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "exclamationmark.circle.fill")
                .font(.title3)
                .foregroundStyle(.red)

            VStack(alignment: .leading, spacing: 3) {
                Text(issue.title)
                    .font(.callout.weight(.semibold))
                Text(issue.detail)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(3)
            }

            Spacer()

            if let actionTitle = issue.actionTitle,
               let action = issue.action {
                Button(actionTitle, action: action)
            }
        }
        .padding(14)
        .background(.red.opacity(0.07), in: RoundedRectangle(cornerRadius: 14))
        .overlay {
            RoundedRectangle(cornerRadius: 14)
                .strokeBorder(.red.opacity(0.20))
        }
    }
}

