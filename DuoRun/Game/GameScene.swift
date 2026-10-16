import SpriteKit

enum GameMode { case solo, duo }

/// Scène orchestratrice. Un seul monde procédural et une distance partagés ; une piste (solo) ou deux
/// (duo tête-bêche : piste B pivotée de 180°, les deux joueurs face à face autour de la ligne
/// médiane). Chaque piste a son coureur ; on saute/glisse indépendamment sur SA moitié d'écran.
final class GameScene: SKScene {

    var mode: GameMode = .duo
    var biome: Biome = .western

    private let tuningSolo = Tuning()
    // En duo chaque piste fait la demi-hauteur : sauts plus courts pour tenir dans la piste.
    private let tuningDuo = Tuning(gravity: -3200, jumpV: 900, doubleV: 820,
                                   glideCap: -220, diveV: -1500, baseSpeed: 340, maxSpeed: 560, fallLimit: 360)
    private var tuning = Tuning()

    // Un monde procédural INDÉPENDANT par piste : chaque côté a son propre parcours (seeds différents).
    private var sims: [WorldSim] = []
    private var collectedCoins: [Set<Int>] = []
    private var collectedPowerups: [Set<Int>] = []
    private var distance: CGFloat = 0
    private var magnetTimer: Double = 0
    private var totalCoins = 0
    // Multiplicateur coop partagé : grimpe en enchaînant les pièces, retombe si un joueur se fait toucher.
    private var comboMult = 1
    private var comboProgress = 0
    private var spawnAhead: CGFloat = 1200
    private let trailMargin: CGFloat = 320
    private var dead = false
    var started = true            // en duo, faux jusqu'à la fin de l'écran de placement
    private var lastTime: TimeInterval = 0
    private var lastMeters = 0
    private var runCompletedMissions: [Mission] = []   // missions terminées durant la partie (écran de fin)
    weak var bridge: GameBridge?

    /// Fait progresser une mission et collecte celles terminées pour l'écran de fin de partie.
    private func progress(_ kind: MissionKind, _ amount: Int) {
        let done = bridge?.model.addMissionProgress(kind, amount) ?? []
        runCompletedMissions.append(contentsOf: done)
    }

    func begin() { started = true; lastTime = 0; isPaused = false }

    private var tracks: [TrackView] = []
    private var holdCount: [Int] = []
    private var touchTrack: [ObjectIdentifier: Int] = [:]

    // Réanimation coop (PRD §4.4) : quand un joueur tombe en duo, l'autre a 8 s pour le sauver en
    // tapant 5 fois une pastille « SOS » sur SA moitié. Expiré = à terre ; les deux à terre = fin.
    private let rescueWindow: Double = 8
    private let maxSOS = 3                  // budget de SOS par partie (réinitialisé par un revive payant)
    private var sosUsed = 0
    private var rescuing: [Bool] = []      // piste en attente de sauvetage (fenêtre ouverte)
    private var expired: [Bool] = []       // fenêtre écoulée / budget épuisé → à terre définitif
    private var rescueLeft: [Double] = []  // secondes restantes de la fenêtre
    private var rescueTaps: [Int] = []     // taps SOS accumulés par le sauveteur
    private var rescueTarget: [Int] = []   // taps requis pour CE SOS (aléatoire 3–6)
    private var sosNodes: [SKNode?] = []   // pastille SOS affichée sur la moitié du sauveteur
    private var timeScale: CGFloat = 1     // ralenti pendant un sauvetage (1 = normal, <1 = slow-mo)
    private let dbgShot = ProcessInfo.processInfo.environment["DBG_SHOT"]   // TEMP-SHOT
    private var dbgFell = false                                             // TEMP-SHOT

    private var distanceLabel = SKLabelNode(fontNamed: "AvenirNext-Bold")
    private var coinLabel = SKLabelNode(fontNamed: "AvenirNext-Bold")
    private var comboLabel = SKLabelNode(fontNamed: "AvenirNext-Heavy")
    private let coinChip = SKShapeNode(rectOf: CGSize(width: 104, height: 32), cornerRadius: 16)
    private var builtSize: CGSize = .zero

    override func didMove(to view: SKView) {
        anchorPoint = .zero
        backgroundColor = UIColor(hex: 0xF2D8A7)
        layoutIfNeeded()
    }

    /// `resizeFill` fixe la vraie taille de la vue APRÈS la création de la scène (et à chaque rotation
    /// / changement d'appareil). On (re)construit la disposition dès qu'on connaît la taille réelle,
    /// sinon la 2ᵉ piste du duo est positionnée hors écran (bug « on ne voit qu'un joueur »).
    override func didChangeSize(_ oldSize: CGSize) {
        super.didChangeSize(oldSize)
        layoutIfNeeded()
    }

    private func layoutIfNeeded() {
        guard size.width > 1, size.height > 1, size != builtSize else { return }
        builtSize = size
        buildAll()
    }

    private func buildAll() {
        removeAllChildren(); removeAllActions()
        tuning = (mode == .duo) ? tuningDuo : tuningSolo
        spawnAhead = size.width + 400
        distance = 0
        magnetTimer = 0; lastMeters = 0; totalCoins = 0; comboMult = 1; comboProgress = 0
        runCompletedMissions.removeAll(); dead = false; lastTime = 0
        timeScale = 1; self.speed = 1
        touchTrack.removeAll()
        buildTracks()
        buildHUD()
        applyStartGadgets()
        applyRecordFlag()
    }

    /// Plante le drapeau du record perso (meilleure distance atteinte) sur chaque piste.
    private func applyRecordFlag() {
        let x = CGFloat(bridge?.model.bestDistanceM ?? 0) * 20
        for t in tracks { t.recordWorldX = x }
    }

    /// Applique les gadgets permanents au départ d'une partie (départ lancé, bouclier de départ).
    private func applyStartGadgets() {
        guard let model = bridge?.model else { return }
        if model.hasGadget("g_headstart") { distance = 400; lastMeters = Int(distance / 20) }
        if model.hasGadget("g_shield") { for t in tracks { t.runner.shield = true } }
    }

    private func buildTracks() {
        tracks.forEach { $0.removeFromParent() }
        tracks.removeAll(); sims.removeAll()
        let skin = bridge?.model.currentSkin() ?? HeroSkin.base
        // Chaque piste reçoit son propre seed → parcours ET décor différents des deux côtés.
        func makeTrack(_ trackSize: CGSize) -> TrackView {
            let seed = UInt64.random(in: 0 ... .max)
            sims.append(WorldSim(seed: seed))
            return TrackView(size: trackSize, tuning: tuning, biome: biome, skin: skin, seed: seed)
        }
        switch mode {
        case .solo:
            let t = makeTrack(size); t.position = .zero
            addChild(t); tracks = [t]
        case .duo:
            let half = CGSize(width: size.width, height: size.height / 2)
            let a = makeTrack(half); a.position = .zero                      // bas : joueur A
            addChild(a)
            let b = makeTrack(half); b.zRotation = .pi                       // haut : tête-bêche
            b.position = CGPoint(x: size.width, y: size.height)             // mappe son (0,0) en (W,H)
            addChild(b)
            tracks = [a, b]
        }
        collectedCoins = Array(repeating: Set<Int>(), count: tracks.count)
        collectedPowerups = Array(repeating: Set<Int>(), count: tracks.count)
        holdCount = Array(repeating: 0, count: tracks.count)
        resetRescueState()
    }

    private func resetRescueState() {
        for n in sosNodes { n?.removeFromParent() }
        rescuing = Array(repeating: false, count: tracks.count)
        expired = Array(repeating: false, count: tracks.count)
        rescueLeft = Array(repeating: 0, count: tracks.count)
        rescueTaps = Array(repeating: 0, count: tracks.count)
        rescueTarget = Array(repeating: 0, count: tracks.count)
        sosNodes = Array(repeating: nil, count: tracks.count)
        sosUsed = 0
    }

    private func buildHUD() {
        distanceLabel.fontColor = Pal.ink
        distanceLabel.zPosition = 100
        // Compteur de pièces : pastille sombre + texte doré vif → lisible sur tous les biomes.
        coinLabel.fontColor = UIColor(hex: 0xF7CE55)
        coinLabel.horizontalAlignmentMode = .center; coinLabel.verticalAlignmentMode = .center
        coinLabel.zPosition = 100
        coinChip.fillColor = UIColor(hex: 0x1E1A26).withAlphaComponent(0.55); coinChip.strokeColor = .clear
        coinChip.zPosition = 99
        comboLabel.fontColor = UIColor(hex: 0xFF9F43); comboLabel.zPosition = 100
        comboLabel.horizontalAlignmentMode = .center; comboLabel.verticalAlignmentMode = .center
        comboLabel.text = ""

        if mode == .duo {
            let band = SKShapeNode(rect: CGRect(x: 0, y: size.height / 2 - 15, width: size.width, height: 30))
            band.fillColor = Pal.ink.withAlphaComponent(0.16); band.strokeColor = .clear; band.zPosition = 90
            addChild(band)
            distanceLabel.fontSize = 20
            distanceLabel.horizontalAlignmentMode = .center; distanceLabel.verticalAlignmentMode = .center
            distanceLabel.position = CGPoint(x: size.width / 2, y: size.height / 2)
            coinLabel.fontSize = 17
            coinChip.position = CGPoint(x: 76, y: size.height / 2)
            coinLabel.position = coinChip.position
            comboLabel.fontSize = 22
            comboLabel.position = CGPoint(x: size.width - 60, y: size.height / 2)
        } else {
            distanceLabel.fontSize = 26
            distanceLabel.horizontalAlignmentMode = .center; distanceLabel.verticalAlignmentMode = .top
            distanceLabel.position = CGPoint(x: size.width / 2, y: size.height - 16)
            coinLabel.fontSize = 20
            coinChip.position = CGPoint(x: 84, y: size.height - 30)
            coinLabel.position = coinChip.position
            comboLabel.fontSize = 26
            comboLabel.position = CGPoint(x: size.width - 60, y: size.height - 30)
        }
        addChild(coinChip); addChild(distanceLabel); addChild(coinLabel); addChild(comboLabel)
    }

    // MARK: Entrées (routage par zone : bas = piste 0, haut = piste 1)

    private func zone(for t: UITouch) -> Int {
        guard mode == .duo else { return 0 }
        return t.location(in: self).y < size.height / 2 ? 0 : 1
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard !dead, started else { return }
        for t in touches {
            if handleSOSTouch(t) { continue }   // tap sur une pastille SOS = sauvetage, pas un saut
            let z = zone(for: t)
            touchTrack[ObjectIdentifier(t)] = z
            if tracks[z].onJump() { progress(.jumps, 1) }
            tracks[z].setHolding(true)
            holdCount[z] += 1
        }
    }
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard !dead, started else { return }
        for t in touches {
            guard let z = touchTrack[ObjectIdentifier(t)] else { continue }   // ignore les touches SOS
            let dy = t.location(in: self).y - t.previousLocation(in: self).y
            // piste du bas : glisse = swipe vers le bas ; piste du haut (tête-bêche) : swipe vers le haut
            if (z == 0 && dy < -8) || (z == 1 && dy > 8) {
                if tracks[z].onSlide() { progress(.slides, 1) }
            }
        }
    }
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) { endTouches(touches) }
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) { endTouches(touches) }
    private func endTouches(_ touches: Set<UITouch>) {
        for t in touches {
            let key = ObjectIdentifier(t)
            guard let z = touchTrack[key] else { continue }   // touche SOS ou non suivie : rien à relâcher
            touchTrack[key] = nil
            holdCount[z] = max(0, holdCount[z] - 1)
            if holdCount[z] == 0 { tracks[z].setHolding(false) }
        }
    }

    /// Si le tap tombe sur une pastille SOS active, l'enregistre comme tap de sauvetage et renvoie true.
    private func handleSOSTouch(_ t: UITouch) -> Bool {
        let p = t.location(in: self)
        for i in tracks.indices {
            guard rescuing[i], let sos = sosNodes[i] else { continue }
            if hypot(p.x - sos.position.x, p.y - sos.position.y) < 62 {
                registerRescueTap(i); return true
            }
        }
        return false
    }

    // MARK: Boucle

    override func update(_ currentTime: TimeInterval) {
        if lastTime == 0 { lastTime = currentTime }
        var dt = currentTime - lastTime
        lastTime = currentTime
        if dt > 1.0 / 30 { dt = 1.0 / 30 }
        if dead || !started { return }

        // Ralenti « sauvetage » : tant qu'un joueur attend d'être secouru, le monde ralentit pour
        // laisser à l'autre le temps de réagir (tap SOS + esquive), puis revient à la normale.
        let slowActive = (mode == .duo) && rescuing.contains(true)
        let targetScale: CGFloat = slowActive ? 0.35 : 1
        timeScale += (targetScale - timeScale) * min(1, CGFloat(dt) * 6)
        self.speed = timeScale                      // ralentit aussi les animations SpriteKit (bulle, course…)
        let gdt = dt * Double(timeScale)             // temps de JEU ralenti
        let d = CGFloat(gdt)

        let speed = min(tuning.maxSpeed, tuning.baseSpeed + distance * 0.005)   // accélération plus marquée
        distance += speed * d
        if magnetTimer > 0 { magnetTimer -= gdt }
        let m = Int(distance / 20)
        if m > lastMeters { progress(.meters, m - lastMeters); lastMeters = m }

        for s in sims { s.ensureGenerated(upTo: distance + spawnAhead); s.cull(before: distance - trailMargin) }

        for (i, t) in tracks.enumerated() { t.step(dt: gdt, distance: distance, sim: sims[i]) }
        for i in tracks.indices { checkCollisions(i) }
        for i in tracks.indices { checkPowerups(i) }
        for (i, t) in tracks.enumerated() {
            t.render(distance: distance, sim: sims[i], collected: collectedCoins[i], collectedPowerups: collectedPowerups[i],
                     speed: speed, dt: d, spawnAhead: spawnAhead)
        }

        if dbgShot == "duosos" && mode == .duo && !dbgFell && distance > 320 && tracks.count > 1 {   // TEMP-SHOT
            dbgFell = true; tracks[0].forceFall()
        }

        // Solo : une chute = fin (second souffle payant via l'UI). Duo : sauvetage coop temps réel.
        if mode == .solo {
            if tracks.contains(where: { $0.isDown }) { enterDead() }
        } else {
            updateDuoRescue(dt: dt)
        }

        bridge?.model.addPlaytime(dt)
        distanceLabel.text = "\(Int(distance / 20)) m"
        coinLabel.text = "◉ \(totalCoins)"
        comboLabel.text = comboMult > 1 ? "x\(comboMult)" : ""
    }

    // MARK: Combo coop (multiplicateur partagé)

    private func gainCoins() {
        let gain = comboMult
        totalCoins += gain
        bridge?.model.addCoins(gain)
        SoundManager.shared.play(.coin, volume: 0.55)
        progress(.coins, 1)
        comboProgress += 1
        if comboMult < 5 && comboProgress >= 12 { comboMult += 1; comboProgress = 0; pulseCombo() }
    }
    private func breakCombo() {
        if comboMult > 1 { comboMult = 1; comboProgress = 0 }
    }
    private func pulseCombo() {
        comboLabel.removeAllActions()
        comboLabel.setScale(1)
        comboLabel.run(.sequence([.scale(to: 1.4, duration: 0.12), .scale(to: 1, duration: 0.12)]))
    }

    private func checkCollisions(_ i: Int) {
        let track = tracks[i]
        guard !track.isDown else { return }
        let s = sims[i]
        let r = track.runner
        let gY = track.groundTopY
        let rx: CGFloat = magnetTimer > 0 ? 130 : 26    // l'aimant élargit le rayon de ramassage
        let ry: CGFloat = magnetTimer > 0 ? 150 : 40
        for c in s.coins where !collectedCoins[i].contains(c.id) {
            if abs(c.x - distance) < rx && abs((gY + c.y) - (r.y + 34)) < ry {
                collectedCoins[i].insert(c.id)
                gainCoins()                    // pièces × multiplicateur coop
                track.popCoin(id: c.id)
            }
        }
        guard r.invi <= 0 else { return }   // invincible (réanimation / fusée)
        let heroTop = r.y + (r.sliding && r.grounded ? 30 : 62)
        for o in s.obstacles where abs(o.x - distance) < 43 {
            let (lo, hi): (CGFloat, CGFloat)
            switch o.kind {
            case .cactus: (lo, hi) = (gY, gY + 74)
            case .barrel: (lo, hi) = (gY, gY + 60)
            case .beam:   (lo, hi) = (gY + 42, gY + 62)
            }
            if r.y < hi && heroTop > lo {
                breakCombo()                  // un choc casse le combo partagé
                if r.shield { r.shield = false; r.invi = 1.0 }   // le bouclier encaisse le choc
                else { track.forceFall() }
                return
            }
        }
    }

    /// Ramassage de power-ups : le bénéfice est PARTAGÉ par les deux joueurs (PRD §4.5).
    private func checkPowerups(_ i: Int) {
        let track = tracks[i]
        guard !track.isDown else { return }
        let r = track.runner
        for p in sims[i].powerups where !collectedPowerups[i].contains(p.id) {
            if abs(p.x - distance) < 30 && abs((track.groundTopY + p.y) - (r.y + 34)) < 46 {
                collectedPowerups[i].insert(p.id)
                track.popPowerup(id: p.id)
                activatePowerup(p.kind)
            }
        }
    }

    private func activatePowerup(_ kind: PowerupKind) {
        SoundManager.shared.play(.powerup)
        switch kind {
        case .magnet: magnetTimer = bridge?.model.magnetDuration ?? 8
        case .shield: for t in tracks where !t.isDown { t.runner.shield = true }
        case .rocket:
            for t in tracks where !t.isDown {
                t.runner.flyTimer = 5
                t.runner.flyTarget = t.groundTopY + t.size.height * 0.45
                t.runner.invi = 5
            }
        }
    }

    // MARK: Réanimation coop (SOS temps réel, PRD §4.4)

    private func updateDuoRescue(dt: Double) {
        // Les DEUX à terre = personne pour sauver = fin de partie (revive payant via l'UI).
        if tracks.allSatisfy({ $0.isDown }) { enterDead(); return }
        for i in tracks.indices {
            let j = tracks.count - 1 - i   // en duo, l'autre piste (le sauveteur)
            if tracks[i].isDown {
                if !rescuing[i] && !expired[i] {
                    if sosUsed < maxSOS {                    // budget de SOS restant pour la partie
                        sosUsed += 1
                        rescuing[i] = true; rescueLeft[i] = rescueWindow; rescueTaps[i] = 0
                        rescueTarget[i] = Int.random(in: 3...6)
                        showSOS(downed: i, rescuer: j)
                    } else {
                        expired[i] = true                   // plus de SOS dispo → à terre (revive payant réinit)
                    }
                } else if rescuing[i] {
                    rescueLeft[i] -= dt
                    if rescueLeft[i] <= 0 { rescuing[i] = false; expired[i] = true; hideSOS(i) }
                }
            } else {
                if rescuing[i] { rescuing[i] = false; hideSOS(i) }
                expired[i] = false
            }
        }
    }

    private func registerRescueTap(_ i: Int) {
        guard rescuing[i] else { return }
        rescueTaps[i] += 1
        haptic(.light)
        SoundManager.shared.play(.tap, volume: 0.7)
        if let sos = sosNodes[i] { fillPips(sos, count: rescueTaps[i], of: rescueTarget[i]); bounce(sos) }
        if rescueTaps[i] >= rescueTarget[i] { performRescue(i) }
    }

    /// Sauvetage réussi : le coureur revient avec 2 s d'invincibilité (le moment star, PRD §9).
    private func performRescue(_ i: Int) {
        rescuing[i] = false
        hideSOS(i)
        tracks[i].revive()
        progress(.saves, 1)
        haptic(.heavy)
        SoundManager.shared.play(.rescue)
        flashTrack(i)
    }

    private func showSOS(downed i: Int, rescuer j: Int) {
        hideSOS(i)
        let node = makeSOSNode(target: rescueTarget[i])
        // Position ALÉATOIRE sur la moitié du sauveteur → l'oblige à repérer la pastille à chaque chute.
        let x = size.width * CGFloat.random(in: 0.22...0.78)
        if j == 0 {   // moitié basse, à l'endroit
            node.position = CGPoint(x: x, y: size.height * CGFloat.random(in: 0.07...0.40))
        } else {      // moitié haute (tête-bêche) : pastille pivotée pour être lisible
            node.position = CGPoint(x: x, y: size.height * CGFloat.random(in: 0.60...0.93))
            node.zRotation = .pi
        }
        node.zPosition = 150
        addChild(node); sosNodes[i] = node
    }
    private func hideSOS(_ i: Int) { sosNodes[i]?.removeFromParent(); sosNodes[i] = nil }

    private func makeSOSNode(target: Int) -> SKNode {
        let node = SKNode()
        let bg = SKShapeNode(rectOf: CGSize(width: 120, height: 80), cornerRadius: 18)
        bg.fillColor = UIColor(hex: 0xE23B4E); bg.strokeColor = .white; bg.lineWidth = 3
        node.addChild(bg)
        let title = SKLabelNode(fontNamed: "AvenirNext-Heavy")
        title.text = "SOS"; title.fontSize = 30; title.fontColor = .white
        title.verticalAlignmentMode = .center; title.position = CGPoint(x: 0, y: 13)
        node.addChild(title)
        let hint = SKLabelNode(fontNamed: "AvenirNext-Bold")
        hint.text = "tape ×\(target)"; hint.fontSize = 12; hint.fontColor = .white
        hint.verticalAlignmentMode = .center; hint.position = CGPoint(x: 0, y: -27)
        node.addChild(hint)
        let spacing: CGFloat = 16
        let start = -CGFloat(target - 1) / 2 * spacing
        for k in 0..<target {
            let pip = SKShapeNode(circleOfRadius: 5)
            pip.strokeColor = .white; pip.lineWidth = 1.5; pip.fillColor = .clear
            pip.position = CGPoint(x: start + CGFloat(k) * spacing, y: -7); pip.name = "pip\(k)"
            node.addChild(pip)
        }
        node.run(.repeatForever(.sequence([.scale(to: 1.08, duration: 0.4), .scale(to: 1.0, duration: 0.4)])))
        return node
    }
    private func fillPips(_ sos: SKNode, count: Int, of target: Int) {
        for k in 0..<target {
            (sos.childNode(withName: "pip\(k)") as? SKShapeNode)?.fillColor = k < count ? .white : .clear
        }
    }
    private func bounce(_ n: SKNode) {
        n.removeAllActions()
        n.run(.sequence([.scale(to: 1.25, duration: 0.06), .scale(to: 1.0, duration: 0.08),
                         .repeatForever(.sequence([.scale(to: 1.08, duration: 0.4), .scale(to: 1.0, duration: 0.4)]))]))
    }
    /// Flash doux sur la moitié de la piste sauvée.
    private func flashTrack(_ i: Int) {
        let rect: CGRect = (mode == .duo)
            ? CGRect(x: 0, y: i == 0 ? 0 : size.height / 2, width: size.width, height: size.height / 2)
            : CGRect(origin: .zero, size: size)
        let flash = SKShapeNode(rect: rect)
        flash.fillColor = .white; flash.strokeColor = .clear; flash.alpha = 0; flash.zPosition = 200
        addChild(flash)
        flash.run(.sequence([.fadeAlpha(to: 0.5, duration: 0.08), .fadeOut(withDuration: 0.35), .removeFromParent()]))
    }
    private func haptic(_ style: UIImpactFeedbackGenerator.FeedbackStyle) {
        UIImpactFeedbackGenerator(style: style).impactOccurred()
    }

    // MARK: Mort / relance / réanimation (pilotées par l'UI via le pont)

    private func enterDead() {
        guard !dead else { return }
        dead = true
        SoundManager.shared.play(.death)
        isPaused = true            // gèle le décor derrière le panneau de mort (plus de défilement)
        let meters = Int(distance / 20)
        progress(.runs, 1)
        GameCenter.shared.submit(distanceM: meters)
        let isRecord = bridge?.model.recordDistance(meters) ?? false
        let best = bridge?.model.bestDistanceM ?? meters
        bridge?.reportDeath(distanceM: meters, runCoins: totalCoins,
                            bestM: best, isRecord: isRecord, completedMissions: runCompletedMissions)
    }

    /// Recommencer depuis le début (nouveau monde).
    func doRestart() {
        distance = 0; lastMeters = 0
        magnetTimer = 0; totalCoins = 0; comboMult = 1; comboProgress = 0; runCompletedMissions.removeAll()
        sims = sims.map { _ in WorldSim(seed: UInt64.random(in: 0 ... .max)) }   // nouveaux parcours, toujours distincts
        collectedCoins = Array(repeating: Set<Int>(), count: tracks.count)
        collectedPowerups = Array(repeating: Set<Int>(), count: tracks.count)
        for t in tracks { t.resetRun() }
        resetRescueState()
        applyStartGadgets()
        applyRecordFlag()
        lastTime = 0; dead = false; isPaused = false; timeScale = 1; self.speed = 1
    }

    /// Revivre : relève le(s) coureur(s) à terre et continue la même partie.
    func doRevive() {
        var saved = 0
        for t in tracks where t.isDown { t.revive(); saved += 1 }
        if saved > 0 { progress(.saves, saved) }
        resetRescueState()
        lastTime = 0; dead = false; isPaused = false
    }
}
