import SwiftUI

/// État persistant du joueur : portefeuille de pièces, stock de vies, temps de jeu cumulé, mode
/// choisi. Tout est local (UserDefaults), hors-ligne, conforme au portefeuille F2P « propre » du PRD.
@MainActor
@Observable
final class AppModel {
    var coins: Int { didSet { save() } }
    var lives: Int { didSet { save() } }
    var totalPlaySeconds: Double
    var mode: GameMode = .duo

    // Cosmétiques
    var ownedCosmetics: Set<String> { didSet { saveCosmetics() } }
    var equippedOutfit: String { didSet { d.set(equippedOutfit, forKey: "duorun.outfit") } }
    var equippedHat: String { didSet { d.set(equippedHat, forKey: "duorun.hat") } }
    var equippedSkinID: String? { didSet { d.set(equippedSkinID, forKey: "duorun.skin") } }
    var selectedBiomeID: String { didSet { d.set(selectedBiomeID, forKey: "duorun.biome") } }

    // Missions / progression / coffre du jour
    var stars: Int { didSet { d.set(stars, forKey: "duorun.stars") } }
    var missions: [Mission] { didSet { saveMissions() } }
    var lastChestDay: String { didSet { d.set(lastChestDay, forKey: "duorun.chestDay") } }
    var ownedGadgets: Set<String> { didSet { d.set(Array(ownedGadgets), forKey: "duorun.gadgets") } }
    /// Meilleure distance (m) jamais atteinte — sert de record affiché en fin de partie.
    var bestDistanceM: Int { didSet { d.set(bestDistanceM, forKey: "duorun.best") } }
    /// Biomes débloqués (Western + Désert offerts ; les autres s'achètent en pièces ou en argent réel).
    var ownedBiomes: Set<String> { didSet { d.set(Array(ownedBiomes), forKey: "duorun.biomes") } }
    static let freeBiomes: Set<String> = ["western", "desert"]

    /// Une réanimation coûte cher : il faut jouer longtemps (~20 min) pour se l'offrir en pièces.
    static let reviveCost = 2000
    /// Prix indicatif du pack (achat réel, câblé plus tard via StoreKit 2).
    static let tenLivesPriceLabel = "4,99 €"

    private let d = UserDefaults.standard
    private var lastPlaytimeSave: Double = 0

    init() {
        coins = d.integer(forKey: "duorun.coins")
        lives = d.integer(forKey: "duorun.lives")
        totalPlaySeconds = d.double(forKey: "duorun.playSeconds")
        var owned = Set(d.stringArray(forKey: "duorun.owned") ?? [])
        owned.formUnion(Cosmetics.freeDefaults)   // les items gratuits sont toujours possédés
        ownedCosmetics = owned
        equippedOutfit = d.string(forKey: "duorun.outfit") ?? "outfit_classic"
        equippedHat = d.string(forKey: "duorun.hat") ?? "hat_cowboy"
        equippedSkinID = d.string(forKey: "duorun.skin")
        selectedBiomeID = d.string(forKey: "duorun.biome") ?? "western"
        stars = d.integer(forKey: "duorun.stars")
        if let data = d.data(forKey: "duorun.missions"),
           let m = try? JSONDecoder().decode([Mission].self, from: data), m.count == 3 {
            missions = m
        } else {
            missions = Missions.freshSet()
        }
        lastChestDay = d.string(forKey: "duorun.chestDay") ?? ""
        ownedGadgets = Set(d.stringArray(forKey: "duorun.gadgets") ?? [])
        bestDistanceM = d.integer(forKey: "duorun.best")
        var biomes = Set(d.stringArray(forKey: "duorun.biomes") ?? [])
        biomes.formUnion(Self.freeBiomes)
        ownedBiomes = biomes
        if !ownedBiomes.contains(selectedBiomeID) { selectedBiomeID = "western" }   // sécurité : jamais bloqué
        // Cadeau de bienvenue : 3 vies offertes au tout premier lancement.
        if !d.bool(forKey: "duorun.bootstrapped") {
            lives = 3
            d.set(true, forKey: "duorun.bootstrapped")
        }
        saveMissions()
    }

    // MARK: Gadgets permanents

    func hasGadget(_ id: String) -> Bool { ownedGadgets.contains(id) }
    @discardableResult func buyGadget(_ g: Gadget) -> Bool {
        guard !hasGadget(g.id), coins >= g.price else { return false }
        coins -= g.price; ownedGadgets.insert(g.id); return true
    }
    /// Octroi après achat réel (IAP direct) d'un gadget.
    func grantGadget(_ id: String) { ownedGadgets.insert(id) }
    /// Durée de l'aimant (rallongée par le gadget dédié).
    var magnetDuration: Double { hasGadget("g_magnet") ? 12 : 8 }

    func selectedBiome() -> Biome { Biome.byID(selectedBiomeID) }

    // MARK: Biomes (déblocage)

    func biomeUnlocked(_ id: String) -> Bool { ownedBiomes.contains(id) }
    /// Achat d'un biome en pièces (option « grind », montant élevé). false si déjà possédé ou fonds
    /// insuffisants.
    @discardableResult func buyBiomeWithCoins(_ b: Biome) -> Bool {
        guard !biomeUnlocked(b.id), case .locked(let n, _, _) = b.unlock, coins >= n else { return false }
        coins -= n; ownedBiomes.insert(b.id); return true
    }
    /// Octroi après achat réel (IAP) — appelé par StoreKit.
    func grantBiome(_ id: String) { ownedBiomes.insert(id) }
    /// Sélectionne un biome s'il est débloqué. Renvoie false s'il est encore verrouillé.
    @discardableResult func selectBiome(_ id: String) -> Bool {
        guard biomeUnlocked(id) else { return false }
        selectedBiomeID = id; return true
    }

    /// Enregistre la distance d'une partie ; renvoie true si c'est un nouveau record personnel.
    @discardableResult func recordDistance(_ m: Int) -> Bool {
        guard m > bestDistanceM else { return false }
        bestDistanceM = m
        return true
    }

    // MARK: Missions / progression

    var level: Int { 1 + stars / 8 }
    private func saveMissions() {
        if let data = try? JSONEncoder().encode(missions) { d.set(data, forKey: "duorun.missions") }
    }

    /// Fait progresser les missions du type donné. Renvoie celles qui viennent d'être complétées
    /// (pour l'affichage) ; chaque mission finie octroie ses pièces + étoiles et est remplacée.
    @discardableResult func addMissionProgress(_ kind: MissionKind, _ amount: Int) -> [Mission] {
        guard amount > 0 else { return [] }
        var completed: [Mission] = []
        for i in missions.indices where missions[i].kind == kind && !missions[i].done {
            missions[i].progress += amount
            if missions[i].done {
                coins += missions[i].reward
                stars += missions[i].stars
                completed.append(missions[i])
                let used = Set(missions.map { $0.kind })
                missions[i] = Missions.random(excluding: used)
            }
        }
        return completed
    }

    // MARK: Coffre du jour

    private static func today() -> String {
        let f = DateFormatter(); f.dateFormat = "yyyy-MM-dd"; f.locale = Locale(identifier: "en_US_POSIX")
        return f.string(from: Date())
    }
    var canClaimChest: Bool { lastChestDay != Self.today() }
    @discardableResult func claimDailyChest() -> Int {
        guard canClaimChest else { return 0 }
        lastChestDay = Self.today()
        let reward = Int.random(in: 150...400)
        coins += reward
        return reward
    }

    private func save() {
        d.set(coins, forKey: "duorun.coins")
        d.set(lives, forKey: "duorun.lives")
    }
    private func saveCosmetics() { d.set(Array(ownedCosmetics), forKey: "duorun.owned") }

    // MARK: Cosmétiques

    func owns(_ id: String) -> Bool { ownedCosmetics.contains(id) }

    /// Achat en pièces (les basiques). Renvoie false si déjà possédé ou pas assez de pièces.
    @discardableResult func buyWithCoins(_ c: Cosmetic) -> Bool {
        guard !owns(c.id), case .coins(let n) = c.price, coins >= n else { return false }
        coins -= n; ownedCosmetics.insert(c.id); return true
    }
    /// Octroi après achat réel (IAP) — le câblage StoreKit remplira ceci.
    func grantCosmetic(_ id: String) { ownedCosmetics.insert(id) }

    /// Équipe un cosmétique possédé. Un skin complet écrase tenue+chapeau ; équiper une tenue/chapeau
    /// retire le skin complet.
    func equip(_ c: Cosmetic) {
        guard owns(c.id) else { return }
        switch c.kind {
        case .outfit: equippedOutfit = c.id; equippedSkinID = nil
        case .hat:    equippedHat = c.id; equippedSkinID = nil
        case .skin:   equippedSkinID = c.id
        }
    }
    func isEquipped(_ c: Cosmetic) -> Bool {
        switch c.kind {
        case .outfit: return equippedSkinID == nil && equippedOutfit == c.id
        case .hat:    return equippedSkinID == nil && equippedHat == c.id
        case .skin:   return equippedSkinID == c.id
        }
    }

    func currentSkin() -> HeroSkin {
        Cosmetics.heroSkin(outfit: equippedOutfit, hat: equippedHat, skin: equippedSkinID)
    }

    func addCoins(_ n: Int) { coins += n }

    func addPlaytime(_ s: Double) {
        totalPlaySeconds += s
        if totalPlaySeconds - lastPlaytimeSave > 5 {   // on ne persiste pas à chaque frame
            lastPlaytimeSave = totalPlaySeconds
            d.set(totalPlaySeconds, forKey: "duorun.playSeconds")
        }
    }

    // MARK: Réanimation

    var canRevive: Bool { lives > 0 || coins >= Self.reviveCost }
    /// Ce que coûtera la prochaine réanimation (pour l'affichage du bouton).
    enum ReviveCost { case oneLife, coins(Int), unaffordable }
    var nextReviveCost: ReviveCost {
        if lives > 0 { return .oneLife }
        if coins >= Self.reviveCost { return .coins(Self.reviveCost) }
        return .unaffordable
    }

    /// Consomme la ressource pour revivre (vie d'abord, sinon pièces). Renvoie false si impossible.
    @discardableResult func consumeRevive() -> Bool {
        if lives > 0 { lives -= 1; return true }
        if coins >= Self.reviveCost { coins -= Self.reviveCost; return true }
        return false
    }

    // MARK: Boutique

    @discardableResult func buyOneLifeWithCoins() -> Bool {
        guard coins >= Self.reviveCost else { return false }
        coins -= Self.reviveCost; lives += 1; return true
    }

    /// Pack de 10 vies via achat réel. Sans StoreKit encore : on accorde en attendant le câblage IAP.
    func grantTenLives() { lives += 10 }
}
