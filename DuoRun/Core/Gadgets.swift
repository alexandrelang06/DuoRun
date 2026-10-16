import Foundation

/// Gadgets permanents (améliorations passives, façon Jetpack Joyride) : achetés une fois avec des
/// pièces, actifs à chaque partie. Ils donnent une raison de dépenser les pièces et un sentiment de
/// progression durable.
struct Gadget: Identifiable, Hashable {
    let id: String
    let name: String
    let desc: String
    let price: Int      // pièces
    let icon: String    // SF Symbol
}

enum Gadgets {
    static let all: [Gadget] = [
        Gadget(id: "g_headstart", name: "Départ lancé", desc: "Commence chaque partie 200 m plus loin",
               price: 4000, icon: "forward.fill"),
        Gadget(id: "g_shield", name: "Bouclier de départ", desc: "Commence chaque partie avec un bouclier",
               price: 3000, icon: "shield.lefthalf.filled"),
        Gadget(id: "g_magnet", name: "Aimant renforcé", desc: "L'aimant dure plus longtemps (12 s)",
               price: 2500, icon: "circle.hexagongrid.fill"),
    ]
    static func item(_ id: String) -> Gadget? { all.first { $0.id == id } }
}
