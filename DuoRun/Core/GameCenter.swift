import GameKit
import SwiftUI

/// Intégration Game Center : authentification, soumission de la distance au classement, dashboard.
/// Nécessite la capability Game Center (entitlement) + les classements créés dans App Store Connect ;
/// sans ça l'auth échoue silencieusement et les soumissions sont ignorées.
@MainActor
@Observable
final class GameCenter {
    static let shared = GameCenter()
    var authenticated = false
    static let boardDistance = "duorun.distance"

    func authenticate() {
        GKLocalPlayer.local.authenticateHandler = { [weak self] _, _ in
            self?.authenticated = GKLocalPlayer.local.isAuthenticated
        }
    }

    func submit(distanceM: Int) {
        guard authenticated, distanceM > 0 else { return }
        Task {
            try? await GKLeaderboard.submitScore(distanceM, context: 0, player: GKLocalPlayer.local,
                                                 leaderboardIDs: [Self.boardDistance])
        }
    }
}

/// Présente le dashboard Game Center (classements) depuis SwiftUI.
struct GameCenterView: UIViewControllerRepresentable {
    @Environment(\.dismiss) private var dismiss
    func makeUIViewController(context: Context) -> GKGameCenterViewController {
        let vc = GKGameCenterViewController(state: .leaderboards)
        vc.gameCenterDelegate = context.coordinator
        return vc
    }
    func updateUIViewController(_ vc: GKGameCenterViewController, context: Context) {}
    func makeCoordinator() -> Coordinator { Coordinator(dismiss: dismiss) }

    final class Coordinator: NSObject, GKGameCenterControllerDelegate {
        let dismiss: DismissAction
        init(dismiss: DismissAction) { self.dismiss = dismiss }
        func gameCenterViewControllerDidFinish(_ vc: GKGameCenterViewController) { dismiss() }
    }
}
