import SwiftUI
import SpriteKit

struct ShopView: View {
    @Bindable var model: AppModel
    var store: Store?
    @Binding var route: RootView.Route
    @State private var tab: Tab
    @State private var preview: Cosmetic?      // item survolé/cliqué → aperçu sur le perso

    enum Tab: String, CaseIterable { case lives = "Vies", coins = "Pièces", biomes = "Biomes", gadgets = "Gadgets", outfits = "Tenues", hats = "Chapeaux", skins = "Skins" }

    init(model: AppModel, store: Store?, route: Binding<RootView.Route>, initialTab: Tab = .lives) {
        self._model = Bindable(model)
        self.store = store
        self._route = route
        self._tab = State(initialValue: initialTab)
    }

    private func productID(_ cosmeticID: String) -> String? {
        switch cosmeticID {
        case "skin_dragon": return Store.skinDragon
        case "skin_robot":  return Store.skinRobot
        case "skin_ghost":  return Store.skinGhost
        default: return nil
        }
    }
    private func buy(_ id: String) { Task { await store?.purchase(id) } }

    var body: some View {
        ZStack {
            UI.bg.ignoresSafeArea()
            VStack(spacing: 12) {
                header
                tabBar
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 12) {
                        switch tab {
                        case .lives: livesTab
                        case .coins: coinsTab
                        case .biomes: biomesTab
                        case .gadgets: gadgetsTab
                        case .outfits: cosmeticTab(Cosmetics.outfits)
                        case .hats: cosmeticTab(Cosmetics.hats)
                        case .skins: cosmeticTab(Cosmetics.skins)
                        }
                    }
                    .padding(.bottom, 12)
                }
            }
            .frame(maxWidth: 620)
            .frame(maxWidth: .infinity)
            .safeInsets()
        }
        .onChange(of: tab) { _, _ in preview = nil }   // repart de l'apparence équipée à chaque onglet
    }

    private var header: some View {
        HStack {
            Button { route = .home } label: {
                Image(systemName: "chevron.left").font(.system(size: 20, weight: .bold)).foregroundStyle(UI.text).padding(10)
            }
            Spacer()
            Text("Boutique").font(.system(size: 22, weight: .heavy, design: .rounded)).foregroundStyle(UI.text)
            Spacer()
            HStack(spacing: 12) {
                Label("\(model.coins)", systemImage: "circle.circle.fill").foregroundStyle(UI.coin)
                Label("\(model.lives)", systemImage: "heart.fill").foregroundStyle(UI.life)
            }
            .font(.system(size: 15, weight: .bold, design: .rounded))
            .padding(.horizontal, 12).padding(.vertical, 7).background(UI.bg2, in: Capsule())
        }
    }

    /// Onglets en pastilles (texte blanc quand non sélectionné → toujours lisible sur fond sombre).
    private var tabBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(Tab.allCases, id: \.self) { t in
                    let sel = tab == t
                    Button { tab = t } label: {
                        Text(t.rawValue)
                            .font(.system(size: 15, weight: .bold, design: .rounded))
                            .foregroundStyle(sel ? UI.bg : UI.text)
                            .padding(.horizontal, 16).padding(.vertical, 9)
                            .background(sel ? UI.cta : UI.bg2, in: Capsule())
                    }
                }
            }.padding(.horizontal, 2)
        }
    }

    // MARK: Vies

    private var livesTab: some View {
        VStack(spacing: 12) {
            row(title: "1 vie", subtitle: "Revivre sans repartir de zéro", trailing: "\(AppModel.reviveCost) ◉",
                enabled: model.coins >= AppModel.reviveCost, highlight: false) { model.buyOneLifeWithCoins() }
            row(title: "Pack 10 vies", subtitle: "La meilleure valeur",
                trailing: store?.priceLabel(Store.lives10, fallback: AppModel.tenLivesPriceLabel) ?? AppModel.tenLivesPriceLabel,
                enabled: true, highlight: true) { buy(Store.lives10) }
            note("Les vies servent à revivre après une chute. Les pièces se gagnent en jouant.")
        }
    }

    // MARK: Pièces (packs en argent réel)

    private var coinsTab: some View {
        VStack(spacing: 12) {
            ForEach(Store.coinPacks) { pack in
                HStack {
                    Text("🪙").font(.system(size: 26)).frame(width: 40)
                    VStack(alignment: .leading, spacing: 3) {
                        Text("\(pack.coins) pièces").font(.system(size: 17, weight: .heavy, design: .rounded)).foregroundStyle(UI.text)
                        Text(pack.id == Store.coinsXL ? "Meilleure valeur" : "Pack de pièces")
                            .font(.system(size: 13, weight: .medium, design: .rounded)).foregroundStyle(UI.sub)
                    }
                    Spacer()
                    pill(store?.priceLabel(pack.id, fallback: pack.price) ?? pack.price,
                         bg: UI.cta, fg: UI.bg, disabled: false) { buy(pack.id) }
                }
                .padding(14).background(UI.bg2, in: RoundedRectangle(cornerRadius: 16))
            }
            note("Les pièces achetées se dépensent sur tout : tenues, chapeaux, gadgets, biomes, vies.")
        }
    }

    // MARK: Biomes (déblocage : pièces OU achat réel)

    private var biomesTab: some View {
        VStack(spacing: 12) {
            ForEach(Biome.all) { b in biomeRow(b) }
            note("Western et Désert sont offerts. Les autres se débloquent en pièces (montant élevé) OU en achat réel.")
        }
    }

    @ViewBuilder private func biomeRow(_ b: Biome) -> some View {
        let owned = model.biomeUnlocked(b.id)
        let selected = owned && model.selectedBiomeID == b.id
        HStack(spacing: 12) {
            RoundedRectangle(cornerRadius: 10)
                .fill(LinearGradient(colors: [Color(uiColor: b.skyStops.first?.1 ?? .gray),
                                              Color(uiColor: b.skyStops.last?.1 ?? .gray),
                                              Color(uiColor: b.groundTop)],
                                     startPoint: .top, endPoint: .bottom))
                .frame(width: 60, height: 40)
                .overlay(RoundedRectangle(cornerRadius: 10).stroke(.white.opacity(0.15), lineWidth: 1))
            VStack(alignment: .leading, spacing: 3) {
                Text(b.name).font(.system(size: 17, weight: .heavy, design: .rounded)).foregroundStyle(UI.text)
                Text(biomeSubtitle(b, owned: owned, selected: selected))
                    .font(.system(size: 12, weight: .medium, design: .rounded)).foregroundStyle(UI.sub)
            }
            Spacer(minLength: 4)
            biomeAction(b, owned: owned, selected: selected)
        }
        .padding(12)
        .background(UI.bg2, in: RoundedRectangle(cornerRadius: 16))
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(selected ? UI.cta : .clear, lineWidth: 1.5))
    }

    private func biomeSubtitle(_ b: Biome, owned: Bool, selected: Bool) -> String {
        if selected { return "Sélectionné" }
        if owned { return "Débloqué" }
        if case .locked = b.unlock { return "Pièces ou achat" }
        return "Offert"
    }

    @ViewBuilder private func biomeAction(_ b: Biome, owned: Bool, selected: Bool) -> some View {
        if selected {
            pill("Choisi", bg: UI.bg, fg: UI.cta, disabled: true) {}
        } else if owned {
            pill("Choisir", bg: UI.cta, fg: UI.bg, disabled: false) { model.selectBiome(b.id) }
        } else if case .locked(let n, let product, let money) = b.unlock {
            VStack(spacing: 6) {
                pill("\(n) ◉", bg: n <= model.coins ? UI.cta : UI.bg, fg: n <= model.coins ? UI.bg : UI.sub,
                     disabled: n > model.coins) { if model.buyBiomeWithCoins(b) { model.selectBiome(b.id) } }
                pill(store?.priceLabel(product, fallback: money) ?? money, bg: UI.bg2, fg: UI.text, disabled: false) {
                    buy(product)
                }
            }
        }
    }

    // MARK: Gadgets

    private var gadgetsTab: some View {
        VStack(spacing: 12) {
            ForEach(Gadgets.all) { g in
                let owned = model.hasGadget(g.id)
                HStack {
                    Image(systemName: g.icon).font(.system(size: 22)).foregroundStyle(UI.cta).frame(width: 30)
                    VStack(alignment: .leading, spacing: 3) {
                        Text(g.name).font(.system(size: 17, weight: .heavy, design: .rounded)).foregroundStyle(UI.text)
                        Text(g.desc).font(.system(size: 13, weight: .medium, design: .rounded)).foregroundStyle(UI.sub)
                    }
                    Spacer()
                    if owned { pill("Actif", bg: UI.bg, fg: UI.cta, disabled: true) {} }
                    else {
                        VStack(spacing: 6) {
                            pill("\(g.price) ◉", bg: g.price <= model.coins ? UI.cta : UI.bg,
                                 fg: g.price <= model.coins ? UI.bg : UI.sub, disabled: g.price > model.coins) { model.buyGadget(g) }
                            pill(store?.priceLabel(Store.directProduct(g.id), fallback: Store.directLabel(forCoins: g.price)) ?? Store.directLabel(forCoins: g.price),
                                 bg: UI.bg2, fg: UI.text, disabled: false) { buy(Store.directProduct(g.id)) }
                        }
                    }
                }
                .padding(14).background(UI.bg2, in: RoundedRectangle(cornerRadius: 16))
            }
            note("Les gadgets sont permanents et actifs à chaque partie.")
        }
    }

    // MARK: Cosmétiques (avec aperçu sur le perso)

    private func cosmeticTab(_ items: [Cosmetic]) -> some View {
        VStack(spacing: 12) {
            heroPreviewPanel
            ForEach(items) { c in cosmeticRow(c) }
            note("Touche un article pour l'essayer sur le perso, puis achète / équipe.")
        }
    }

    /// Aperçu du coureur avec l'article cliqué (ou l'apparence équipée par défaut).
    private var heroPreviewPanel: some View {
        HeroPreview(skin: previewSkin(), changeKey: previewKey)
            .frame(height: 150).frame(maxWidth: .infinity)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay(alignment: .bottomLeading) {
                Text(preview?.name ?? "Équipé")
                    .font(.system(size: 12, weight: .bold, design: .rounded)).foregroundStyle(UI.sub)
                    .padding(10)
            }
    }
    private func previewSkin() -> HeroSkin {
        guard let c = preview else { return model.currentSkin() }
        switch c.kind {
        case .outfit: return Cosmetics.heroSkin(outfit: c.id, hat: model.equippedHat, skin: nil)
        case .hat:    return Cosmetics.heroSkin(outfit: model.equippedOutfit, hat: c.id, skin: nil)
        case .skin:   return Cosmetics.heroSkin(outfit: model.equippedOutfit, hat: model.equippedHat, skin: c.id)
        }
    }
    private var previewKey: String {
        preview?.id ?? "eq-\(model.equippedOutfit)-\(model.equippedHat)-\(model.equippedSkinID ?? "")"
    }

    @ViewBuilder private func cosmeticRow(_ c: Cosmetic) -> some View {
        let owned = model.owns(c.id)
        let equipped = model.isEquipped(c)
        let isPreview = preview?.id == c.id
        HStack(spacing: 8) {
            // Zone gauche = aperçu sur le perso (bouton distinct, ne bloque pas l'achat).
            Button { preview = c } label: {
                HStack {
                    Text(icon(c)).font(.system(size: 26)).frame(width: 40)
                    VStack(alignment: .leading, spacing: 3) {
                        Text(c.name).font(.system(size: 17, weight: .heavy, design: .rounded)).foregroundStyle(UI.text)
                        Text(priceText(c)).font(.system(size: 13, weight: .medium, design: .rounded)).foregroundStyle(UI.sub)
                    }
                    Spacer(minLength: 0)
                }
                .contentShape(Rectangle())
            }.buttonStyle(.plain)
            action(c, owned: owned, equipped: equipped)
        }
        .padding(14)
        .background(UI.bg2, in: RoundedRectangle(cornerRadius: 16))
        .overlay(RoundedRectangle(cornerRadius: 16)
            .stroke(equipped ? UI.cta : (isPreview ? UI.cta.opacity(0.5) : .clear), lineWidth: 1.5))
    }

    @ViewBuilder private func action(_ c: Cosmetic, owned: Bool, equipped: Bool) -> some View {
        if equipped {
            pill("Équipé", bg: UI.bg, fg: UI.cta, disabled: true) {}
        } else if owned {
            pill("Équiper", bg: UI.cta, fg: UI.bg, disabled: false) { model.equip(c) }
        } else {
            switch c.price {
            case .coins(let n):
                // Payable en pièces OU directement en argent réel.
                VStack(spacing: 6) {
                    pill("\(n) ◉", bg: n <= model.coins ? UI.cta : UI.bg, fg: n <= model.coins ? UI.bg : UI.sub,
                         disabled: n > model.coins) { if model.buyWithCoins(c) { model.equip(c) } }
                    pill(store?.priceLabel(Store.directProduct(c.id), fallback: Store.directLabel(forCoins: n)) ?? Store.directLabel(forCoins: n),
                         bg: UI.bg2, fg: UI.text, disabled: false) { buy(Store.directProduct(c.id)) }
                }
            case .money(let label):
                let pid = productID(c.id)
                pill(store?.priceLabel(pid ?? "", fallback: label) ?? label, bg: UI.cta, fg: UI.bg, disabled: false) {
                    if let pid { buy(pid) }
                }
            }
        }
    }

    // MARK: Petits composants

    private func pill(_ t: String, bg: Color, fg: Color, disabled: Bool, _ act: @escaping () -> Void) -> some View {
        Button(action: act) {
            Text(t).font(.system(size: 15, weight: .heavy, design: .rounded)).foregroundStyle(fg)
                .padding(.horizontal, 16).padding(.vertical, 9).background(bg, in: Capsule())
        }.disabled(disabled)
    }

    private func row(title: String, subtitle: String, trailing: String, enabled: Bool, highlight: Bool,
                     _ act: @escaping () -> Void) -> some View {
        Button(action: act) {
            HStack {
                VStack(alignment: .leading, spacing: 3) {
                    Text(title).font(.system(size: 18, weight: .heavy, design: .rounded)).foregroundStyle(UI.text)
                    Text(subtitle).font(.system(size: 13, weight: .medium, design: .rounded)).foregroundStyle(UI.sub)
                }
                Spacer()
                Text(trailing).font(.system(size: 16, weight: .heavy, design: .rounded))
                    .foregroundStyle(highlight ? UI.bg : UI.text)
                    .padding(.horizontal, 14).padding(.vertical, 8).background(highlight ? UI.cta : UI.bg, in: Capsule())
            }
            .padding(16).background(UI.bg2, in: RoundedRectangle(cornerRadius: 18))
            .opacity(enabled ? 1 : 0.5)
        }.disabled(!enabled)
    }

    private func note(_ t: String) -> some View {
        Text(t).font(.system(size: 13, weight: .medium, design: .rounded))
            .foregroundStyle(UI.sub).multilineTextAlignment(.center).padding(.top, 6)
    }

    private func icon(_ c: Cosmetic) -> String {
        switch c.id {
        case "skin_dragon": return "🐉"; case "skin_robot": return "🤖"; case "skin_ghost": return "👻"; case "skin_cat": return "🐱"
        case "hat_cowboy": return "🤠"; case "hat_cap", "hat_cap_red", "hat_cap_green": return "🧢"
        case "hat_crown": return "👑"; case "hat_band", "hat_band_gold", "hat_band_purple": return "🎗️"; case "hat_beanie": return "🧶"
        case "outfit_gold": return "🟡"; case "outfit_royal": return "🟣"; case "outfit_teal", "outfit_mint": return "🟢"
        case "outfit_ocean": return "🔵"; case "outfit_crimson": return "🔴"; case "outfit_candy": return "🩷"
        case "outfit_sunset": return "🟠"; case "outfit_shadow": return "⚫️"; case "outfit_forest": return "🌲"
        default: return "👕"
        }
    }
    private func priceText(_ c: Cosmetic) -> String {
        if model.isEquipped(c) { return "Équipé" }
        if model.owns(c.id) { return "Possédé" }
        switch c.price { case .coins(let n): return n == 0 ? "Gratuit" : "\(n) pièces"; case .money(let l): return l }
    }
}

// MARK: - Aperçu du coureur (SpriteKit)

/// Rend un `HeroNode` seul, centré et animé, pour prévisualiser un cosmétique.
final class HeroPreviewScene: SKScene {
    private let container = SKNode()
    var skin: HeroSkin = .base { didSet { rebuild() } }

    override init(size: CGSize) {
        super.init(size: size)
        scaleMode = .resizeFill
        backgroundColor = UIColor(hex: 0x2A2436)      // « présentoir » assorti au panneau
        addChild(container)                            // tout construit dès l'init (pas de dépendance à didMove)
        reposition()
        rebuild()
    }
    required init?(coder: NSCoder) { fatalError() }

    override func didChangeSize(_ oldSize: CGSize) { super.didChangeSize(oldSize); reposition() }

    private func reposition() {
        container.position = CGPoint(x: size.width / 2, y: max(18, size.height * 0.14))
    }

    private func rebuild() {
        container.removeAllChildren()
        let hero = HeroNode(skin: skin)
        hero.setScale(1.3)
        container.addChild(hero)
        reposition()
    }
}

struct HeroPreview: View {
    let skin: HeroSkin
    let changeKey: String
    @State private var scene = HeroPreviewScene(size: CGSize(width: 220, height: 160))

    var body: some View {
        SpriteView(scene: scene)
            .onAppear { scene.skin = skin }
            .onChange(of: changeKey) { _, _ in scene.skin = skin }
    }
}
