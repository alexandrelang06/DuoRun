import SwiftUI

/// Racine de l'app : accueil ↔ jeu ↔ boutique. Un seul `AppModel` (portefeuille, vies, temps de jeu)
/// partagé partout. Design menu sombre chaleureux (PRD §9).
struct RootView: View {
    enum Route { case home, game, shop }
    @State private var model = AppModel()
    @State private var store: Store?
    @State private var route: Route = .home
    @State private var shopTab: ShopView.Tab = .lives

    var body: some View {
        ZStack {
            switch route {
            case .home: HomeView(model: model, route: $route, shopTab: $shopTab)
            case .game: GameContainerView(model: model, route: $route)
            case .shop: ShopView(model: model, store: store, route: $route, initialTab: shopTab)
            }
        }
        .animation(.easeInOut(duration: 0.2), value: route)
        .task {
            if store == nil { store = Store(model: model) }
            GameCenter.shared.authenticate()
            SoundManager.shared.startMusic()
            if ProcessInfo.processInfo.environment["DBG_SHOT"] != nil { route = .game }   // TEMP-SHOT
        }
    }
}

/// Marges de sécurité : respecte l'encoche / la caméra (Dynamic Island) sur tous les appareils —
/// crucial en paysage où la zone protégée est sur un côté. Garantit au moins `min` de marge partout.
struct SafeInsets: ViewModifier {
    var min: CGFloat = 16
    func body(content: Content) -> some View {
        GeometryReader { geo in
            content.padding(EdgeInsets(
                top: Swift.max(min, geo.safeAreaInsets.top),
                leading: Swift.max(min, geo.safeAreaInsets.leading),
                bottom: Swift.max(min, geo.safeAreaInsets.bottom),
                trailing: Swift.max(min, geo.safeAreaInsets.trailing)))
        }
        .ignoresSafeArea()
    }
}
extension View {
    func safeInsets(min: CGFloat = 16) -> some View { modifier(SafeInsets(min: min)) }
}

/// Palette UI (menu / boutique).
enum UI {
    static let bg = Color(hex: 0x1E1A26)
    static let bg2 = Color(hex: 0x2A2436)
    static let cta = Color(hex: 0xF4C430)
    static let text = Color(hex: 0xFBF7F0)
    static let sub = Color(hex: 0xB9B2C7)
    static let coin = Color(hex: 0xF4C430)
    static let life = Color(hex: 0xFF6B6B)
}
