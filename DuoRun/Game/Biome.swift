import UIKit

/// Style de silhouette d'arrière-plan (dessiné en procédural, flat toon, cohérent avec le Western).
enum Silhouette { case mesa, hill, tree, building, peak, crystal }
/// Décor animé du ciel.
enum SkyDecor { case clouds, stars, snow }

/// Déblocage d'un biome : soit offert, soit verrouillé avec **deux** options — un montant élevé en
/// pièces (grind) OU un achat réel (IAP). Le joueur choisit.
enum BiomeUnlock: Equatable {
    case free
    case locked(coins: Int, product: String, money: String)
}

/// Un biome = un ciel (dégradé + astre + décor) + deux couches de silhouettes en parallaxe + une
/// palette de sol. Tout est procédural (aucune image), dans le même style flat que le Western.
struct Biome: Identifiable {
    let id: String
    let name: String
    let skyStops: [(CGFloat, UIColor)]
    let sun: UIColor?                    // astre (soleil/lune/planète), nil = aucun
    let sunPos: CGPoint                  // position relative (0..1) de l'astre
    let farStyle: Silhouette
    let nearStyle: Silhouette
    let farColor: UIColor
    let nearColor: UIColor
    let accent: UIColor                  // néons, reflets…
    let decor: SkyDecor
    let groundTop: UIColor
    let groundEdgeTop: UIColor
    let groundBody: UIColor
    let groundEdge: UIColor
    let moss: UIColor
    var unlock: BiomeUnlock = .free      // par défaut gratuit ; surchargé pour les biomes payants

    private static func c(_ h: UInt32) -> UIColor { UIColor(hex: h) }

    static let western = Biome(
        id: "western", name: "Canyon Western",
        skyStops: [(0, c(0xF6E2B8)), (1, c(0xF2D8A7))], sun: c(0xF7C978), sunPos: CGPoint(x: 0.8, y: 0.78),
        farStyle: .mesa, nearStyle: .mesa, farColor: c(0xEFCEA6), nearColor: c(0xD79A6B), accent: c(0xF4C430),
        decor: .clouds,
        groundTop: Pal.groundTop, groundEdgeTop: Pal.groundEdgeTop, groundBody: Pal.groundBody,
        groundEdge: Pal.groundEdge, moss: c(0x6E8C52))

    static let desert = Biome(
        id: "desert", name: "Désert doré",
        skyStops: [(0, c(0x2E5A8E)), (0.55, c(0x8FB4C0)), (1, c(0xEAC27A))], sun: c(0xFCE6A8), sunPos: CGPoint(x: 0.82, y: 0.34),
        farStyle: .hill, nearStyle: .mesa, farColor: c(0xE7C98A), nearColor: c(0xD9A64E), accent: c(0xF7D07A),
        decor: .clouds,
        groundTop: c(0xD9A64E), groundEdgeTop: c(0xEAC27A), groundBody: c(0x9E6E2E), groundEdge: c(0x6E4A1E), moss: c(0xE0C88A))

    static let jungle = Biome(
        id: "jungle", name: "Jungle émeraude",
        skyStops: [(0, c(0x2E6E62)), (0.5, c(0x74B48E)), (1, c(0xE6E4A6))], sun: c(0xF3EAA2), sunPos: CGPoint(x: 0.7, y: 0.3),
        farStyle: .hill, nearStyle: .tree, farColor: c(0x4E8E6A), nearColor: c(0x2E6E46), accent: c(0xFF8C7A),
        decor: .clouds,
        groundTop: c(0x3E7A4E), groundEdgeTop: c(0x5EA060), groundBody: c(0x274A32), groundEdge: c(0x18301F), moss: c(0x7ABF6A),
        unlock: .locked(coins: 6000, product: "com.duorun.biome_jungle", money: "2,99 €"))

    static let neon = Biome(
        id: "neon", name: "Ville néon",
        skyStops: [(0, c(0x1A1030)), (0.55, c(0x3A2060)), (1, c(0x6E2E7A))], sun: c(0xC79ADE), sunPos: CGPoint(x: 0.72, y: 0.26),
        farStyle: .building, nearStyle: .building, farColor: c(0x2A1E46), nearColor: c(0x3C2C5C), accent: c(0x5FE0E8),
        decor: .stars,
        groundTop: c(0x2E2A4E), groundEdgeTop: c(0x5FE0E8), groundBody: c(0x1A1730), groundEdge: c(0x100E22), moss: c(0x5FE0E8),
        unlock: .locked(coins: 8000, product: "com.duorun.biome_neon", money: "3,99 €"))

    static let snow = Biome(
        id: "snow", name: "Montagnes enneigées",
        skyStops: [(0, c(0x5E80C4)), (0.55, c(0xAFC6E6)), (1, c(0xE8D6DE))], sun: c(0xF2E4EA), sunPos: CGPoint(x: 0.78, y: 0.3),
        farStyle: .peak, nearStyle: .peak, farColor: c(0xBFD0E6), nearColor: c(0xDCE7F2), accent: c(0xFFFFFF),
        decor: .snow,
        groundTop: c(0xD8E4F0), groundEdgeTop: c(0xF2F7FC), groundBody: c(0x9EB2CE), groundEdge: c(0x7E92B0), moss: c(0xBFD6EE),
        unlock: .locked(coins: 10000, product: "com.duorun.biome_snow", money: "4,99 €"))

    static let space = Biome(
        id: "space", name: "Espace",
        skyStops: [(0, c(0x120C2A)), (0.5, c(0x2A1E56)), (1, c(0x5E3A7A))], sun: c(0xC89AE0), sunPos: CGPoint(x: 0.76, y: 0.7),
        farStyle: .crystal, nearStyle: .crystal, farColor: c(0x352A5A), nearColor: c(0x4A3670), accent: c(0x8FD0E8),
        decor: .stars,
        groundTop: c(0x3A3060), groundEdgeTop: c(0x8F76C0), groundBody: c(0x241E42), groundEdge: c(0x150F2E), moss: c(0xC89AE0),
        unlock: .locked(coins: 12000, product: "com.duorun.biome_space", money: "5,99 €"))

    /// Couleur des obstacles, teintée par biome (cactus/rocher/glaçon/borne néon/cristal…).
    var obstacle: UIColor {
        switch id {
        case "desert": return UIColor(hex: 0x9E7A3E)
        case "jungle": return UIColor(hex: 0x2E7D57)
        case "neon":   return UIColor(hex: 0x2E8EA0)
        case "snow":   return UIColor(hex: 0xB4D2E8)
        case "space":  return UIColor(hex: 0x6E5AC0)
        default:       return UIColor(hex: 0x4E8B4A)   // western
        }
    }

    static let all: [Biome] = [western, desert, jungle, neon, snow, space]
    static func byID(_ id: String) -> Biome { all.first { $0.id == id } ?? western }
}
