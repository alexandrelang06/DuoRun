import SwiftUI

extension Color {
    init(hex: UInt32) {
        self.init(.sRGB,
                  red: Double((hex >> 16) & 0xFF) / 255,
                  green: Double((hex >> 8) & 0xFF) / 255,
                  blue: Double(hex & 0xFF) / 255,
                  opacity: 1)
    }
}

#if canImport(UIKit)
import UIKit
extension UIColor {
    convenience init(hex: UInt32) {
        self.init(red: CGFloat((hex >> 16) & 0xFF) / 255,
                  green: CGFloat((hex >> 8) & 0xFF) / 255,
                  blue: CGFloat(hex & 0xFF) / 255,
                  alpha: 1)
    }
}
#endif

/// Palette du biome Canyon Western (PRD §5, §9). Flat texturé chaleureux, formes rondes, traits épais.
enum Pal {
    // Ciel et fonds
    static let skyTop    = UIColor(hex: 0xF6E2B8)
    static let skyBottom = UIColor(hex: 0xF2D8A7)
    static let sun       = UIColor(hex: 0xF7C978)
    // Mesas en parallaxe (fonds lointains) : volontairement PLUS CLAIRES et désaturées que le sol,
    // pour reculer et ne jamais se confondre avec la surface jouable.
    static let mesaFar   = UIColor(hex: 0xEFCEA6)
    static let mesaMid   = UIColor(hex: 0xE3B487)
    static let mesaNear  = UIColor(hex: 0xD79A6B)
    // Sol (surface jouable, terracotta franc, plus foncé que les mesas)
    static let groundTop  = UIColor(hex: 0xC46A3B)
    static let groundEdgeTop = UIColor(hex: 0xE0895A)   // liseré clair de la surface
    static let groundBody = UIColor(hex: 0x8A4A28)
    static let groundEdge = UIColor(hex: 0x6E3A1F)
    // Éléments
    static let cactus     = UIColor(hex: 0x4E8B4A)
    static let cactusDark = UIColor(hex: 0x3C6E39)
    static let barrel     = UIColor(hex: 0x9A5A2E)
    static let barrelHoop = UIColor(hex: 0x5E3418)
    static let coin       = UIColor(hex: 0xF4C430)
    static let coinShine  = UIColor(hex: 0xFCE7A0)
    static let ink        = UIColor(hex: 0x3A2A1E)   // contour commun
    // Personnage (cowboy toon)
    static let heroSkin  = UIColor(hex: 0xF3C79B)
    static let heroHat   = UIColor(hex: 0x8A5A32)
    static let heroShirt = UIColor(hex: 0xD6503F)
    static let heroPants = UIColor(hex: 0x3E5C8A)
    // UI
    static let uiText    = UIColor(hex: 0xFBF7F0)
}
