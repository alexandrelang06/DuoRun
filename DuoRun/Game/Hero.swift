import SpriteKit

/// Apparence du coureur, pilotée par la boutique de cosmétiques. Soit un humain (tenue + chapeau
/// personnalisables), soit un skin complet (dragon, robot…).
struct HeroSkin {
    enum Body { case human(shirt: UIColor, pants: UIColor, skin: UIColor), dragon, robot, ghost, cat }
    enum Hat { case none, cowboy, cap(UIColor), crown, band(UIColor), beanie(UIColor) }
    var body: Body
    var hat: Hat

    static let base = HeroSkin(body: .human(shirt: Pal.heroShirt, pants: Pal.heroPants, skin: Pal.heroSkin),
                               hat: .cowboy)
}

/// Le coureur toon. Pieds à l'origine locale (y = 0). Les jambes pivotent à la hanche pour la course ;
/// en saut elles se replient. L'apparence vient d'un `HeroSkin`.
final class HeroNode: SKNode {

    private let legL = SKNode()
    private let legR = SKNode()
    private let bodyGroup = SKNode()
    private enum Pose { case run, air, slide }
    private var pose: Pose = .run

    init(skin: HeroSkin) {
        super.init()
        build(skin)
        pose = .run
        animateRun()
    }
    required init?(coder: NSCoder) { fatalError() }

    private func leg(_ color: UIColor) -> SKShapeNode {
        let bar = SKShapeNode(rectOf: CGSize(width: 11, height: 16), cornerRadius: 5)
        bar.fillColor = color; bar.strokeColor = Pal.ink; bar.lineWidth = Western.outline
        bar.position = CGPoint(x: 0, y: -8)
        return bar
    }

    private func build(_ skin: HeroSkin) {
        let legColor: UIColor
        switch skin.body {
        case .human(_, let pants, _): legColor = pants
        case .dragon: legColor = UIColor(hex: 0x3E8E4E)
        case .robot:  legColor = UIColor(hex: 0x8A94A0)
        case .ghost:  legColor = UIColor(hex: 0xD8DEF2)
        case .cat:    legColor = UIColor(hex: 0xE8934E)
        }
        legL.position = CGPoint(x: -8, y: 16); addChild(legL); legL.addChild(leg(legColor))
        legR.position = CGPoint(x: 8, y: 16); addChild(legR); legR.addChild(leg(legColor))

        switch skin.body {
        case .human(let shirt, _, let sk): buildHuman(shirt: shirt, skin: sk)
        case .dragon: buildDragon()
        case .robot:  buildRobot()
        case .ghost:  buildGhost()
        case .cat:    buildCat()
        }
        addHat(skin.hat)
        addChild(bodyGroup)
    }

    private func shape(_ node: SKShapeNode, _ fill: UIColor, line: CGFloat = Western.outline) -> SKShapeNode {
        node.fillColor = fill; node.strokeColor = Pal.ink; node.lineWidth = line; return node
    }

    private func buildHuman(shirt: UIColor, skin: UIColor) {
        let body = shape(SKShapeNode(rectOf: CGSize(width: 30, height: 26), cornerRadius: 10), shirt)
        body.position = CGPoint(x: 0, y: 26); bodyGroup.addChild(body)
        let arm = shape(SKShapeNode(rectOf: CGSize(width: 10, height: 18), cornerRadius: 5), shirt.lighter(0.05), line: 3)
        arm.position = CGPoint(x: 12, y: 24); arm.name = "arm"; bodyGroup.addChild(arm)
        let head = shape(SKShapeNode(circleOfRadius: 21), skin)
        head.position = CGPoint(x: 2, y: 56); bodyGroup.addChild(head)
        for dx in [-4, 8] {
            let eye = SKShapeNode(circleOfRadius: 3); eye.fillColor = Pal.ink; eye.strokeColor = .clear
            eye.position = CGPoint(x: CGFloat(dx) + 2, y: 58); bodyGroup.addChild(eye)
        }
    }

    private func buildDragon() {
        let g = UIColor(hex: 0x4EA85E), gd = UIColor(hex: 0x2E7A44), belly = UIColor(hex: 0xE8D89A)
        // aile derrière
        let wing = shape(SKShapeNode(path: {
            let p = CGMutablePath(); p.move(to: CGPoint(x: -6, y: 30))
            p.addQuadCurve(to: CGPoint(x: -34, y: 58), control: CGPoint(x: -34, y: 34))
            p.addQuadCurve(to: CGPoint(x: -8, y: 44), control: CGPoint(x: -18, y: 44)); p.closeSubpath(); return p
        }()), gd, line: 3); wing.zPosition = -1; bodyGroup.addChild(wing)
        let body = shape(SKShapeNode(rectOf: CGSize(width: 32, height: 30), cornerRadius: 13), g)
        body.position = CGPoint(x: 0, y: 26); bodyGroup.addChild(body)
        let bel = SKShapeNode(rectOf: CGSize(width: 16, height: 20), cornerRadius: 8); bel.fillColor = belly; bel.strokeColor = .clear
        bel.position = CGPoint(x: 0, y: 24); bodyGroup.addChild(bel)
        // queue (derrière le corps, côté arrière)
        let tail = shape(SKShapeNode(path: {
            let p = CGMutablePath(); p.move(to: CGPoint(x: -10, y: 16))
            p.addQuadCurve(to: CGPoint(x: -38, y: 12), control: CGPoint(x: -30, y: 28)); return p
        }()), .clear, line: 0); tail.strokeColor = g; tail.lineWidth = 10; tail.lineCap = .round
        tail.zPosition = -1; bodyGroup.addChild(tail)
        let head = shape(SKShapeNode(circleOfRadius: 20), g)
        head.position = CGPoint(x: 3, y: 56); bodyGroup.addChild(head)
        let snout = shape(SKShapeNode(rectOf: CGSize(width: 18, height: 12), cornerRadius: 5), g)
        snout.position = CGPoint(x: 16, y: 52); bodyGroup.addChild(snout)
        for dx in [-2, 12] {   // cornes
            let horn = shape(SKShapeNode(path: {
                let p = CGMutablePath(); p.move(to: CGPoint(x: CGFloat(dx), y: 70)); p.addLine(to: CGPoint(x: CGFloat(dx) - 4, y: 84)); p.addLine(to: CGPoint(x: CGFloat(dx) + 5, y: 72)); p.closeSubpath(); return p
            }()), belly, line: 2); bodyGroup.addChild(horn)
        }
        let eye = SKShapeNode(circleOfRadius: 3.5); eye.fillColor = Pal.ink; eye.strokeColor = .clear
        eye.position = CGPoint(x: 8, y: 60); bodyGroup.addChild(eye)
    }

    private func buildRobot() {
        let m = UIColor(hex: 0xAEB6C2), md = UIColor(hex: 0x7A8492), panel = UIColor(hex: 0x2E3440)
        let body = shape(SKShapeNode(rectOf: CGSize(width: 32, height: 28), cornerRadius: 7), m)
        body.position = CGPoint(x: 0, y: 26); bodyGroup.addChild(body)
        let pnl = SKShapeNode(rectOf: CGSize(width: 16, height: 12), cornerRadius: 3); pnl.fillColor = panel; pnl.strokeColor = .clear
        pnl.position = CGPoint(x: 0, y: 26); bodyGroup.addChild(pnl)
        let light = SKShapeNode(circleOfRadius: 3); light.fillColor = UIColor(hex: 0x5FE0C2); light.strokeColor = .clear
        light.position = CGPoint(x: 0, y: 26); bodyGroup.addChild(light)
        let head = shape(SKShapeNode(rectOf: CGSize(width: 30, height: 26), cornerRadius: 8), m)
        head.position = CGPoint(x: 2, y: 56); bodyGroup.addChild(head)
        for dx in [-6, 8] {
            let eye = SKShapeNode(rectOf: CGSize(width: 7, height: 8), cornerRadius: 2); eye.fillColor = UIColor(hex: 0x5FE0C2); eye.strokeColor = Pal.ink; eye.lineWidth = 2
            eye.position = CGPoint(x: CGFloat(dx) + 2, y: 57); bodyGroup.addChild(eye)
        }
        let ant = SKShapeNode(rectOf: CGSize(width: 3, height: 12)); ant.fillColor = md; ant.strokeColor = .clear
        ant.position = CGPoint(x: 2, y: 76); bodyGroup.addChild(ant)
        let ball = SKShapeNode(circleOfRadius: 4); ball.fillColor = UIColor(hex: 0xFF6B6B); ball.strokeColor = Pal.ink; ball.lineWidth = 2
        ball.position = CGPoint(x: 2, y: 84); bodyGroup.addChild(ball)
    }

    private func buildGhost() {
        let w = UIColor(hex: 0xF0F3FF), wd = UIColor(hex: 0xCED6F0)
        // corps en cloche
        let body = shape(SKShapeNode(rectOf: CGSize(width: 34, height: 40), cornerRadius: 16), w)
        body.position = CGPoint(x: 2, y: 40); bodyGroup.addChild(body)
        // festons du bas
        for dx in [-11, 0, 11] {
            let f = shape(SKShapeNode(circleOfRadius: 6), w, line: 0)
            f.position = CGPoint(x: CGFloat(dx) + 2, y: 22); bodyGroup.addChild(f)
        }
        let head = shape(SKShapeNode(circleOfRadius: 15), w)
        head.position = CGPoint(x: 2, y: 58); bodyGroup.addChild(head)
        for dx in [-5, 9] {
            let eye = SKShapeNode(ellipseOf: CGSize(width: 6, height: 9)); eye.fillColor = Pal.ink; eye.strokeColor = .clear
            eye.position = CGPoint(x: CGFloat(dx) + 2, y: 58); bodyGroup.addChild(eye)
        }
        let cheek = SKShapeNode(circleOfRadius: 3); cheek.fillColor = wd; cheek.strokeColor = .clear
        cheek.position = CGPoint(x: 14, y: 50); bodyGroup.addChild(cheek)
    }

    private func buildCat() {
        let o = UIColor(hex: 0xE8934E), od = UIColor(hex: 0xC26E2E), belly = UIColor(hex: 0xF6DCC0)
        let body = shape(SKShapeNode(rectOf: CGSize(width: 30, height: 28), cornerRadius: 12), o)
        body.position = CGPoint(x: 0, y: 26); bodyGroup.addChild(body)
        let bel = SKShapeNode(rectOf: CGSize(width: 14, height: 18), cornerRadius: 7); bel.fillColor = belly; bel.strokeColor = .clear
        bel.position = CGPoint(x: 0, y: 24); bodyGroup.addChild(bel)
        // queue
        let tail = shape(SKShapeNode(path: {
            let p = CGMutablePath(); p.move(to: CGPoint(x: -12, y: 18))
            p.addQuadCurve(to: CGPoint(x: -34, y: 30), control: CGPoint(x: -30, y: 8)); return p
        }()), .clear, line: 0); tail.strokeColor = o; tail.lineWidth = 9; tail.lineCap = .round
        tail.zPosition = -1; bodyGroup.addChild(tail)
        let head = shape(SKShapeNode(circleOfRadius: 19), o)
        head.position = CGPoint(x: 2, y: 56); bodyGroup.addChild(head)
        for dx in [-14, 14] {   // oreilles
            let ear = shape(SKShapeNode(path: {
                let p = CGMutablePath(); p.move(to: CGPoint(x: CGFloat(dx), y: 66)); p.addLine(to: CGPoint(x: CGFloat(dx) + (dx < 0 ? 2 : -2), y: 84)); p.addLine(to: CGPoint(x: CGFloat(dx) + (dx < 0 ? 12 : -12), y: 68)); p.closeSubpath(); return p
            }()), o, line: 3); ear.position = CGPoint(x: 2, y: 0); bodyGroup.addChild(ear)
        }
        for dx in [-6, 10] {
            let eye = SKShapeNode(ellipseOf: CGSize(width: 5, height: 8)); eye.fillColor = Pal.ink; eye.strokeColor = .clear
            eye.position = CGPoint(x: CGFloat(dx) + 2, y: 58); bodyGroup.addChild(eye)
        }
        let nose = SKShapeNode(circleOfRadius: 2.5); nose.fillColor = od; nose.strokeColor = .clear
        nose.position = CGPoint(x: 2, y: 50); bodyGroup.addChild(nose)
    }

    private func addHat(_ hat: HeroSkin.Hat) {
        switch hat {
        case .none: return
        case .cowboy:
            let brim = shape(SKShapeNode(ellipseOf: CGSize(width: 52, height: 16)), Pal.heroHat)
            brim.position = CGPoint(x: 2, y: 72); bodyGroup.addChild(brim)
            let crown = shape(SKShapeNode(rectOf: CGSize(width: 28, height: 18), cornerRadius: 8), Pal.heroHat)
            crown.position = CGPoint(x: 2, y: 80); bodyGroup.addChild(crown)
        case .cap(let c):
            let dome = shape(SKShapeNode(path: {
                let p = CGMutablePath(); p.addArc(center: CGPoint(x: 2, y: 70), radius: 18, startAngle: 0, endAngle: .pi, clockwise: false); p.closeSubpath(); return p
            }()), c)
            bodyGroup.addChild(dome)
            let peak = shape(SKShapeNode(rectOf: CGSize(width: 26, height: 7), cornerRadius: 3), c)
            peak.position = CGPoint(x: 16, y: 70); bodyGroup.addChild(peak)
        case .crown:
            let gold = UIColor(hex: 0xF4C430)
            let band = shape(SKShapeNode(rectOf: CGSize(width: 30, height: 8), cornerRadius: 2), gold)
            band.position = CGPoint(x: 2, y: 74); bodyGroup.addChild(band)
            for dx in [-10, 2, 14] {
                let sp = shape(SKShapeNode(path: {
                    let p = CGMutablePath(); p.move(to: CGPoint(x: CGFloat(dx), y: 76)); p.addLine(to: CGPoint(x: CGFloat(dx) + 5, y: 88)); p.addLine(to: CGPoint(x: CGFloat(dx) + 10, y: 76)); p.closeSubpath(); return p
                }()), gold, line: 2); bodyGroup.addChild(sp)
            }
        case .band(let c):
            let band = shape(SKShapeNode(rectOf: CGSize(width: 44, height: 8), cornerRadius: 3), c)
            band.position = CGPoint(x: 2, y: 70); bodyGroup.addChild(band)
        case .beanie(let c):
            let dome = shape(SKShapeNode(path: {
                let p = CGMutablePath(); p.addArc(center: CGPoint(x: 2, y: 68), radius: 19, startAngle: 0, endAngle: .pi, clockwise: false); p.closeSubpath(); return p
            }()), c)
            bodyGroup.addChild(dome)
            let cuff = shape(SKShapeNode(rectOf: CGSize(width: 40, height: 9), cornerRadius: 4), c.lighter(0.12))
            cuff.position = CGPoint(x: 2, y: 68); bodyGroup.addChild(cuff)
            let pom = shape(SKShapeNode(circleOfRadius: 5), .white, line: 2)
            pom.position = CGPoint(x: 2, y: 88); bodyGroup.addChild(pom)
        }
    }

    // MARK: États animés

    func startRunning() { guard pose != .run else { return }; pose = .run; animateRun() }

    private func animateRun() {
        legL.removeAllActions(); legR.removeAllActions(); bodyGroup.removeAction(forKey: "pose")
        let period = 0.32
        func swing(_ n: SKNode, phase: Double) {
            n.zRotation = 0
            let a = SKAction.sequence([
                .rotate(toAngle: 0.34, duration: period / 2, shortestUnitArc: true),
                .rotate(toAngle: -0.34, duration: period / 2, shortestUnitArc: true)])
            n.run(.sequence([.wait(forDuration: phase), .repeatForever(a)]))
        }
        swing(legL, phase: 0); swing(legR, phase: period / 2)
        bodyGroup.run(.repeatForever(.sequence([.moveBy(x: 0, y: 3, duration: period / 2),
                                                .moveBy(x: 0, y: -3, duration: period / 2)])), withKey: "pose")
        bodyGroup.childNode(withName: "arm")?.run(.repeatForever(.sequence([
            .rotate(toAngle: 0.6, duration: period / 2, shortestUnitArc: true),
            .rotate(toAngle: -0.4, duration: period / 2, shortestUnitArc: true)])))
    }

    func jumpPose() {
        pose = .air
        legL.removeAllActions(); legR.removeAllActions(); bodyGroup.removeAction(forKey: "pose")
        bodyGroup.childNode(withName: "arm")?.removeAllActions()
        legL.run(.rotate(toAngle: 0.9, duration: 0.12, shortestUnitArc: true))
        legR.run(.rotate(toAngle: 0.6, duration: 0.12, shortestUnitArc: true))
        bodyGroup.run(.moveTo(y: 0, duration: 0.1))
    }

    func land() { if pose != .run { startRunning() } }

    func setSliding(_ on: Bool) {
        pose = on ? .slide : .run
        if on {
            legL.removeAllActions(); legR.removeAllActions()
            legL.run(.rotate(toAngle: 1.4, duration: 0.1, shortestUnitArc: true))
            legR.run(.rotate(toAngle: 1.4, duration: 0.1, shortestUnitArc: true))
        } else { startRunning() }
    }
}
