import SwiftUI

struct ListeningBadge: View {
    let state: ListeningState

    var body: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(state.statusColor)
                .frame(width: 8, height: 8)
            Text(state.label)
                .font(.callout.weight(.medium))
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 7)
        .background(.regularMaterial, in: Capsule())
    }
}

struct ListeningStatusPill: View {
    let state: ListeningState

    var body: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(state.statusColor)
                .frame(width: 7, height: 7)
                .shadow(color: state.statusColor.opacity(isActive ? 0.45 : 0), radius: isActive ? 6 : 0)
            Text(state.compactLabel)
        }
        .font(.caption.weight(.semibold))
        .padding(.horizontal, 9)
        .padding(.vertical, 5)
        .background(.white.opacity(0.08), in: Capsule())
        .animation(.easeInOut(duration: 0.22), value: state)
    }

    private var isActive: Bool {
        switch state {
        case .listening, .previewing:
            true
        case .idle, .starting, .failed:
            false
        }
    }
}

