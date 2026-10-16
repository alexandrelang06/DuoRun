import UIKit

enum CosmeticKind { case outfit, hat, skin }

/// Prix : en pièces (gagnées en jouant) ou en argent réel (IAP).
enum CosmeticPrice { case coins(Int), money(String) }

struct Cosmetic: Identifiable, Hashable {
    let id: String
    let name: String
    let kind: CosmeticKind
    let price: CosmeticPrice
    static func == (a: Cosmetic, b: Cosmetic) -> Bool { a.id == b.id }
    func hash(into h: inout Hasher) { h.combine(id) }
}

/// Catalogue des cosmétiques. Tenues + chapeaux basiques en pièces (échelle de prix croissante) ;
/// skins spéciaux surtout en argent réel (un skin premium en pièces « montant élevé »). Les items
/// gratuits (0 pièce) sont possédés d'office.
enum Cosmetics {
    static let outfits: [Cosmetic] = [
        Cosmetic(id: "outfit_classic", name: "Classique",     kind: .outfit, price: .coins(0)),
        Cosmetic(id: "outfit_crimson", name: "Cramoisi",      kind: .outfit, price: .coins(900)),
        Cosmetic(id: "outfit_forest",  name: "Forestier",     kind: .outfit, price: .coins(1300)),
        Cosmetic(id: "outfit_ocean",   name: "Marin",         kind: .outfit, price: .coins(1700)),
        Cosmetic(id: "outfit_teal",    name: "Explorateur",   kind: .outfit, price: .coins(2000)),
        Cosmetic(id: "outfit_sunset",  name: "Crépuscule",    kind: .outfit, price: .coins(2400)),
        Cosmetic(id: "outfit_candy",   name: "Bonbon",        kind: .outfit, price: .coins(2800)),
        Cosmetic(id: "outfit_mint",    name: "Menthe",        kind: .outfit, price: .coins(3200)),
        Cosmetic(id: "outfit_shadow",  name: "Ombre",         kind: .outfit, price: .coins(3800)),
        Cosmetic(id: "outfit_royal",   name: "Royal",         kind: .outfit, price: .coins(4500)),
        Cosmetic(id: "outfit_gold",    name: "Doré",          kind: .outfit, price: .coins(6500)),
    ]
    static let hats: [Cosmetic] = [
        Cosmetic(id: "hat_cowboy",      name: "Chapeau cowboy",   kind: .hat, price: .coins(0)),
        Cosmetic(id: "hat_band",        name: "Bandeau",          kind: .hat, price: .coins(700)),
        Cosmetic(id: "hat_cap",         name: "Casquette",        kind: .hat, price: .coins(1100)),
        Cosmetic(id: "hat_cap_red",     name: "Casquette rouge",  kind: .hat, price: .coins(1300)),
        Cosmetic(id: "hat_cap_green",   name: "Casquette verte",  kind: .hat, price: .coins(1500)),
        Cosmetic(id: "hat_band_gold",   name: "Bandeau doré",     kind: .hat, price: .coins(1800)),
        Cosmetic(id: "hat_band_purple", name: "Bandeau violet",   kind: .hat, price: .coins(2000)),
        Cosmetic(id: "hat_beanie",      name: "Bonnet",           kind: .hat, price: .coins(2400)),
        Cosmetic(id: "hat_crown",       name: "Couronne",         kind: .hat, price: .coins(4000)),
    ]
    static let skins: [Cosmetic] = [
        Cosmetic(id: "skin_ghost",  name: "Fantôme", kind: .skin, price: .money("1,99 €")),
        Cosmetic(id: "skin_robot",  name: "Robot",   kind: .skin, price: .money("2,99 €")),
        Cosmetic(id: "skin_dragon", name: "Dragon",  kind: .skin, price: .money("3,99 €")),
        Cosmetic(id: "skin_cat",    name: "Chat",    kind: .skin, price: .coins(12000)),
    ]
    static var all: [Cosmetic] { outfits + hats + skins }
    static let freeDefaults = ["outfit_classic", "hat_cowboy"]

    static func item(_ id: String) -> Cosmetic? { all.first { $0.id == id } }

    // MARK: Mapping id -> apparence

    static func outfitColors(_ id: String) -> (shirt: UIColor, pants: UIColor, skin: UIColor) {
        func c(_ h: UInt32) -> UIColor { UIColor(hex: h) }
        switch id {
        case "outfit_crimson": return (c(0xC0392B), c(0x7A241B), Pal.heroSkin)
        case "outfit_forest":  return (c(0x2E8B57), c(0x1F5E3A), Pal.heroSkin)
        case "outfit_ocean":   return (c(0x2E6EA8), c(0x1E4A70), Pal.heroSkin)
        case "outfit_teal":    return (c(0x2E9E8E), c(0x274A57), Pal.heroSkin)
        case "outfit_sunset":  return (c(0xE8804E), c(0xB4552E), Pal.heroSkin)
        case "outfit_candy":   return (c(0xE86BA0), c(0xB0407A), Pal.heroSkin)
        case "outfit_mint":    return (c(0x6BD0B0), c(0x3E9E8A), Pal.heroSkin)
        case "outfit_shadow":  return (c(0x3A3A46), c(0x22222A), Pal.heroSkin)
        case "outfit_royal":   return (c(0x7A3E9E), c(0x37305A), Pal.heroSkin)
        case "outfit_gold":    return (c(0xF4C430), c(0xB58A1E), Pal.heroSkin)
        default:               return (Pal.heroShirt, Pal.heroPants, Pal.heroSkin)   // classic
        }
    }
    static func hat(_ id: String) -> HeroSkin.Hat {
        func c(_ h: UInt32) -> UIColor { UIColor(hex: h) }
        switch id {
        case "hat_band":        return .band(c(0xC0392B))
        case "hat_band_gold":   return .band(c(0xF4C430))
        case "hat_band_purple": return .band(c(0x7A3E9E))
        case "hat_cap":         return .cap(c(0x2E6EA8))
        case "hat_cap_red":     return .cap(c(0xC0392B))
        case "hat_cap_green":   return .cap(c(0x2E8B57))
        case "hat_beanie":      return .beanie(c(0x8A5AC0))
        case "hat_crown":       return .crown
        case "hat_cowboy":      return .cowboy
        default: return .none
        }
    }

    /// Construit l'apparence à partir des cosmétiques équipés (un skin complet écrase tenue+chapeau).
    static func heroSkin(outfit: String, hat hatID: String, skin: String?) -> HeroSkin {
        if let s = skin {
            let body: HeroSkin.Body
            switch s {
            case "skin_dragon": body = .dragon
            case "skin_robot":  body = .robot
            case "skin_ghost":  body = .ghost
            case "skin_cat":    body = .cat
            default:            body = .robot
            }
            return HeroSkin(body: body, hat: .none)
        }
        let c = outfitColors(outfit)
        return HeroSkin(body: .human(shirt: c.shirt, pants: c.pants, skin: c.skin), hat: hat(hatID))
    }
}
