import CoreGraphics

/// Génération procédurale seedée du monde (PRD §4.3, §13.2). Le monde s'assemble par chunks placés à
/// la volée devant le joueur et recyclés derrière. Une seule timeline / un seul seed : les deux pistes
/// du mode duo partageront cette même simulation, ce qui crée les réactions synchronisées.
final class WorldSim {

    private(set) var segments: [GroundSegment] = []
    private(set) var obstacles: [Obstacle] = []
    private(set) var coins: [Coin] = []
    private(set) var powerups: [Powerup] = []

    private var rng: SplitMix64
    private var frontier: CGFloat = 0          // monde généré jusqu'ici
    private var nextID = 0
    private var chunkIndex = 0
    private var sinceRespiration = 0
    private var lastWasTrap = false

    let seed: UInt64
    init(seed: UInt64) { self.seed = seed; rng = SplitMix64(seed: seed) }

    private func id() -> Int { defer { nextID += 1 }; return nextID }

    // MARK: Génération

    func ensureGenerated(upTo x: CGFloat) { while frontier < x { appendChunk() } }

    /// Difficulté croissante avec la distance : monte par paliers (~110 m) jusqu'à 10. Plus le monde
    /// avance, plus les obstacles s'enchaînent et les pièges (trous, doubles) sont fréquents.
    private func difficulty(at x: CGFloat) -> Int { 1 + min(9, Int(x / 2200)) }

    private enum ChunkType { case flat, barrel, cactus, beam, gap, double }

    private func chooseType(_ d: Int) -> ChunkType {
        // Respiration imposée, de moins en moins souvent quand la difficulté grimpe (9 → 4 chunks).
        let breather = max(4, 9 - d) + Int(rng.unit() * 2)
        if sinceRespiration >= breather { return .flat }
        var pool: [(ChunkType, Double)] = [
            (.flat, max(0.5, 1.4 - Double(d) * 0.1)),
            (.barrel, 1.6), (.cactus, 1.6), (.beam, 1.6 + Double(d) * 0.15),
            (.gap, 0.6 + Double(d) * 0.6), (.double, 0.2 + Double(d) * 0.5),
        ]
        if lastWasTrap { pool.removeAll { $0.0 == .gap || $0.0 == .double } }   // jamais 2 pièges de suite
        let total = pool.reduce(0) { $0 + $1.1 }
        var r = rng.unit() * total
        for (t, w) in pool { if r < w { return t }; r -= w }
        return .flat
    }

    private func solid(_ start: CGFloat, _ end: CGFloat) {
        segments.append(GroundSegment(id: id(), startX: start, endX: end))
    }
    /// Arche de pièces. Hauteurs bornées (base 42, sommet ≤ 126) pour rester atteignables au saut
    /// ET tenir dans la demi-hauteur d'une piste en mode duo (pas de débordement sur l'autre piste).
    private func coinArc(center: CGFloat, count: Int, peak: CGFloat, spread: CGFloat) {
        let p = min(peak, 70)   // sommet d'arche atteignable avec le nouveau saut plus bas
        for i in 0..<count {
            let t = count == 1 ? 0.5 : CGFloat(i) / CGFloat(count - 1)
            let y = 42 + p * (1 - 4 * (t - 0.5) * (t - 0.5))
            coins.append(Coin(id: id(), x: center + (t - 0.5) * spread, y: y))
        }
    }
    private func coinLine(from x: CGFloat, count: Int, gap: CGFloat, y: CGFloat) {
        for i in 0..<count { coins.append(Coin(id: id(), x: x + CGFloat(i) * gap, y: y)) }
    }

    private func appendChunk() {
        let start = frontier
        let d = difficulty(at: start)
        // Resserrement de l'espacement avec la difficulté (obstacles plus rapprochés, jamais infranchissable).
        let tight = CGFloat(min(150, (d - 1) * 20))
        // Le tout premier chunk est une intro plate sûre.
        let type: ChunkType = chunkIndex == 0 ? .flat : chooseType(d)
        chunkIndex += 1

        switch type {
        case .flat:
            let w: CGFloat = 520
            solid(start, start + w)
            coinLine(from: start + 120, count: 4, gap: 90, y: 90)
            if chunkIndex > 2 && rng.unit() < 0.30 {   // power-up occasionnel sur une respiration
                let k = PowerupKind.allCases[min(2, Int(rng.unit() * 3))]
                powerups.append(Powerup(id: id(), x: start + 300, y: 100, kind: k))
            }
            frontier = start + w
            sinceRespiration = 0
        case .barrel:
            let w: CGFloat = 600 - tight
            solid(start, start + w)
            obstacles.append(Obstacle(id: id(), x: start + 300, kind: .barrel))
            coinArc(center: start + 300, count: 5, peak: 120, spread: 260)
            frontier = start + w
        case .cactus:
            let w: CGFloat = 540 - tight
            solid(start, start + w)
            obstacles.append(Obstacle(id: id(), x: start + 280, kind: .cactus))
            frontier = start + w
        case .beam:
            let w: CGFloat = 620 - tight
            solid(start, start + w)
            obstacles.append(Obstacle(id: id(), x: start + 320, kind: .beam))
            // Pièces au ras du sol DANS le couloir de glissade (bien sous la barre à y=42-62),
            // ramassées en slidant — plus jamais collées à l'obstacle.
            coinLine(from: start + 288, count: 3, gap: 32, y: 14)
            frontier = start + w
        case .gap:
            let gapW = min(205, 150 + CGFloat(d) * 10)      // borné (saut plus bas) : toujours franchissable
            let lead: CGFloat = 300, tail: CGFloat = 300
            let gapStart = start + lead
            solid(start, gapStart)
            solid(gapStart + gapW, gapStart + gapW + tail)
            coinArc(center: gapStart + gapW / 2, count: 5, peak: 160, spread: gapW + 120)
            frontier = gapStart + gapW + tail
        case .double:
            let w: CGFloat = 760 - tight
            solid(start, start + w)
            obstacles.append(Obstacle(id: id(), x: start + 260, kind: .barrel))
            obstacles.append(Obstacle(id: id(), x: start + 560, kind: .cactus))
            frontier = start + w
        }
        if type != .flat { sinceRespiration += 1 }
        lastWasTrap = (type == .gap || type == .double)
    }

    // MARK: Requêtes / entretien

    func hasGround(at x: CGFloat) -> Bool {
        for s in segments where x >= s.startX && x <= s.endX { return true }
        return false
    }

    /// Retire ce qui est passé loin derrière (recyclage mémoire).
    func cull(before x: CGFloat) {
        segments.removeAll { $0.endX < x }
        obstacles.removeAll { $0.x < x }
        coins.removeAll { $0.x < x }
        powerups.removeAll { $0.x < x }
    }
}
