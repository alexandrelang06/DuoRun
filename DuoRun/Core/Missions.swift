import Foundation

/// Missions façon Jetpack Joyride : 3 actives en permanence, à compléter pour gagner des pièces et des
/// étoiles (progression douce). Quand l'une est finie, une nouvelle la remplace. C'est le principal
/// moteur de rétention : toujours un objectif à poursuivre, qui pousse à varier son jeu.
enum MissionKind: String, Codable, CaseIterable {
    case coins, meters, jumps, slides, saves, runs
}

struct Mission: Codable, Identifiable, Equatable {
    var id: String
    var kind: MissionKind
    var target: Int
    var progress: Int
    var reward: Int      // pièces
    var stars: Int
    var done: Bool { progress >= target }

    var text: String {
        switch kind {
        case .coins:  return "Récolte \(target) pièces"
        case .meters: return "Cours \(target) m au total"
        case .jumps:  return "Saute \(target) fois"
        case .slides: return "Glisse \(target) fois"
        case .saves:  return "Sauve ton partenaire \(target) fois"
        case .runs:   return "Termine \(target) parties"
        }
    }
    var icon: String {
        switch kind {
        case .coins: return "circle.circle.fill"; case .meters: return "figure.run"
        case .jumps: return "arrow.up.circle.fill"; case .slides: return "arrow.down.circle.fill"
        case .saves: return "heart.circle.fill"; case .runs: return "flag.checkered"
        }
    }
}

enum Missions {
    /// Fourchettes (min, max, pièces par unité, base d'étoiles) par type.
    private static func spec(_ k: MissionKind) -> (ClosedRange<Int>, Double) {
        switch k {
        case .coins:  return (150...700, 1.6)
        case .meters: return (800...3500, 0.6)
        case .jumps:  return (60...240, 5)
        case .slides: return (30...140, 7)
        case .saves:  return (3...14, 160)
        case .runs:   return (3...12, 120)
        }
    }

    static func random(excluding kinds: Set<MissionKind> = []) -> Mission {
        let avail = MissionKind.allCases.filter { !kinds.contains($0) }
        let kind = (avail.isEmpty ? MissionKind.allCases : avail).randomElement()!
        let (range, perUnit) = spec(kind)
        let target = Int.random(in: range)
        let frac = Double(target - range.lowerBound) / Double(max(1, range.upperBound - range.lowerBound))
        let stars = frac < 0.34 ? 1 : (frac < 0.67 ? 2 : 3)
        let reward = max(100, Int(Double(target) * perUnit))
        return Mission(id: UUID().uuidString, kind: kind, target: target, progress: 0, reward: reward, stars: stars)
    }

    /// Trois missions actives, de types distincts si possible.
    static func freshSet() -> [Mission] {
        var set: [Mission] = []
        var used = Set<MissionKind>()
        for _ in 0..<3 { let m = random(excluding: used); used.insert(m.kind); set.append(m) }
        return set
    }
}
