import CoreGraphics

/// Types d'entités du monde, en coordonnées « monde » (points depuis le départ). Chaque entité a un
/// identifiant stable : le rendu recycle les nœuds SpriteKit par id (pooling), indispensable pour un
/// runner infini.
enum ObstacleKind {
    case cactus   // à sauter
    case barrel   // à sauter
    case beam     // à glisser dessous
}

struct GroundSegment { var id: Int; var startX: CGFloat; var endX: CGFloat }
struct Obstacle { var id: Int; var x: CGFloat; var kind: ObstacleKind }
struct Coin { var id: Int; var x: CGFloat; var y: CGFloat }   // y = hauteur au-dessus du sol

/// Power-ups ramassables en course. Le bénéfice est partagé par les DEUX joueurs (PRD §4.5).
enum PowerupKind: CaseIterable { case magnet, shield, rocket }
struct Powerup { var id: Int; var x: CGFloat; var y: CGFloat; var kind: PowerupKind }
