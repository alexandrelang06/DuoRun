import SwiftUI

struct HomeView: View {
    @Bindable var model: AppModel
    @Binding var route: RootView.Route
    @Binding var shopTab: ShopView.Tab
    @State private var chestReward: Int?
    @State private var showLeaderboard = false
    @State private var muted = SoundManager.shared.muted

    var body: some View {
        ZStack {
            UI.bg.ignoresSafeArea()
            VStack(spacing: 10) {
                topBar
                titleBlock
                modePicker
                playButton                       // toujours visible : zéro scroll pour jouer
                biomePicker
                Spacer(minLength: 8)
                bottomButtons                    // Boutique + Classement épinglés en bas
            }
            .frame(maxWidth: 620)
            .frame(maxWidth: .infinity)
            .safeInsets()

            if let reward = chestReward {
                ChestRewardView(reward: reward) { chestReward = nil }
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.2), value: chestReward)
        .sheet(isPresented: $showLeaderboard) { GameCenterView().ignoresSafeArea() }
    }

    // MARK: Haut

    private var topBar: some View {
        HStack(spacing: 8) {
            pill { Label("\(model.coins)", systemImage: "circle.circle.fill").foregroundStyle(UI.coin) }
            pill { Label("\(model.lives)", systemImage: "heart.fill").foregroundStyle(UI.life) }
            pill { Label("Niv. \(model.level)", systemImage: "star.fill").foregroundStyle(UI.cta) }
            Spacer()
            Button {
                muted.toggle(); SoundManager.shared.setMuted(muted)
            } label: {
                Image(systemName: muted ? "speaker.slash.fill" : "speaker.wave.2.fill")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(UI.sub)
                    .frame(width: 34, height: 34).background(UI.bg2, in: Circle())
            }
            Button {
                if model.canClaimChest { let r = model.claimDailyChest(); if r > 0 { chestReward = r; SoundManager.shared.play(.chest) } }
            } label: {
                Label(model.canClaimChest ? "Coffre" : "Pris", systemImage: "gift.fill")
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundStyle(model.canClaimChest ? UI.bg : UI.sub)
                    .padding(.horizontal, 12).padding(.vertical, 8)
                    .background(model.canClaimChest ? UI.cta : UI.bg2, in: Capsule())
            }.disabled(!model.canClaimChest)
        }
    }
    private func pill<C: View>(@ViewBuilder _ c: () -> C) -> some View {
        c().font(.system(size: 15, weight: .bold, design: .rounded))
            .padding(.horizontal, 12).padding(.vertical, 7).background(UI.bg2, in: Capsule())
    }

    private var titleBlock: some View {
        HStack(spacing: 8) {
            Text("Duo Run")
                .font(.system(size: 28, weight: .heavy, design: .rounded)).foregroundStyle(UI.text)
            Text("· Courez à deux sur un seul écran")
                .font(.system(size: 13, weight: .medium, design: .rounded)).foregroundStyle(UI.sub)
                .lineLimit(1)
        }
    }

    private var playButton: some View {
        Button { route = .game } label: {
            Text("JOUER").font(.system(size: 23, weight: .heavy, design: .rounded))
                .foregroundStyle(UI.bg).frame(maxWidth: 360).padding(.vertical, 14)
                .background(UI.cta, in: Capsule())
        }
    }

    private var bottomButtons: some View {
        HStack(spacing: 10) {
            Button { route = .shop } label: {
                Label("Boutique", systemImage: "bag.fill")
                    .font(.system(size: 16, weight: .bold, design: .rounded)).foregroundStyle(UI.text)
                    .frame(maxWidth: .infinity).padding(.vertical, 13).background(UI.bg2, in: Capsule())
            }
            Button { showLeaderboard = true } label: {
                Label("Classement", systemImage: "list.number")
                    .font(.system(size: 16, weight: .bold, design: .rounded)).foregroundStyle(UI.text)
                    .frame(maxWidth: .infinity).padding(.vertical, 13).background(UI.bg2, in: Capsule())
            }
        }
    }

    // MARK: Mode

    private var modePicker: some View {
        HStack(spacing: 10) {
            modeButton("Duo coop", .duo, system: "person.2.fill")
            modeButton("Solo", .solo, system: "person.fill")
        }
    }
    private func modeButton(_ title: String, _ m: GameMode, system: String) -> some View {
        let selected = model.mode == m
        return Button { model.mode = m } label: {
            Label(title, systemImage: system).font(.system(size: 15, weight: .bold, design: .rounded))
                .foregroundStyle(selected ? UI.bg : UI.text)
                .padding(.horizontal, 16).padding(.vertical, 10)
                .background(selected ? UI.cta : UI.bg2, in: Capsule())
        }
    }

    // MARK: Biome (avec biomes verrouillés à acheter)

    private var biomePicker: some View {
        VStack(spacing: 6) {
            Text("Biome").font(.system(size: 13, weight: .bold, design: .rounded)).foregroundStyle(UI.sub)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(Biome.all) { b in biomeCell(b) }
                }.padding(.horizontal, 4)
            }
        }
    }

    @ViewBuilder private func biomeCell(_ b: Biome) -> some View {
        let unlocked = model.biomeUnlocked(b.id)
        let selected = unlocked && model.selectedBiomeID == b.id
        Button {
            if unlocked { model.selectBiome(b.id) }
            else { shopTab = .biomes; route = .shop }   // verrouillé → onglet Biomes de la boutique
        } label: {
            VStack(spacing: 4) {
                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(LinearGradient(colors: [Color(uiColor: b.skyStops.first?.1 ?? .gray),
                                                      Color(uiColor: b.skyStops.last?.1 ?? .gray),
                                                      Color(uiColor: b.groundTop)],
                                             startPoint: .top, endPoint: .bottom))
                        .frame(width: 120, height: 62)
                        .overlay(RoundedRectangle(cornerRadius: 10)
                            .stroke(selected ? UI.cta : .white.opacity(0.15), lineWidth: selected ? 3 : 1))
                    if !unlocked {
                        RoundedRectangle(cornerRadius: 10).fill(.black.opacity(0.42))
                            .frame(width: 120, height: 62)
                        VStack(spacing: 3) {
                            Image(systemName: "lock.fill").font(.system(size: 16, weight: .bold))
                                .foregroundStyle(.white)
                            Text(priceLabel(b.unlock)).font(.system(size: 11, weight: .heavy, design: .rounded))
                                .foregroundStyle(UI.cta)
                        }
                    }
                }
                Text(b.name).font(.system(size: 11, weight: .semibold, design: .rounded))
                    .foregroundStyle(selected ? UI.cta : UI.sub).lineLimit(1)
            }.frame(width: 120)
        }
    }

    private func priceLabel(_ u: BiomeUnlock) -> String {
        switch u {
        case .free: return "Gratuit"
        case .locked(let n, _, _): return "\(n) ◉"
        }
    }
}

/// Récompense du coffre du jour, façon « loot » : le coffre surgit, tremble, s'ouvre, les pièces
/// jaillissent en étoile et le montant défile. Remplace l'alerte plate.
struct ChestRewardView: View {
    let reward: Int
    let onClose: () -> Void

    @State private var appear = false
    @State private var shake = false
    @State private var open = false
    @State private var displayed = 0

    var body: some View {
        ZStack {
            Color.black.opacity(0.6).ignoresSafeArea()
                .onTapGesture { onClose() }

            VStack(spacing: 16) {
                Text("Coffre du jour")
                    .font(.system(size: 20, weight: .heavy, design: .rounded))
                    .foregroundStyle(UI.text).opacity(appear ? 1 : 0)

                ZStack {
                    Circle().fill(UI.cta.opacity(0.30))
                        .frame(width: 200, height: 200).blur(radius: 34)
                        .scaleEffect(open ? 1.2 : 0.5).opacity(open ? 1 : 0)

                    // Pièces cachées au centre (derrière le coffre), qui jaillissent à l'ouverture.
                    ForEach(0..<12, id: \.self) { i in
                        let angle = Double(i) / 12 * 2 * .pi
                        Text("🪙").font(.system(size: 24))
                            .offset(x: open ? CGFloat(cos(angle)) * 128 : 0,
                                    y: open ? CGFloat(sin(angle)) * 94 : 0)
                            .opacity(open ? 0 : 1)
                            .scaleEffect(open ? 0.5 : 1)
                            .animation(.easeOut(duration: 0.7).delay(Double(i) * 0.015), value: open)
                    }

                    Text(open ? "🪙" : "🎁")
                        .font(.system(size: 92))
                        .scaleEffect(appear ? (open ? 1.1 : 1) : 0.1)
                        .rotationEffect(.degrees(shake ? 9 : -9))
                }
                .frame(height: 200)

                Text("+\(displayed) ◉")
                    .font(.system(size: 34, weight: .heavy, design: .rounded))
                    .foregroundStyle(UI.coin)
                    .opacity(open ? 1 : 0).scaleEffect(open ? 1 : 0.4)

                Text("Reviens demain pour un nouveau coffre !")
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .foregroundStyle(UI.sub).opacity(open ? 1 : 0)

                Button(action: onClose) {
                    Text("Super !").font(.system(size: 18, weight: .heavy, design: .rounded))
                        .foregroundStyle(UI.bg).frame(maxWidth: 240).padding(.vertical, 13)
                        .background(UI.cta, in: Capsule())
                }.opacity(open ? 1 : 0)
            }
            .padding(28)
        }
        .onAppear(perform: run)
    }

    private func run() {
        withAnimation(.spring(response: 0.45, dampingFraction: 0.55)) { appear = true }
        withAnimation(.easeInOut(duration: 0.08).repeatCount(6, autoreverses: true).delay(0.28)) { shake = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.85) {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.62)) { open = true }
            countUp()
        }
    }

    private func countUp() {
        let inc = max(1, reward / 24)
        Timer.scheduledTimer(withTimeInterval: 0.025, repeats: true) { t in
            displayed = min(reward, displayed + inc)
            if displayed >= reward { t.invalidate() }
        }
    }
}
