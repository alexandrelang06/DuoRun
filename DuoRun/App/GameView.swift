import SwiftUI
import SpriteKit

/// Détient une unique scène + son pont, câblés ensemble. Créé à chaque entrée en jeu (mode courant).
@MainActor @Observable
final class GameHost {
    let bridge: GameBridge
    let scene: GameScene
    init(model: AppModel) {
        bridge = GameBridge(model: model)
        scene = GameScene(size: CGSize(width: 852, height: 393))
        scene.scaleMode = .resizeFill
        scene.mode = model.mode
        scene.biome = model.selectedBiome()
        scene.bridge = bridge
        bridge.scene = scene
        if model.mode == .duo {          // écran de placement avant de démarrer à deux
            scene.started = false
            bridge.phase = .placement
        }
        if let s = ProcessInfo.processInfo.environment["DBG_SHOT"] {   // TEMP-SHOT
            scene.mode = s.contains("duo") ? .duo : .solo
            scene.started = true; bridge.phase = .playing
        }
    }
}

/// Hôte du jeu : la scène SpriteKit plein écran + le panneau de mort (pause pour les deux) en overlay.
struct GameContainerView: View {
    let model: AppModel
    @Binding var route: RootView.Route
    @State private var host: GameHost

    init(model: AppModel, route: Binding<RootView.Route>) {
        self.model = model
        self._route = route
        _host = State(initialValue: GameHost(model: model))
    }

    var body: some View {
        ZStack {
            SpriteView(scene: host.scene, options: [.ignoresSiblingOrder])
                .ignoresSafeArea()

            VStack {
                HStack {
                    Button { route = .home } label: {
                        Image(systemName: "house.fill")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundStyle(UI.text)
                            .padding(10).background(.black.opacity(0.35), in: Circle())
                    }
                    Spacer()
                }
                Spacer()
            }
            .safeInsets(min: 12)

            if host.bridge.phase == .placement {
                PlacementView(bridge: host.bridge)
            }
            if host.bridge.phase == .dead {
                DeathPanel(model: model, bridge: host.bridge, route: $route)
            }
        }
    }
}

/// Écran de placement duo : chaque joueur pose son pouce sur SA zone « Prêt » (celle du haut est
/// retournée pour le joueur d'en face). Quand les deux sont prêts, décompte 3-2-1 puis la partie démarre.
struct PlacementView: View {
    let bridge: GameBridge
    @State private var readyTop = false
    @State private var readyBottom = false
    @State private var count: Int? = nil

    var body: some View {
        GeometryReader { geo in
            ZStack {
                Color.black.opacity(0.6).ignoresSafeArea()
                VStack(spacing: 0) {
                    readyZone(top: true, ready: $readyTop).frame(height: geo.size.height / 2)
                    readyZone(top: false, ready: $readyBottom).frame(height: geo.size.height / 2)
                }
                if let c = count {
                    Text("\(c)").font(.system(size: 120, weight: .heavy, design: .rounded))
                        .foregroundStyle(UI.cta).shadow(radius: 8)
                }
            }
        }
        .onChange(of: readyTop) { _, _ in checkStart() }
        .onChange(of: readyBottom) { _, _ in checkStart() }
    }

    private func readyZone(top: Bool, ready: Binding<Bool>) -> some View {
        Button { ready.wrappedValue.toggle() } label: {
            VStack(spacing: 10) {
                Image(systemName: ready.wrappedValue ? "checkmark.circle.fill" : "hand.tap.fill")
                    .font(.system(size: 40))
                Text(ready.wrappedValue ? "Prêt !" : "Touche quand tu es prêt")
                    .font(.system(size: 20, weight: .heavy, design: .rounded))
                Text(top ? "Joueur du haut" : "Joueur du bas")
                    .font(.system(size: 13, weight: .medium, design: .rounded)).opacity(0.7)
            }
            .foregroundStyle(ready.wrappedValue ? UI.bg : UI.text)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(ready.wrappedValue ? UI.cta.opacity(0.85) : UI.bg2.opacity(0.85))
            .rotationEffect(top ? .degrees(180) : .zero)
        }
        .buttonStyle(.plain)
    }

    private func checkStart() {
        guard readyTop && readyBottom, count == nil else { return }
        count = 3
        func tick() {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) {
                if let c = count, c > 1 { count = c - 1; tick() }
                else { bridge.beginPlay() }
            }
        }
        tick()
    }
}

/// Panneau affiché quand un joueur tombe : la partie est en pause pour les deux.
struct DeathPanel: View {
    @Bindable var model: AppModel
    let bridge: GameBridge
    @Binding var route: RootView.Route

    var body: some View {
        ZStack {
            Color.black.opacity(0.55).ignoresSafeArea()
            GeometryReader { geo in
                card
                    .frame(maxWidth: 460)
                    .frame(maxHeight: geo.size.height)   // ne dépasse jamais l'écran
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
            }
            .safeInsets(min: 12)
        }
    }

    /// Carte de fin de partie / pause : infos qui défilent EN INTERNE, boutons épinglés en bas.
    /// La carte est bornée à la hauteur de l'écran → jamais de débordement, marges respectées.
    private var card: some View {
        VStack(spacing: 0) {
            ScrollView(showsIndicators: true) {
                VStack(spacing: 11) {
                    Text("Un coureur est tombé !")
                        .font(.system(size: 19, weight: .heavy, design: .rounded))
                        .foregroundStyle(UI.text).multilineTextAlignment(.center)

                    VStack(spacing: 2) {
                        Text("\(bridge.runDistanceM) m")
                            .font(.system(size: 27, weight: .heavy, design: .rounded)).foregroundStyle(UI.text)
                        if bridge.runIsRecord {
                            Text("🏆  Nouveau record !")
                                .font(.system(size: 13, weight: .heavy, design: .rounded)).foregroundStyle(UI.coin)
                                .padding(.horizontal, 10).padding(.vertical, 4)
                                .background(UI.coin.opacity(0.15), in: Capsule())
                        } else {
                            Text("Record : \(bridge.runBestM) m")
                                .font(.system(size: 12, weight: .semibold, design: .rounded)).foregroundStyle(UI.sub)
                        }
                    }

                    gainsBlock
                    if !bridge.runCompletedMissions.isEmpty { accomplishedBlock }
                    activeMissionsBlock
                }
                .padding(.horizontal, 18).padding(.top, 16).padding(.bottom, 10)
            }
            .overlay(alignment: .bottom) {   // léger dégradé : indique qu'on peut défiler pour voir les missions
                LinearGradient(colors: [UI.bg.opacity(0), UI.bg], startPoint: .top, endPoint: .bottom)
                    .frame(height: 16).allowsHitTesting(false)
            }

            VStack(spacing: 8) {   // boutons toujours visibles, en bas du panneau
                reviveButton
                Button { bridge.restart() } label: {
                    Text("Recommencer")
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundStyle(UI.text)
                        .frame(maxWidth: 300).padding(.vertical, 10)
                        .background(UI.bg2, in: Capsule())
                }
                HStack(spacing: 16) {
                    Button { route = .home } label: {
                        Text("Menu").font(.system(size: 14, weight: .semibold, design: .rounded))
                            .foregroundStyle(UI.sub)
                    }
                    walletLine
                }
            }
            .padding(.horizontal, 18).padding(.top, 8).padding(.bottom, 16)
        }
        .frame(maxWidth: 460)
        .background(UI.bg, in: RoundedRectangle(cornerRadius: 22))
    }

    /// Pièces gagnées cette partie : ramassées en courant + bonus des missions accomplies.
    private var gainsBlock: some View {
        VStack(spacing: 6) {
            Text("Pièces gagnées").font(.system(size: 12, weight: .heavy, design: .rounded))
                .foregroundStyle(UI.sub).frame(maxWidth: .infinity, alignment: .leading)
            HStack(spacing: 8) {
                gainTile(icon: "circle.circle.fill", amount: bridge.runCoins, label: "ramassées", tint: UI.coin)
                if bridge.runMissionCoins > 0 {
                    gainTile(icon: "checkmark.seal.fill", amount: bridge.runMissionCoins, label: "missions", tint: UI.cta)
                }
            }
        }
    }

    private func gainTile(icon: String, amount: Int, label: String, tint: Color) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon).font(.system(size: 18, weight: .bold)).foregroundStyle(tint)
            VStack(alignment: .leading, spacing: 1) {
                Text("+\(amount) ◉").font(.system(size: 17, weight: .heavy, design: .rounded)).foregroundStyle(UI.text)
                Text(label).font(.system(size: 11, weight: .medium, design: .rounded)).foregroundStyle(UI.sub)
            }
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 12).padding(.vertical, 9)
        .frame(maxWidth: .infinity)
        .background(UI.bg2, in: RoundedRectangle(cornerRadius: 12))
    }

    /// Missions accomplies pendant CETTE partie (mises en avant).
    private var accomplishedBlock: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Missions accomplies").font(.system(size: 12, weight: .heavy, design: .rounded))
                .foregroundStyle(UI.cta)
            ForEach(bridge.runCompletedMissions) { m in
                HStack(spacing: 8) {
                    Image(systemName: "checkmark.circle.fill").font(.system(size: 15)).foregroundStyle(UI.cta)
                    Text(m.text).font(.system(size: 12, weight: .semibold, design: .rounded)).foregroundStyle(UI.text)
                    Spacer(minLength: 0)
                    Text("+\(m.reward) ◉").font(.system(size: 12, weight: .heavy, design: .rounded)).foregroundStyle(UI.coin)
                }
            }
        }
        .padding(10).frame(maxWidth: .infinity)
        .background(UI.cta.opacity(0.12), in: RoundedRectangle(cornerRadius: 12))
    }

    /// Missions en cours (les 3 actives) avec leur progression — visibles dans l'écran de pause.
    private var activeMissionsBlock: some View {
        VStack(alignment: .leading, spacing: 7) {
            Text("Missions en cours").font(.system(size: 12, weight: .heavy, design: .rounded))
                .foregroundStyle(UI.sub)
            ForEach(model.missions) { m in
                HStack(spacing: 8) {
                    Image(systemName: m.icon).font(.system(size: 13, weight: .bold)).foregroundStyle(UI.cta).frame(width: 18)
                    VStack(alignment: .leading, spacing: 3) {
                        Text(m.text).font(.system(size: 12, weight: .semibold, design: .rounded)).foregroundStyle(UI.text)
                        ProgressView(value: Double(min(m.progress, m.target)), total: Double(m.target))
                            .tint(UI.cta).scaleEffect(x: 1, y: 0.8, anchor: .center)
                    }
                    Text("+\(m.reward) ◉").font(.system(size: 11, weight: .heavy, design: .rounded)).foregroundStyle(UI.coin)
                }
            }
        }
        .padding(10).frame(maxWidth: .infinity)
        .background(UI.bg2, in: RoundedRectangle(cornerRadius: 12))
    }

    @ViewBuilder private var reviveButton: some View {
        switch model.nextReviveCost {
        case .oneLife:
            reviveCTA(title: "Revivre  ·  1 vie ♥", enabled: true)
        case .coins(let c):
            reviveCTA(title: "Revivre  ·  \(c) ◉", enabled: true)
        case .unaffordable:
            VStack(spacing: 6) {
                reviveCTA(title: "Revivre  ·  \(AppModel.reviveCost) ◉", enabled: false)
                Text("Pas assez de pièces — joue encore pour en gagner, ou passe à la boutique.")
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundStyle(UI.sub).multilineTextAlignment(.center)
            }
        }
    }
    private func reviveCTA(title: String, enabled: Bool) -> some View {
        Button { if enabled { bridge.revive() } } label: {
            Text(title)
                .font(.system(size: 20, weight: .heavy, design: .rounded))
                .foregroundStyle(enabled ? UI.bg : UI.sub)
                .frame(maxWidth: 300).padding(.vertical, 15)
                .background(enabled ? UI.cta : UI.bg2, in: Capsule())
        }
        .disabled(!enabled)
    }

    private var walletLine: some View {
        HStack(spacing: 14) {
            Label("\(model.coins)", systemImage: "circle.circle.fill").foregroundStyle(UI.coin)
            Label("\(model.lives)", systemImage: "heart.fill").foregroundStyle(UI.life)
        }
        .font(.system(size: 15, weight: .bold, design: .rounded))
    }
}
