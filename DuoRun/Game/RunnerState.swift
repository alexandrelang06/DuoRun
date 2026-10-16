import Foundation
import CoreGraphics

/// Constantes de game feel, partagées par la scène et les coureurs.
struct Tuning {
    var gravity: CGFloat = -2800
    var jumpV: CGFloat = 920       // saut solo abaissé (~150 pt de haut) : proportionné aux obstacles
    var doubleV: CGFloat = 850
    var glideCap: CGFloat = -240
    var diveV: CGFloat = -1700
    var baseSpeed: CGFloat = 340
    var maxSpeed: CGFloat = 640    // vitesse de pointe relevée : on accélère nettement, mais jouable
    var fallLimit: CGFloat = 520   // sous le sol de tant de points = chute
}

/// État vertical d'un coureur. L'horizontale est commune (distance partagée du monde) ; chaque coureur
/// gère seulement son saut / plané / glissade et sa hauteur `y`. En duo, deux `RunnerState` jouent la
/// même piste (même seed, même distance) mais sautent indépendamment.
final class RunnerState {
    var y: CGFloat
    var vy: CGFloat = 0
    var grounded = true
    var canDouble = false
    var sliding = false
    var slideTimer: TimeInterval = 0
    var isHolding = false
    /// À terre, en attente de réanimation (mode coop) ou fin de run.
    var down = false
    /// Invincibilité (secondes) après une réanimation.
    var invi: Double = 0
    /// Bouclier : encaisse un choc sans tomber.
    var shield = false
    /// Fusée : vol invincible pendant `flyTimer` secondes vers `flyTarget`.
    var flyTimer: Double = 0
    var flyTarget: CGFloat = 0

    let groundTopY: CGFloat
    init(groundTopY: CGFloat) { self.groundTopY = groundTopY; self.y = groundTopY }

    enum Event { case none, landed, fell }

    // Intentions (routées depuis les entrées)
    func jump(_ t: Tuning) {
        guard !down else { return }
        if grounded { vy = t.jumpV; grounded = false; canDouble = true }
        else if canDouble { vy = t.doubleV; canDouble = false }
    }
    func beginSlide(_ t: Tuning) {
        guard !down else { return }
        sliding = true; slideTimer = 1.5
        if !grounded { vy = min(vy, t.diveV) }
    }

    /// Avance la physique verticale. `distance` = position monde commune (pour tester le sol).
    func step(dt: Double, distance: CGFloat, sim: WorldSim, t: Tuning) -> Event {
        guard !down else { return .none }
        if invi > 0 { invi -= dt }
        // Fusée : vol invincible, on s'élève vers la cible en ignorant sol/gravité.
        if flyTimer > 0 {
            flyTimer -= dt; invi = max(invi, 0.15)
            grounded = false; sliding = false
            y += (flyTarget - y) * min(1, CGFloat(dt) * 6)
            return .none
        }
        let d = CGFloat(dt)
        vy += t.gravity * d
        if isHolding && !grounded && vy < 0 { vy = max(vy, t.glideCap) }
        let prevY = y
        y += vy * d

        let wasGrounded = grounded
        // On ne « pose » le coureur que s'il TRAVERSE le sol par le haut (atterrissage : il était au
        // niveau ou au-dessus la frame précédente). S'il a déjà plongé sous le sol dans un trou, le
        // bord opposé qui défile sous lui ne le fait PLUS remonter d'un coup → fini la « téléportation
        // après le trou ». Robuste quelle que soit la vitesse de chute ou la durée de frame.
        if sim.hasGround(at: distance) && y <= groundTopY && prevY >= groundTopY - 2 {
            // Atterrissage : on redescend sur le sol par le haut → on se pose.
            y = groundTopY; vy = 0
            if !grounded { grounded = true; canDouble = false }
        } else {
            grounded = false
            // Percussion du MUR : du sol est présent ici mais on est passé SOUS sa surface (on a plongé
            // dans le trou et le bord opposé arrive sur nous) → on se cogne le mur, chute nette immédiate.
            // On ne traverse plus le bloc de sol.
            if sim.hasGround(at: distance) && y < groundTopY - 6 { down = true; return .fell }
            if y < groundTopY - t.fallLimit { down = true; return .fell }
        }
        if sliding { slideTimer -= dt; if slideTimer <= 0 && grounded { sliding = false } }
        return (grounded && !wasGrounded) ? .landed : .none
    }

    func reset() {
        y = groundTopY; vy = 0; grounded = true; canDouble = false
        sliding = false; slideTimer = 0; isHolding = false; down = false; invi = 0
        shield = false; flyTimer = 0; flyTarget = 0
    }

    /// Réanimation : on repose au sol avec une courte invincibilité, sans réinitialiser la partie.
    func revive() {
        down = false; y = groundTopY; vy = 0
        grounded = true; canDouble = false; sliding = false; slideTimer = 0; invi = 2.0
    }
}
