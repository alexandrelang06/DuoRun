import SpriteKit

/// Une piste de course : tout le rendu d'un coureur (ciel, mesas, nuages, sol, obstacles, pièces,
/// héros, ombre) dans un repère local (origine bas-gauche, taille `size`). La scène en place une
/// (solo, plein écran) ou deux (duo tête-bêche : la piste B est pivotée de 180°). Le monde
/// (`WorldSim`) et la distance sont partagés ; chaque piste a son propre `RunnerState`.
final class TrackView: SKNode {

    let size: CGSize
    let charX: CGFloat
    let groundTopY: CGFloat
    let tuning: Tuning
    let biome: Biome
    let runner: RunnerState

    private let hero: HeroNode
    private let heroShadow: SKShapeNode
    private let cloudsLayer = SKNode()
    private var clouds: [SKNode] = []
    private var farBands: [SKNode] = []
    private var midBands: [SKNode] = []

    private var segNodes: [Int: SKNode] = [:]
    private var obNodes: [Int: SKNode] = [:]
    private var coinNodes: [Int: SKNode] = [:]
    private var pwrNodes: [Int: SKNode] = [:]
    private let shieldRing = SKShapeNode(circleOfRadius: 34)
    private var bubble: SKShapeNode?
    private var wasSliding = false

    /// Position « monde » (points) du record perso à marquer d'un drapeau ; 0 = aucun record.
    var recordWorldX: CGFloat = 0
    private var recordFlagNode: SKNode?

    init(size: CGSize, tuning: Tuning, biome: Biome, skin: HeroSkin, seed: UInt64) {
        self.size = size
        self.tuning = tuning
        self.biome = biome
        self.charX = size.width * 0.28
        self.groundTopY = size.height * 0.24          // plus de ciel au-dessus pour le saut en demi-hauteur
        self.runner = RunnerState(groundTopY: groundTopY)
        self.heroShadow = Western.shadow(width: 46)
        self.hero = HeroNode(skin: skin)
        super.init()
        buildBackground(seed: seed)
        buildDecor(seed: seed)
        buildHero()
    }
    required init?(coder: NSCoder) { fatalError() }

    // MARK: Construction

    /// Fond procédural du biome : ciel multi-stops + astre, puis deux couches de silhouettes en
    /// parallaxe (mesa / hill / tree / building / peak / crystal selon le biome).
    private func buildBackground(seed: UInt64) {
        let sky = Western.skyNode(size: size, biome: biome); sky.zPosition = -100; addChild(sky)
        for i in 0..<2 {
            let b = Western.band(width: size.width, style: biome.farStyle, color: biome.farColor, accent: biome.accent,
                                 baseY: groundTopY - 4, minH: size.height * 0.14, maxH: size.height * 0.30, count: 4, seed: seed &+ 11)
            b.position = CGPoint(x: CGFloat(i) * size.width, y: 0); b.zPosition = -60; b.alpha = 0.85
            addChild(b); farBands.append(b)
        }
        for i in 0..<2 {
            let b = Western.band(width: size.width, style: biome.nearStyle, color: biome.nearColor, accent: biome.accent,
                                 baseY: groundTopY - 2, minH: size.height * 0.08, maxH: size.height * 0.18, count: 5, seed: seed &+ 29)
            b.position = CGPoint(x: CGFloat(i) * size.width, y: 0); b.zPosition = -40; b.alpha = 0.94
            addChild(b); midBands.append(b)
        }
    }

    private func buildDecor(seed: UInt64) {
        switch biome.decor {
        case .clouds:
            cloudsLayer.zPosition = -70; addChild(cloudsLayer)
            for i in 0..<3 {
                let c = Western.cloud()
                c.position = CGPoint(x: CGFloat(i) * size.width / 2 + 60, y: size.height * (0.72 + 0.08 * CGFloat(i % 2)))
                c.setScale(0.6 + 0.4 * CGFloat(i % 2))
                cloudsLayer.addChild(c); clouds.append(c)
            }
        case .stars:
            let s = Western.starfield(size: size, count: 70); s.zPosition = -90; addChild(s)
        case .snow:
            let sn = Western.snowLayer(size: size, count: 44); sn.zPosition = 6; addChild(sn)
        }
    }

    private func buildHero() {
        heroShadow.zPosition = 1
        heroShadow.position = CGPoint(x: charX, y: groundTopY + 2)
        addChild(heroShadow)
        hero.position = CGPoint(x: charX, y: groundTopY)
        hero.zPosition = 10
        addChild(hero)
        shieldRing.strokeColor = UIColor(hex: 0x5FBFE0); shieldRing.lineWidth = 4
        shieldRing.fillColor = UIColor(hex: 0x5FBFE0).withAlphaComponent(0.12)
        shieldRing.zPosition = 11; shieldRing.isHidden = true; addChild(shieldRing)
    }

    // MARK: Entrées → coureur + animations

    @discardableResult func onJump() -> Bool {
        let wasGrounded = runner.grounded
        let canJump = !runner.down && (runner.grounded || runner.canDouble)
        runner.jump(tuning)
        if canJump { hero.jumpPose(); SoundManager.shared.play(wasGrounded ? .jump : .djump) }
        return canJump
    }
    @discardableResult func onSlide() -> Bool {
        let can = !runner.down
        let fresh = !runner.sliding
        if runner.grounded && !runner.down { hero.setSliding(true) }
        runner.beginSlide(tuning)
        if can && fresh { SoundManager.shared.play(.slide, volume: 0.8) }
        return can
    }
    func setHolding(_ b: Bool) { runner.isHolding = b }

    /// Avance la physique du coureur et déclenche les transitions d'animation. Renvoie true si ce
    /// coureur vient de tomber (pour la logique coop de la scène).
    @discardableResult func step(dt: Double, distance: CGFloat, sim: WorldSim) -> Bool {
        let e = runner.step(dt: dt, distance: distance, sim: sim, t: tuning)
        if wasSliding && !runner.sliding { hero.setSliding(false) }
        wasSliding = runner.sliding
        switch e {
        case .landed: if !runner.sliding { hero.land() }; SoundManager.shared.play(.land, volume: 0.55)
        case .fell: showBubble()
        case .none: break
        }
        return e == .fell
    }

    // MARK: Rendu du monde (spawn/recyclage par id) + héros

    func render(distance: CGFloat, sim: WorldSim, collected: Set<Int>, collectedPowerups: Set<Int>,
                speed: CGFloat, dt: CGFloat, spawnAhead: CGFloat) {
        var liveSeg = Set<Int>(), liveOb = Set<Int>(), liveCoin = Set<Int>(), livePwr = Set<Int>()
        for s in sim.segments {
            liveSeg.insert(s.id)
            let n = segNodes[s.id] ?? makeSeg(s)
            n.position.x = charX + s.startX - distance
        }
        for o in sim.obstacles {
            liveOb.insert(o.id)
            let n = obNodes[o.id] ?? makeOb(o)
            n.position.x = charX + o.x - distance
        }
        for c in sim.coins where !collected.contains(c.id) {
            liveCoin.insert(c.id)
            let n = coinNodes[c.id] ?? makeCoin(c)
            n.position.x = charX + c.x - distance
        }
        for p in sim.powerups where !collectedPowerups.contains(p.id) {
            livePwr.insert(p.id)
            let n = pwrNodes[p.id] ?? makePwr(p)
            n.position.x = charX + p.x - distance
        }
        // Drapeau du record perso : planté à la meilleure distance atteinte (défile avec le monde).
        if recordWorldX > 0 {
            let f = recordFlagNode ?? makeRecordFlag()
            f.position.x = charX + recordWorldX - distance
        }

        for (id, n) in segNodes where !liveSeg.contains(id) { n.removeFromParent(); segNodes[id] = nil }
        for (id, n) in obNodes where !liveOb.contains(id) { n.removeFromParent(); obNodes[id] = nil }
        for (id, n) in coinNodes where !liveCoin.contains(id) { n.removeFromParent(); coinNodes[id] = nil }
        for (id, n) in pwrNodes where !livePwr.contains(id) { n.removeFromParent(); pwrNodes[id] = nil }

        // héros : en course il suit sa hauteur ; à terre il flotte DANS la bulle (qui dérive).
        if runner.down, let b = bubble {
            hero.position = b.position
            hero.yScale = 1; hero.xScale = 1
        } else {
            hero.position = CGPoint(x: charX, y: runner.y - 3)
            let squashed = runner.sliding && runner.grounded
            hero.yScale = squashed ? 0.5 : 1
            hero.xScale = squashed ? 1.15 : 1
        }
        shieldRing.position = CGPoint(x: charX, y: runner.y + 30)
        shieldRing.isHidden = !runner.shield || runner.down

        // parallaxe / nuages / ombre
        func scroll(_ bands: [SKNode], f: CGFloat) {
            for b in bands { b.position.x -= speed * f * dt; if b.position.x <= -size.width { b.position.x += size.width * 2 } }
        }
        scroll(farBands, f: 0.18); scroll(midBands, f: 0.42)
        for c in clouds { c.position.x -= speed * 0.10 * dt; if c.position.x < -110 { c.position.x = size.width + 110 } }
        let sf = max(0.4, 1 - max(0, runner.y - groundTopY) / 180)
        heroShadow.setScale(sf); heroShadow.alpha = 0.30 * sf; heroShadow.isHidden = runner.down
    }

    @discardableResult private func makeSeg(_ s: GroundSegment) -> SKNode {
        let n = Western.groundSegment(w: s.endX - s.startX, depth: groundTopY + 40,
                                      top: biome.groundTop, edgeTop: biome.groundEdgeTop,
                                      body: biome.groundBody, edge: biome.groundEdge)
        n.position = CGPoint(x: 0, y: groundTopY); n.zPosition = 0
        addChild(n); segNodes[s.id] = n; return n
    }
    @discardableResult private func makeOb(_ o: Obstacle) -> SKNode {
        let n: SKNode
        switch o.kind {
        case .cactus: n = Western.cactus(color: biome.obstacle)
        case .barrel: n = Western.barrel(color: biome.obstacle)
        case .beam:   n = Western.beam(color: biome.obstacle)
        }
        let sh = Western.shadow(width: o.kind == .barrel ? 60 : 44)
        sh.position = CGPoint(x: 0, y: 2); sh.zPosition = -1; n.addChild(sh)
        n.position = CGPoint(x: 0, y: groundTopY - 2); n.zPosition = 2
        addChild(n); obNodes[o.id] = n; return n
    }
    @discardableResult private func makeRecordFlag() -> SKNode {
        let n = Western.recordFlag(accent: biome.accent)
        n.position = CGPoint(x: 0, y: groundTopY - 2); n.zPosition = 2
        addChild(n); recordFlagNode = n; return n
    }
    @discardableResult private func makeCoin(_ c: Coin) -> SKNode {
        let n = Western.coin()
        n.position = CGPoint(x: 0, y: groundTopY + c.y); n.zPosition = 3
        addChild(n); coinNodes[c.id] = n; return n
    }
    @discardableResult private func makePwr(_ p: Powerup) -> SKNode {
        let n = Western.powerup(p.kind)
        n.position = CGPoint(x: 0, y: groundTopY + p.y); n.zPosition = 4
        addChild(n); pwrNodes[p.id] = n; return n
    }
    func popPowerup(id: Int) {
        guard let n = pwrNodes[id] else { return }
        pwrNodes[id] = nil
        n.run(.sequence([.group([.scale(to: 1.8, duration: 0.15), .fadeOut(withDuration: 0.15)]), .removeFromParent()]))
    }

    func popCoin(id: Int) {
        guard let n = coinNodes[id] else { return }
        coinNodes[id] = nil
        n.run(.sequence([.group([.scale(to: 1.6, duration: 0.12), .fadeOut(withDuration: 0.12)]), .removeFromParent()]))
    }

    // MARK: Bulle (chute) / relance

    private func showBubble() {
        let b = SKShapeNode(circleOfRadius: 40)
        b.fillColor = UIColor.white.withAlphaComponent(0.35)
        b.strokeColor = UIColor.white.withAlphaComponent(0.85); b.lineWidth = 3
        // Flotte à une hauteur visible (le coureur a pu tomber loin sous le sol) et dérive lentement
        // vers la gauche pendant la fenêtre de sauvetage de 8 s (PRD §4.4).
        b.position = CGPoint(x: charX, y: groundTopY + 70); b.zPosition = 20
        addChild(b); bubble = b
        b.run(.moveBy(x: -150, y: 0, duration: 8))
        hero.run(.fadeAlpha(to: 0.6, duration: 0.2))
    }

    func clearWorldNodes() {
        for n in segNodes.values { n.removeFromParent() }
        for n in obNodes.values { n.removeFromParent() }
        for n in coinNodes.values { n.removeFromParent() }
        for n in pwrNodes.values { n.removeFromParent() }
        segNodes.removeAll(); obNodes.removeAll(); coinNodes.removeAll(); pwrNodes.removeAll()
        recordFlagNode?.removeFromParent(); recordFlagNode = nil
        shieldRing.isHidden = true
    }

    func reviveVisual() {
        bubble?.removeFromParent(); bubble = nil
        hero.run(.fadeAlpha(to: 1, duration: 0.15)); hero.land()
    }

    /// Chute déclenchée par une collision (obstacle).
    func forceFall() { if !runner.down { runner.down = true; showBubble() } }
    var isDown: Bool { runner.down }

    /// Réanimation : le coureur repart là où il est tombé, avec invincibilité brève.
    func revive() { runner.revive(); wasSliding = false; reviveVisual() }

    func resetRun() {
        runner.reset(); wasSliding = false
        clearWorldNodes(); reviveVisual()
    }
}
