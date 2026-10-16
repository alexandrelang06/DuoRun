import SwiftUI

/// Pont entre la scène SpriteKit et l'interface SwiftUI. La scène pousse l'état de partie (en cours /
/// mort) et les stats ; l'UI affiche le panneau de mort et déclenche Recommencer / Revivre.
@MainActor
@Observable
final class GameBridge {
    enum Phase { case placement, playing, dead }
    var phase: Phase = .playing
    var runDistanceM: Int = 0
    var runCoins: Int = 0
    var runBestM: Int = 0
    var runIsRecord: Bool = false
    var runCompletedMissions: [Mission] = []
    /// Pièces gagnées via les missions accomplies pendant la partie.
    var runMissionCoins: Int { runCompletedMissions.reduce(0) { $0 + $1.reward } }

    weak var scene: GameScene?
    let model: AppModel
    init(model: AppModel) { self.model = model }

    /// Fin du placement duo (les deux joueurs prêts) : la partie démarre.
    func beginPlay() { scene?.begin(); phase = .playing }

    /// Appelé par la scène dès qu'un joueur tombe : pause pour les deux.
    func reportDeath(distanceM: Int, runCoins: Int, bestM: Int, isRecord: Bool, completedMissions: [Mission]) {
        self.runDistanceM = distanceM
        self.runCoins = runCoins
        self.runBestM = bestM
        self.runIsRecord = isRecord
        self.runCompletedMissions = completedMissions
        phase = .dead
    }

    func restart() { scene?.doRestart(); phase = .playing }

    /// Revivre en consommant une vie (ou des pièces). Continue la MÊME partie là où on est tombé.
    @discardableResult func revive() -> Bool {
        guard model.consumeRevive() else { return false }
        scene?.doRevive()
        phase = .playing
        return true
    }
}
