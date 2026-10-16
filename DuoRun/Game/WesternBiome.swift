import SpriteKit
import UIKit

/// Fabrique de tous les visuels du biome Canyon Western, dessinés par le code (aucun asset externe).
/// Direction artistique (PRD §5, §9) : flat texturé chaleureux, formes rondes, contours épais « ink »,
/// personnage toon à grosse tête. C'est CE style qui est soumis à validation.
enum Western {

    static let outline: CGFloat = 4   // épaisseur de trait commune

    // MARK: Ciel

    static func gradientTexture(_ size: CGSize, top: UIColor, bottom: UIColor) -> SKTexture {
        let r = UIGraphicsImageRenderer(size: size)
        let img = r.image { ctx in
            let cg = ctx.cgContext
            let grad = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(),
                                  colors: [top.cgColor, bottom.cgColor] as CFArray,
                                  locations: [0, 1])!
            cg.drawLinearGradient(grad, start: .zero, end: CGPoint(x: 0, y: size.height), options: [])
        }
        return SKTexture(image: img)
    }

    static func sky(size: CGSize) -> SKNode {
        let node = SKNode()
        let tex = gradientTexture(size, top: Pal.skyTop, bottom: Pal.skyBottom)
        let sky = SKSpriteNode(texture: tex, size: size)
        sky.anchorPoint = CGPoint(x: 0.5, y: 0.5)
        sky.position = CGPoint(x: size.width / 2, y: size.height / 2)
        node.addChild(sky)
        // Soleil doux, haut à droite
        let sun = SKShapeNode(circleOfRadius: 46)
        sun.fillColor = Pal.sun; sun.strokeColor = .clear
        sun.alpha = 0.9
        sun.position = CGPoint(x: size.width * 0.80, y: size.height * 0.78)
        node.addChild(sun)
        return node
    }

    // MARK: Mesas (parallaxe)

    /// Une bande de mesas/buttes arrondies, `width` de large, posées sur `baseY`. On en met deux
    /// côte à côte dans la scène pour un défilement sans couture.
    static func mesaBand(width: CGFloat, color: UIColor, baseY: CGFloat, minH: CGFloat, maxH: CGFloat,
                         count: Int, seed: UInt64) -> SKNode {
        var rng = SplitMix64(seed: seed)
        let band = SKNode()
        let step = width / CGFloat(count)
        for i in 0..<count {
            let h = minH + CGFloat(rng.unit()) * (maxH - minH)
            let w = step * (0.7 + CGFloat(rng.unit()) * 0.5)
            let cx = CGFloat(i) * step + step / 2
            let mesa = mesaShape(w: w, h: h, color: color)
            mesa.position = CGPoint(x: cx, y: baseY)
            band.addChild(mesa)
        }
        return band
    }

    private static func mesaShape(w: CGFloat, h: CGFloat, color: UIColor) -> SKShapeNode {
        // Trapèze à sommet plat et coins arrondis (silhouette de mesa).
        let r: CGFloat = min(18, w * 0.15)
        let topInset = w * 0.16
        let path = CGMutablePath()
        path.move(to: CGPoint(x: -w/2, y: 0))
        path.addLine(to: CGPoint(x: -w/2 + topInset - r, y: h - r))
        path.addQuadCurve(to: CGPoint(x: -w/2 + topInset + r, y: h),
                          control: CGPoint(x: -w/2 + topInset, y: h))
        path.addLine(to: CGPoint(x: w/2 - topInset - r, y: h))
        path.addQuadCurve(to: CGPoint(x: w/2 - topInset + r, y: h - r),
                          control: CGPoint(x: w/2 - topInset, y: h))
        path.addLine(to: CGPoint(x: w/2, y: 0))
        path.closeSubpath()
        let node = SKShapeNode(path: path)
        node.fillColor = color; node.strokeColor = .clear
        node.lineWidth = 0
        // liseré supérieur plus clair (soleil rasant)
        let cap = SKShapeNode(rectOf: CGSize(width: w * 0.68, height: 8), cornerRadius: 4)
        cap.fillColor = color.lighter(0.12); cap.strokeColor = .clear
        cap.position = CGPoint(x: 0, y: h - 4)
        node.addChild(cap)
        return node
    }

    // MARK: Sol

    /// Un segment de sol (bande claire dessus, terre foncée dessous), aux couleurs du biome.
    static func groundSegment(w: CGFloat, depth: CGFloat,
                              top: UIColor = Pal.groundTop, edgeTop: UIColor = Pal.groundEdgeTop,
                              body: UIColor = Pal.groundBody, edge: UIColor = Pal.groundEdge) -> SKNode {
        let node = SKNode()
        let bodyN = SKShapeNode(rect: CGRect(x: 0, y: -depth, width: w, height: depth))
        bodyN.fillColor = body; bodyN.strokeColor = .clear
        node.addChild(bodyN)
        let topN = SKShapeNode(rect: CGRect(x: 0, y: -22, width: w, height: 22))
        topN.fillColor = top; topN.strokeColor = .clear
        node.addChild(topN)
        // liseré clair de surface : rend la ligne de sol nette et sans ambiguïté
        let hi = SKShapeNode(rect: CGRect(x: 0, y: -5, width: w, height: 5))
        hi.fillColor = edgeTop; hi.strokeColor = .clear
        node.addChild(hi)
        // pointillés de texture (cailloux) sur la bande de terre
        var x: CGFloat = 24
        while x < w - 10 {
            let dot = SKShapeNode(circleOfRadius: 3)
            dot.fillColor = edge; dot.strokeColor = .clear
            dot.position = CGPoint(x: x, y: -40 - CGFloat((Int(x) % 3)) * 8)
            node.addChild(dot)
            x += 46
        }
        let edgeN = SKShapeNode(rect: CGRect(x: 0, y: -24, width: w, height: 4))
        edgeN.fillColor = edge; edgeN.strokeColor = .clear
        node.addChild(edgeN)
        return node
    }

    // MARK: Obstacles

    static func cactus(color: UIColor = Pal.cactus) -> SKNode {
        let n = SKNode()
        n.addChild(roundedBar(w: 26, h: 74, color: color))
        let armL = roundedBar(w: 14, h: 26, color: color); armL.position = CGPoint(x: -18, y: 34); n.addChild(armL)
        let armLUp = roundedBar(w: 14, h: 22, color: color); armLUp.position = CGPoint(x: -18, y: 56); n.addChild(armLUp)
        let armR = roundedBar(w: 14, h: 22, color: color); armR.position = CGPoint(x: 18, y: 42); n.addChild(armR)
        let armRUp = roundedBar(w: 14, h: 18, color: color); armRUp.position = CGPoint(x: 18, y: 60); n.addChild(armRUp)
        return n
    }

    static func barrel(color: UIColor = Pal.barrel) -> SKNode {
        let n = SKNode()
        let body = SKShapeNode(rectOf: CGSize(width: 54, height: 60), cornerRadius: 14)
        body.fillColor = color; body.strokeColor = Pal.ink; body.lineWidth = outline
        body.position = CGPoint(x: 0, y: 30); n.addChild(body)
        for dy in [16, 44] {
            let hoop = SKShapeNode(rectOf: CGSize(width: 56, height: 7), cornerRadius: 3)
            hoop.fillColor = color.darker(0.22); hoop.strokeColor = .clear
            hoop.position = CGPoint(x: 0, y: CGFloat(dy)); n.addChild(hoop)
        }
        return n
    }

    /// Poutre basse en surplomb : la barre est à hauteur de tête (~y=52), il faut glisser dessous.
    static func beam(color: UIColor = Pal.barrel) -> SKNode {
        let n = SKNode()
        for dx in [-42, 42] {
            let post = SKShapeNode(rectOf: CGSize(width: 10, height: 108), cornerRadius: 5)
            post.fillColor = color.darker(0.22); post.strokeColor = .clear
            post.position = CGPoint(x: CGFloat(dx), y: 54); n.addChild(post)
        }
        let bar = SKShapeNode(rectOf: CGSize(width: 104, height: 20), cornerRadius: 8)
        bar.fillColor = color; bar.strokeColor = Pal.ink; bar.lineWidth = outline
        bar.position = CGPoint(x: 0, y: 52); n.addChild(bar)
        return n
    }

    // MARK: Vie de décor (nuages, oiseaux) + ombres

    static func cloud() -> SKNode {
        let n = SKNode()
        let puffs: [(CGFloat, CGFloat, CGFloat)] = [(-34, 0, 24), (0, 6, 32), (30, 0, 22), (-6, -6, 26)]
        for (x, y, r) in puffs {
            let p = SKShapeNode(circleOfRadius: r)
            p.fillColor = UIColor.white.withAlphaComponent(0.85); p.strokeColor = .clear
            p.position = CGPoint(x: x, y: y); n.addChild(p)
        }
        return n
    }

    /// Oiseau simple (silhouette « mouette ») avec un léger battement d'ailes.
    static func bird() -> SKNode {
        let n = SKNode()
        func wing(flip: CGFloat) -> SKShapeNode {
            let path = CGMutablePath()
            path.move(to: .zero)
            path.addQuadCurve(to: CGPoint(x: 16 * flip, y: 0), control: CGPoint(x: 8 * flip, y: 8))
            let w = SKShapeNode(path: path)
            w.strokeColor = Pal.ink.withAlphaComponent(0.55); w.lineWidth = 3; w.lineCap = .round
            return w
        }
        let l = wing(flip: -1), r = wing(flip: 1)
        n.addChild(l); n.addChild(r)
        let flap = SKAction.sequence([.scaleY(to: 0.6, duration: 0.25), .scaleY(to: 1, duration: 0.25)])
        n.run(.repeatForever(flap))
        return n
    }

    /// Ombre portée douce, à poser au sol sous une entité.
    static func shadow(width: CGFloat) -> SKShapeNode {
        let s = SKShapeNode(ellipseOf: CGSize(width: width, height: width * 0.32))
        s.fillColor = UIColor(hex: 0x6E3A1F).withAlphaComponent(0.28); s.strokeColor = .clear
        return s
    }

    // MARK: Pièce

    static func coin() -> SKNode {
        let c = SKShapeNode(circleOfRadius: 15)
        c.fillColor = Pal.coin; c.strokeColor = Pal.ink; c.lineWidth = 3
        let shine = SKShapeNode(circleOfRadius: 7)
        shine.fillColor = Pal.coinShine; shine.strokeColor = .clear
        shine.position = CGPoint(x: -3, y: 3); c.addChild(shine)
        c.run(.repeatForever(.sequence([
            .moveBy(x: 0, y: 6, duration: 0.6), .moveBy(x: 0, y: -6, duration: 0.6)
        ])))
        return c
    }

    // MARK: Power-ups

    static func powerup(_ kind: PowerupKind) -> SKNode {
        let n = SKNode()
        let color: UIColor; let glyph: String
        switch kind {
        case .magnet: color = UIColor(hex: 0xFF6B6B); glyph = "🧲"
        case .shield: color = UIColor(hex: 0x5FBFE0); glyph = "🛡️"
        case .rocket: color = UIColor(hex: 0xF4C430); glyph = "🚀"
        }
        let orb = SKShapeNode(circleOfRadius: 20)
        orb.fillColor = color; orb.strokeColor = Pal.ink; orb.lineWidth = 3
        n.addChild(orb)
        let lbl = SKLabelNode(text: glyph)
        lbl.fontSize = 22; lbl.verticalAlignmentMode = .center; lbl.horizontalAlignmentMode = .center
        n.addChild(lbl)
        n.run(.repeatForever(.sequence([.moveBy(x: 0, y: 6, duration: 0.6), .moveBy(x: 0, y: -6, duration: 0.6)])))
        return n
    }

    // MARK: Drapeau du record (marqueur « plus loin »)

    /// Drapeau à damier planté à la meilleure distance atteinte. Origine locale au pied du mât.
    static func recordFlag(accent: UIColor) -> SKNode {
        let n = SKNode()
        let poleH: CGFloat = 96
        let pole = SKShapeNode(rect: CGRect(x: -3, y: 0, width: 6, height: poleH), cornerRadius: 3)
        pole.fillColor = UIColor(hex: 0x4A3B2E); pole.strokeColor = Pal.ink; pole.lineWidth = 2
        n.addChild(pole)

        // Fanion à damier (petits carreaux noir/blanc), accroché en haut du mât.
        let cols = 4, rows = 3
        let cell: CGFloat = 9
        let flag = SKNode()
        for cx in 0..<cols {
            for cy in 0..<rows {
                let sq = SKShapeNode(rect: CGRect(x: CGFloat(cx) * cell, y: CGFloat(cy) * cell, width: cell, height: cell))
                sq.fillColor = (cx + cy) % 2 == 0 ? .white : UIColor(hex: 0x1E1A26)
                sq.strokeColor = .clear
                flag.addChild(sq)
            }
        }
        flag.position = CGPoint(x: 3, y: poleH - CGFloat(rows) * cell - 4)
        n.addChild(flag)

        // Petite pastille « record » colorée en pointe du mât.
        let knob = SKShapeNode(circleOfRadius: 5)
        knob.fillColor = accent; knob.strokeColor = Pal.ink; knob.lineWidth = 2
        knob.position = CGPoint(x: 0, y: poleH + 2)
        n.addChild(knob)

        n.run(.repeatForever(.sequence([.moveBy(x: 0, y: 3, duration: 0.7), .moveBy(x: 0, y: -3, duration: 0.7)])))
        return n
    }

    // MARK: Héros (cowboy toon à grosse tête)

    /// Pieds à l'origine locale (y=0), le personnage pousse vers le haut. `container` porte tout.
    static func hero() -> SKNode {
        let n = SKNode()
        // jambes
        for dx in [-8, 8] {
            let leg = roundedBar(w: 11, h: 16, color: Pal.heroPants)
            leg.position = CGPoint(x: CGFloat(dx), y: 0); n.addChild(leg)
        }
        // corps (chemise)
        let body = SKShapeNode(rectOf: CGSize(width: 30, height: 26), cornerRadius: 10)
        body.fillColor = Pal.heroShirt; body.strokeColor = Pal.ink; body.lineWidth = outline
        body.position = CGPoint(x: 0, y: 26); n.addChild(body)
        // grosse tête
        let head = SKShapeNode(circleOfRadius: 21)
        head.fillColor = Pal.heroSkin; head.strokeColor = Pal.ink; head.lineWidth = outline
        head.position = CGPoint(x: 2, y: 56); n.addChild(head)
        // yeux
        for dx in [ -4, 8 ] {
            let eye = SKShapeNode(circleOfRadius: 3)
            eye.fillColor = Pal.ink; eye.strokeColor = .clear
            eye.position = CGPoint(x: CGFloat(dx) + 2, y: 58); n.addChild(eye)
        }
        // chapeau de cowboy
        let brim = SKShapeNode(ellipseOf: CGSize(width: 52, height: 16))
        brim.fillColor = Pal.heroHat; brim.strokeColor = Pal.ink; brim.lineWidth = outline
        brim.position = CGPoint(x: 2, y: 72); n.addChild(brim)
        let crown = SKShapeNode(rectOf: CGSize(width: 28, height: 18), cornerRadius: 8)
        crown.fillColor = Pal.heroHat; crown.strokeColor = Pal.ink; crown.lineWidth = outline
        crown.position = CGPoint(x: 2, y: 80); n.addChild(crown)
        n.name = "hero"
        return n
    }

    // MARK: Ciel multi-stops + astre

    static func multiGradient(_ size: CGSize, _ stops: [(CGFloat, UIColor)]) -> SKTexture {
        let r = UIGraphicsImageRenderer(size: size)
        let img = r.image { ctx in
            let colors = stops.map { $0.1.cgColor } as CFArray
            let locs = stops.map { $0.0 }
            if let g = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: colors, locations: locs) {
                ctx.cgContext.drawLinearGradient(g, start: .zero, end: CGPoint(x: 0, y: size.height), options: [])
            }
        }
        return SKTexture(image: img)
    }

    static func skyNode(size: CGSize, biome: Biome) -> SKNode {
        let node = SKNode()
        let sky = SKSpriteNode(texture: multiGradient(size, biome.skyStops), size: size)
        sky.anchorPoint = .zero; sky.position = .zero
        node.addChild(sky)
        if let sun = biome.sun {
            let s = SKShapeNode(circleOfRadius: 44)
            s.fillColor = sun; s.strokeColor = .clear; s.alpha = 0.92
            s.position = CGPoint(x: size.width * biome.sunPos.x, y: size.height * biome.sunPos.y)
            node.addChild(s)
        }
        return node
    }

    // MARK: Silhouettes par style (bandes tileables, base à `baseY`)

    static func band(width: CGFloat, style: Silhouette, color: UIColor, accent: UIColor, baseY: CGFloat,
                     minH: CGFloat, maxH: CGFloat, count: Int, seed: UInt64) -> SKNode {
        switch style {
        case .mesa: return mesaBand(width: width, color: color, baseY: baseY, minH: minH, maxH: maxH, count: count, seed: seed)
        case .hill: return hillBand(width: width, color: color, baseY: baseY, minH: minH, maxH: maxH, count: count, seed: seed)
        case .tree: return treeBand(width: width, color: color, baseY: baseY, minH: minH, maxH: maxH, count: count, seed: seed)
        case .building: return buildingBand(width: width, color: color, accent: accent, baseY: baseY, minH: minH, maxH: maxH, count: count, seed: seed)
        case .peak: return peakBand(width: width, color: color, baseY: baseY, minH: minH, maxH: maxH, count: count, seed: seed)
        case .crystal: return crystalBand(width: width, color: color, accent: accent, baseY: baseY, minH: minH, maxH: maxH, count: count, seed: seed)
        }
    }

    private static func hillBand(width: CGFloat, color: UIColor, baseY: CGFloat, minH: CGFloat, maxH: CGFloat, count: Int, seed: UInt64) -> SKNode {
        var rng = SplitMix64(seed: seed); let n = SKNode()
        let step = width / CGFloat(count)
        var peaks: [CGPoint] = []
        for i in 0...count { peaks.append(CGPoint(x: CGFloat(i) * step, y: minH + CGFloat(rng.unit()) * (maxH - minH))) }
        let path = CGMutablePath(); path.move(to: CGPoint(x: 0, y: -6)); path.addLine(to: CGPoint(x: 0, y: peaks[0].y))
        for i in 0..<count {
            path.addQuadCurve(to: peaks[i + 1], control: CGPoint(x: (peaks[i].x + peaks[i + 1].x) / 2, y: max(peaks[i].y, peaks[i + 1].y) + 8))
        }
        path.addLine(to: CGPoint(x: width, y: -6)); path.closeSubpath()
        let s = SKShapeNode(path: path); s.fillColor = color; s.strokeColor = .clear
        s.position = CGPoint(x: 0, y: baseY); n.addChild(s); return n
    }

    private static func treeBand(width: CGFloat, color: UIColor, baseY: CGFloat, minH: CGFloat, maxH: CGFloat, count: Int, seed: UInt64) -> SKNode {
        var rng = SplitMix64(seed: seed); let n = SKNode()
        let step = width / CGFloat(count)
        for i in 0..<count {
            let cx = CGFloat(i) * step + step / 2
            let h = minH + CGFloat(rng.unit()) * (maxH - minH)
            let trunk = SKShapeNode(rectOf: CGSize(width: 10, height: h * 0.5))
            trunk.fillColor = color.darker(0.06); trunk.strokeColor = .clear
            trunk.position = CGPoint(x: cx, y: baseY + h * 0.25); n.addChild(trunk)
            for k in 0..<3 {
                let r = (h * 0.32) * (1 - CGFloat(k) * 0.18)
                let blob = SKShapeNode(circleOfRadius: r)
                blob.fillColor = color; blob.strokeColor = .clear
                blob.position = CGPoint(x: cx + CGFloat(k % 2 == 0 ? -8 : 8), y: baseY + h * 0.5 + CGFloat(k) * r * 0.7)
                n.addChild(blob)
            }
        }
        return n
    }

    private static func buildingBand(width: CGFloat, color: UIColor, accent: UIColor, baseY: CGFloat, minH: CGFloat, maxH: CGFloat, count: Int, seed: UInt64) -> SKNode {
        var rng = SplitMix64(seed: seed); let n = SKNode()
        let step = width / CGFloat(count)
        for i in 0..<count {
            let cx = CGFloat(i) * step + step / 2
            let h = minH + CGFloat(rng.unit()) * (maxH - minH)
            let w = step * (0.55 + CGFloat(rng.unit()) * 0.3)
            let b = SKShapeNode(rect: CGRect(x: cx - w / 2, y: 0, width: w, height: h), cornerRadius: 4)
            b.fillColor = color; b.strokeColor = .clear; b.position = CGPoint(x: 0, y: baseY); n.addChild(b)
            var wy = h - 14
            while wy > 12 {
                let win = SKShapeNode(rectOf: CGSize(width: 4, height: 4))
                win.fillColor = accent; win.strokeColor = .clear; win.alpha = CGFloat(rng.unit()) > 0.4 ? 0.9 : 0.25
                win.position = CGPoint(x: cx - w / 4 + CGFloat(Int(rng.unit() * 3)) * (w / 5), y: baseY + wy)
                n.addChild(win); wy -= 14
            }
        }
        return n
    }

    private static func peakBand(width: CGFloat, color: UIColor, baseY: CGFloat, minH: CGFloat, maxH: CGFloat, count: Int, seed: UInt64) -> SKNode {
        var rng = SplitMix64(seed: seed); let n = SKNode()
        let step = width / CGFloat(count)
        for i in 0..<count {
            let cx = CGFloat(i) * step + step / 2
            let h = minH + CGFloat(rng.unit()) * (maxH - minH); let w = step * 0.9
            let p = CGMutablePath(); p.move(to: CGPoint(x: cx - w / 2, y: 0)); p.addLine(to: CGPoint(x: cx - w * 0.08, y: h * 0.82))
            p.addLine(to: CGPoint(x: cx, y: h)); p.addLine(to: CGPoint(x: cx + w * 0.12, y: h * 0.78)); p.addLine(to: CGPoint(x: cx + w / 2, y: 0)); p.closeSubpath()
            let s = SKShapeNode(path: p); s.fillColor = color; s.strokeColor = .clear; s.position = CGPoint(x: 0, y: baseY); n.addChild(s)
            // coiffe de neige/lumière
            let cap = SKShapeNode(path: {
                let q = CGMutablePath(); q.move(to: CGPoint(x: cx - w * 0.12, y: h * 0.7)); q.addLine(to: CGPoint(x: cx, y: h)); q.addLine(to: CGPoint(x: cx + w * 0.14, y: h * 0.68)); q.closeSubpath(); return q
            }()); cap.fillColor = color.lighter(0.18); cap.strokeColor = .clear; cap.position = CGPoint(x: 0, y: baseY); n.addChild(cap)
        }
        return n
    }

    private static func crystalBand(width: CGFloat, color: UIColor, accent: UIColor, baseY: CGFloat, minH: CGFloat, maxH: CGFloat, count: Int, seed: UInt64) -> SKNode {
        var rng = SplitMix64(seed: seed); let n = SKNode()
        let step = width / CGFloat(count)
        for i in 0..<count {
            let cx = CGFloat(i) * step + step / 2
            let h = minH + CGFloat(rng.unit()) * (maxH - minH); let w = step * 0.5
            let tilt = CGFloat(rng.unit() - 0.5) * 20
            let p = CGMutablePath(); p.move(to: CGPoint(x: cx - w / 2, y: 0)); p.addLine(to: CGPoint(x: cx - w * 0.2, y: h * 0.6))
            p.addLine(to: CGPoint(x: cx + tilt, y: h)); p.addLine(to: CGPoint(x: cx + w * 0.3, y: h * 0.55)); p.addLine(to: CGPoint(x: cx + w / 2, y: 0)); p.closeSubpath()
            let s = SKShapeNode(path: p); s.fillColor = color; s.strokeColor = accent.withAlphaComponent(0.4); s.lineWidth = 2
            s.position = CGPoint(x: 0, y: baseY); n.addChild(s)
        }
        return n
    }

    // MARK: Décor de ciel

    static func starfield(size: CGSize, count: Int) -> SKNode {
        var rng = SplitMix64(seed: 424242); let n = SKNode()
        for _ in 0..<count {
            let r = CGFloat(0.6 + rng.unit() * 1.8)
            let star = SKShapeNode(circleOfRadius: r)
            star.fillColor = .white; star.strokeColor = .clear; star.alpha = CGFloat(0.4 + rng.unit() * 0.6)
            star.position = CGPoint(x: CGFloat(rng.unit()) * size.width, y: size.height * (0.35 + CGFloat(rng.unit()) * 0.6))
            n.addChild(star)
        }
        return n
    }

    static func snowLayer(size: CGSize, count: Int) -> SKNode {
        var rng = SplitMix64(seed: 71717); let n = SKNode()
        for _ in 0..<count {
            let flake = SKShapeNode(circleOfRadius: CGFloat(1.5 + rng.unit() * 2))
            flake.fillColor = .white; flake.strokeColor = .clear; flake.alpha = 0.85
            let x0 = CGFloat(rng.unit()) * size.width, dur = 3.0 + rng.unit() * 3
            flake.position = CGPoint(x: x0, y: size.height * CGFloat(rng.unit()))
            n.addChild(flake)
            let fall = SKAction.moveBy(x: -18, y: -size.height - 20, duration: dur)
            let reset = SKAction.run { [weak flake] in flake?.position = CGPoint(x: CGFloat.random(in: 0...size.width), y: size.height + 10) }
            flake.run(.repeatForever(.sequence([fall, reset])))
        }
        return n
    }

    // MARK: util

    static func roundedBar(w: CGFloat, h: CGFloat, color: UIColor) -> SKShapeNode {
        let bar = SKShapeNode(rectOf: CGSize(width: w, height: h), cornerRadius: min(w, h) / 2.4)
        bar.fillColor = color; bar.strokeColor = Pal.ink; bar.lineWidth = outline
        bar.position = CGPoint(x: 0, y: h / 2)
        return bar
    }
}

extension UIColor {
    func lighter(_ amount: CGFloat) -> UIColor {
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        getRed(&r, green: &g, blue: &b, alpha: &a)
        return UIColor(red: min(r + amount, 1), green: min(g + amount, 1), blue: min(b + amount, 1), alpha: a)
    }
    func darker(_ amount: CGFloat) -> UIColor {
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        getRed(&r, green: &g, blue: &b, alpha: &a)
        return UIColor(red: max(r - amount, 0), green: max(g - amount, 0), blue: max(b - amount, 0), alpha: a)
    }
}

/// Générateur pseudo-aléatoire déterministe (seedé) — servira aussi à la génération procédurale.
struct SplitMix64 {
    private var state: UInt64
    init(seed: UInt64) { state = seed }
    mutating func next() -> UInt64 {
        state &+= 0x9E3779B97F4A7C15
        var z = state
        z = (z ^ (z >> 30)) &* 0xBF58476D1CE4E5B9
        z = (z ^ (z >> 27)) &* 0x94D049BB133111EB
        return z ^ (z >> 31)
    }
    mutating func unit() -> Double { Double(next() >> 11) * (1.0 / 9007199254740992.0) }
}
