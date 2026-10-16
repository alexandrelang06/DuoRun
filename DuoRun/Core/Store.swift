import StoreKit

/// Achats intégrés (StoreKit 2). Produits : pack 10 vies (consommable) + skins Dragon/Robot
/// (non-consommables, Family Sharing). Écoute `Transaction.updates`, octroie à l'achat, restaure.
/// NB : les achats ne se testent que dans Xcode (config `DuoRun.storekit` via le scheme).
@MainActor
@Observable
final class Store {
    var products: [Product] = []
    var purchasing: String?
    private var updatesTask: Task<Void, Never>?
    private let model: AppModel

    static let lives10 = "com.duorun.lives10"
    static let skinDragon = "com.duorun.skin_dragon"
    static let skinRobot = "com.duorun.skin_robot"
    static let skinGhost = "com.duorun.skin_ghost"
    static let biomeJungle = "com.duorun.biome_jungle"
    static let biomeNeon = "com.duorun.biome_neon"
    static let biomeSnow = "com.duorun.biome_snow"
    static let biomeSpace = "com.duorun.biome_space"
    // Packs de pièces (argent réel → pièces, dépensables sur tout).
    static let coinsS = "com.duorun.coins_1200"
    static let coinsM = "com.duorun.coins_5000"
    static let coinsL = "com.duorun.coins_14000"
    static let coinsXL = "com.duorun.coins_40000"
    static let ids = [lives10, skinDragon, skinRobot, skinGhost, biomeJungle, biomeNeon, biomeSnow, biomeSpace,
                      coinsS, coinsM, coinsL, coinsXL]

    /// Pack de pièces affiché en boutique.
    struct CoinPack: Identifiable { let id: String; let coins: Int; let price: String }
    static let coinPacks: [CoinPack] = [
        .init(id: coinsS,  coins: 2000,  price: "0,99 €"),
        .init(id: coinsM,  coins: 6500,  price: "2,99 €"),
        .init(id: coinsL,  coins: 16000, price: "6,99 €"),
        .init(id: coinsXL, coins: 36000, price: "14,99 €"),
    ]

    /// Préfixe des produits « achat direct d'un article en argent réel » (un produit par article).
    static let directPrefix = "com.duorun.buy."
    static func directProduct(_ itemID: String) -> String { directPrefix + itemID }
    /// Palier de prix indicatif pour l'achat direct d'un article coûtant `coins` pièces.
    static func directLabel(forCoins coins: Int) -> String {
        switch coins {          // ~2000 pièces = 1 €
        case ..<1400:  return "0,99 €"
        case ..<3000:  return "1,49 €"
        case ..<4600:  return "1,99 €"
        case ..<6600:  return "2,99 €"
        case ..<9000:  return "3,99 €"
        case ..<13000: return "5,99 €"
        default:       return "9,99 €"
        }
    }

    /// Table produit → octroi.
    static func grant(_ productID: String, to model: AppModel) {
        // Achat direct d'un article : com.duorun.buy.<itemID> → octroie le cosmétique ou le gadget.
        if productID.hasPrefix(directPrefix) {
            let itemID = String(productID.dropFirst(directPrefix.count))
            if itemID.hasPrefix("g_") { model.grantGadget(itemID) } else { model.grantCosmetic(itemID) }
            return
        }
        switch productID {
        case lives10: model.grantTenLives()
        case skinDragon: model.grantCosmetic("skin_dragon")
        case skinRobot: model.grantCosmetic("skin_robot")
        case skinGhost: model.grantCosmetic("skin_ghost")
        case biomeJungle: model.grantBiome("jungle")
        case biomeNeon: model.grantBiome("neon")
        case biomeSnow: model.grantBiome("snow")
        case biomeSpace: model.grantBiome("space")
        case coinsS: model.addCoins(2000)
        case coinsM: model.addCoins(6500)
        case coinsL: model.addCoins(16000)
        case coinsXL: model.addCoins(36000)
        default: break
        }
    }

    init(model: AppModel) {
        self.model = model
        updatesTask = Task { [weak self] in
            for await result in Transaction.updates { await self?.handle(result) }
        }
        Task { await load() }
    }

    func load() async { products = (try? await Product.products(for: Self.ids)) ?? [] }
    func product(_ id: String) -> Product? { products.first { $0.id == id } }

    /// Prix affichable (localisé) si chargé, sinon un repli.
    func priceLabel(_ id: String, fallback: String) -> String { product(id)?.displayPrice ?? fallback }

    func purchase(_ id: String) async {
        guard let p = product(id) else {
            // Pas de StoreKit chargé (simulateur lancé hors Xcode) : en DEBUG on simule l'achat pour
            // pouvoir tester le flux. En build App Store, un vrai produit est toujours présent.
            #if DEBUG
            Self.grant(id, to: model)
            #endif
            return
        }
        purchasing = id; defer { purchasing = nil }
        guard let result = try? await p.purchase() else { return }
        switch result {
        case .success(let verification):
            if case .verified(let t) = verification {
                Self.grant(t.productID, to: model)
                await t.finish()
            }
        default: break
        }
    }

    private func handle(_ result: VerificationResult<Transaction>) async {
        if case .verified(let t) = result {
            Self.grant(t.productID, to: model)
            await t.finish()
        }
    }

    func restore() async { try? await AppStore.sync() }
}
