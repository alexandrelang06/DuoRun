import AVFoundation

/// Gestion audio du jeu : bruitages synthétisés (WAV embarqués), pool de lecteurs pour permettre les
/// sons qui se chevauchent (pièces à la chaîne…). Respecte l'interrupteur silence (catégorie ambient)
/// et se mélange à la musique de l'utilisateur. Mute persistant.
final class SoundManager {
    static let shared = SoundManager()

    enum SFX: String, CaseIterable {
        case coin, jump, djump, land, slide, powerup, rescue, death, chest, tap
    }

    private var pools: [SFX: [AVAudioPlayer]] = [:]
    private let poolSize = 5
    private var music: AVAudioPlayer?
    private(set) var muted: Bool

    private init() {
        muted = UserDefaults.standard.bool(forKey: "duorun.muted")
        let session = AVAudioSession.sharedInstance()
        try? session.setCategory(.ambient, options: [.mixWithOthers])
        try? session.setActive(true)
        for s in SFX.allCases {
            guard let url = Bundle.main.url(forResource: s.rawValue, withExtension: "wav") else { continue }
            pools[s] = (0..<poolSize).compactMap {
                _ in let p = try? AVAudioPlayer(contentsOf: url); p?.prepareToPlay(); return p
            }
        }
    }

    func play(_ s: SFX, volume: Float = 1) {
        guard !muted, let pool = pools[s] else { return }
        let p = pool.first { !$0.isPlaying } ?? pool.first
        p?.volume = volume
        p?.currentTime = 0
        p?.play()
    }

    /// Démarre la musique de fond en boucle (une seule fois). Volume discret pour laisser passer les SFX.
    func startMusic() {
        guard music == nil, let url = Bundle.main.url(forResource: "music", withExtension: "wav") else { return }
        let p = try? AVAudioPlayer(contentsOf: url)
        p?.numberOfLoops = -1
        p?.volume = 0.32
        p?.prepareToPlay()
        music = p
        if !muted { p?.play() }
    }

    func setMuted(_ m: Bool) {
        muted = m
        UserDefaults.standard.set(m, forKey: "duorun.muted")
        if m { music?.pause() } else { music?.play() }
    }
}
