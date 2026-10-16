# Duo Run — Journal

Runner infini coopératif à deux sur un seul écran (PRD-DuoRun-runner-coop.md), optimisé iPhone Duo.
Projet Xcode indépendant : `com.duorun.app`, paysage, SpriteKit (jeu) + SwiftUI (hôte). iOS 17+.

## Étape en cours : premier niveau (biome Western) pour validation du style

Conformément à la demande « code tout mais arrête-toi après un niveau pour valider le style graphique ».
Périmètre volontairement limité au **solo + biome Canyon Western**, pour juger la direction artistique
et le game feel de base avant le mode duo, la génération procédurale et l'économie.

### Fait
- Structure : `App/` (DuoRunApp, GameView), `Game/` (GameScene, Hero, Level, WesternBiome), `Core/` (Palette).
- **Physique maison** déterministe (gravité, vélocité, AABB), défilement auto (320→520 pt/s), pas de
  moteur physique SpriteKit pour le perso (contrôle du game feel), conforme PRD §11.
- **Contrôles** : tap = saut, tap en l'air = double saut, maintien = plané, swipe bas = glissade/plongeon.
- **Niveau 1 écrit à la main** (Level.western) : intro, tonneau, cactus, gouffres (canyon), poutre à
  glisser dessous, arcs et lignes de pièces, respiration finale. Décodable/franchissable à la vitesse courante.
- **Direction artistique Western** (WesternBiome) : ciel dégradé + soleil, 2 couches de mesas en
  parallaxe, sol terracotta/terre, cactus, tonneaux, poutre, pièces — flat texturé, formes rondes,
  contours « ink », toon à grosse tête.
- **Retours utilisateur intégrés (1re passe)** :
  - contact au sol garanti (bases enfoncées de 2 px + **ombres portées** sous perso et obstacles) ;
  - **vie de décor** : nuages en parallaxe lente + **oiseaux** qui traversent ;
  - **animations du coureur** : cycle de course (jambes + bras + bob), pose de saut (jambes repliées),
    pose de glissade.
- HUD : distance (m) au centre, pièces en haut à gauche.

### À valider avec l'utilisateur (checkpoint style)
- Direction artistique du biome Western (palette, formes, personnage).
- Game feel de base (hauteur/rythme des sauts, vitesse).

### Style validé par l'utilisateur (12/09) → on avance

### Jalon 2 — Génération procédurale infinie (fait)
- `WorldSim` : monde seedé assemblé par chunks à la volée (flat, tonneau, cactus, poutre, gouffre,
  double), courbe de difficulté (1→5 selon la distance), **jamais deux pièges d'affilée**, respiration
  imposée toutes les 8-10 unités, **gouffres bornés (≤220 pt) toujours franchissables**.
- `GameScene` refactorée : le monde n'est plus un niveau fixe bouclé mais **infini**, avec
  **spawn/recyclage des nœuds par identifiant** (pooling) — création devant, retrait derrière.
- Contact au sol conservé. Build OK.

### Jalon 3 — Mode duo tête-bêche + architecture (fait, build OK)
- Refactor propre : `RunnerState` (physique verticale d'un coureur + `Tuning`), `TrackView` (rendu
  complet d'une piste : décor + héros + monde, repère local), `GameScene` orchestratrice.
- **Solo ET duo** : en duo, deux pistes en demi-hauteur, la piste B **pivotée de 180°** (les deux
  joueurs face à face autour de la ligne médiane / charnière), **même monde et même distance
  partagés** (obstacles synchronisés). Sauts calibrés pour la demi-hauteur (Tuning duo), pièces
  bornées pour ne pas déborder sur l'autre piste.
- **Entrées multi-touch routées par zone** : bas = joueur A, haut = joueur B ; chacun saute/plane/
  glisse sur SA moitié (glissade inversée pour la piste tête-bêche).
- **Chute → bulle** ; fin de partie quand les DEUX sont à terre → relance (nouveau seed).
- Bande de score commune sur la ligne médiane.
- ⚠️ **Non vérifié visuellement** (simulateur réservé à la fin, machine limitée) : compile, à
  regarder en jeu au moment du test global.

### Direction artistique à pousser : ROGER DEAN (demandé par l'utilisateur)
Le flat Western est une base « pour commencer ». Viser ensuite un style **Roger Dean** (pochettes de
Yes / Asia) : **paysages surréalistes**, îles/rochers **flottants**, **arches rocheuses organiques**
et sinueuses, ciels en **dégradés riches** multi-couches, végétation onirique, formes courbes et
fantastiques. À appliquer sur les fonds/parallaxe des biomes (passe artistique après l'économie).

### Jalon 4 — Économie, arrêt de mort, menu & boutique (fait, build OK)
- **Un coureur tombe → pause pour les deux** → panneau : **Recommencer** OU **Revivre**.
  Revivre consomme **1 vie** du stock si dispo, sinon **2000 pièces** (cher : ~20 min de jeu),
  sinon bouton grisé + invite à jouer/boutique. Revivre continue la MÊME partie (invincibilité 2 s).
- **Portefeuille persistant** (`AppModel`, UserDefaults) : pièces, vies, temps de jeu. Pièces gagnées
  en jouant vont au portefeuille (affiché en HUD).
- **Menu d'accueil** (SwiftUI, design sombre chaleureux PRD §9) : sélecteur Solo/Duo, JOUER, Boutique,
  portefeuille. **Boutique** : « 1 vie — 2000 ◉ » (pièces) et « Pack 10 vies — 4,99 € » (achat réel,
  **StoreKit à câbler**, stub avec alerte pour l'instant).
- Pont `GameBridge` scène↔UI (état en jeu/mort, distance, pièces du run).
- ⚠️ Compile ; non vérifié visuellement (test simulateur réservé à la fin).

### Reste (ordre PRD §13)
Réanimation coop **SOS** (l'autre tape 5× pour sauver, invincibilité 2 s, bulle qui dérive 8 s) →
biome 1 complet (train) → biomes 2-3 → économie (pièces, bonus partagés, missions, coffre) → écrans
(accueil, placement duo, fin de run, boutique, réglages) → StoreKit 2 → Game Center → polish.

### Notes techniques
- Scène mémoïsée (SceneHolder) : ne pas recréer la scène à chaque layout (casse le rendu Metal).
- zPosition explicites par calque (le ciel opaque masquait sol/mesas avec `.ignoresSiblingOrder`).
- Capture simulateur : nécessite Simulator au premier plan (sinon « no drawables »), device en paysage.

### Jalon 5 — Art peint (pipeline IA) + cosmétiques (fait, build OK)
- **Fond peint intégré** : `Biome` (image de fond + palette de sol). Biome « Îles célestes » avec le
  fond généré (ChatGPT/DALL·E), **bouclé par miroir** dans `TrackView` (défilement sans couture),
  sol reteinté lavande/jade. `Western` reste dispo en fond procédural.
- **Pipeline art** validé : l'utilisateur génère les fonds dans ChatGPT (prompts sans nom d'artiste,
  16:9, bas dégagé), je les découpe/intègre. (Le procédural PIL ne pouvait pas atteindre ce détail ;
  IA locale sur Mac Intel = trop lente → génération dans le navigateur.)
- **Cosmétiques** : `HeroSkin` (humain tenue+chapeau, ou skin complet dragon/robot dessinés en
  SpriteKit). `Cosmetics` (catalogue), `AppModel` (possession/équipement persistants). Boutique
  onglets **Vies / Tenues / Chapeaux / Skins** : basiques en **pièces** (chers), skins spéciaux en
  **argent réel** (IAP stub, StoreKit à câbler). Achat + équipement fonctionnels.
- ⚠️ Non vérifié à l'écran (simu réservé à la fin). Compile.

### Reste
Prompts + intégration des autres biomes ; câblage StoreKit (packs vies + skins) ; sélecteur de biome ;
placement duo ; Game Center ; polish. Perso par défaut = cowboy (changeable en boutique).

### Jalon 6 — Retour au style de base : biomes 100 % procéduraux (fait, build OK)
- Décision utilisateur : **abandon des fonds IA** (diff trop marquée, « trop IA »). Imagesets retirés,
  code du fond peint supprimé.
- **6 biomes procéduraux** dans le style flat cohérent (Biome + moteur `Western` étendu) :
  Western (mesas), Désert (dunes+sandstone), Jungle (collines+arbres), Néon (buildings+fenêtres+étoiles),
  Neige (pics enneigés+chute de neige), Espace (cristaux+planète+étoiles). Chaque biome = ciel
  multi-stops + astre + 2 couches de silhouettes en parallaxe + décor + palette de sol assortie.
- Sélecteur de biome au menu (vignettes = dégradé de la palette). Cosmétiques/skins conservés.
- ⚠️ Non vérifié en simu (réservé à la fin). Aperçu PIL = approximation fidèle des palettes/silhouettes.

### Jalon 7 — Rétention (façon Jetpack Joyride) + suite (fait, build OK)
Étude Jetpack Joyride : missions (3 actives = moteur de rétention), gadgets, power-ups, défis
quotidiens, restart instantané. Notre atout unique = le duo coop. Emprunts intégrés :
- **Missions** (`Missions`, `Mission`) : 3 actives en permanence, types coins/mètres/sauts/glissades/
  sauvetages/parties, cibles + récompenses (pièces) + étoiles ; complétées → pièces+étoiles+niveau,
  remplacées aussitôt. Progression **persistante**, branchée aux événements de jeu. Affichées au menu.
- **Coffre du jour** : 150-400 pièces gratuites, 1×/jour (persistant par date).
- **Obstacles rethémés par biome** (couleur dérivée du biome : cactus/rocher/glaçon/borne néon/cristal).
- **Écran de placement duo** (PRD §8.2) : deux zones « Prêt » (celle du haut retournée), décompte 3-2-1
  puis départ ; la scène ne démarre qu'après (`GameScene.started`).
- **StoreKit 2** (`Store`) : pack 10 vies (consommable) + skins Dragon/Robot (non-consommables,
  Family Sharing). `Transaction.updates`, octroi auto, restauration. Boutique câblée (plus de stub).
  Fichier `DuoRun.storekit` créé — **à sélectionner dans le scheme Xcode** (Run > Options > StoreKit
  Configuration) pour tester les achats.
- ⚠️ Tout compile ; non vérifié en simu (réservé à la fin). Les achats ne se testent que dans Xcode.

### Jalon 8 — Power-ups en course, gadgets permanents, Game Center, écran de fin enrichi (fait, build OK)
Fin de la « suite » listée au Jalon 7. Tout compile en simu (`BUILD SUCCEEDED`).
- **Power-ups à ramasser en course** (`PowerupKind` magnet/shield/rocket) : générés dans les tronçons
  plats (`WorldSim`), orbe coloré + emoji dans `Western.powerup`. **Bénéfice partagé** par les deux
  joueurs (PRD §4.5) : aimant (élargit le rayon de ramassage des pièces, durée `model.magnetDuration`),
  bouclier (encaisse un choc — `runner.shield`, anneau visible dans `TrackView`), fusée (vol invincible
  ~5 s, `flyTimer`/`flyTarget` dans `RunnerState`).
- **Gadgets permanents** (`Gadget`, `Gadgets`, onglet Boutique) achetés en pièces, actifs à chaque
  partie : Départ lancé (400 m d'avance), Bouclier de départ, Aimant longue durée (8→12 s). Appliqués
  au départ via `applyStartGadgets()`.
- **Game Center** (`GameCenter`, GameKit) : authentification au lancement, soumission de la distance au
  classement `duorun.distance` à chaque mort, feuille de classement (`GameCenterView`) ouverte depuis le
  menu. Entitlement `DuoRun.entitlements` (game-center) câblé dans le projet ; dégrade proprement si non
  authentifié. **À créer côté App Store Connect** : le leaderboard `duorun.distance`.
- **Écran de fin enrichi** (`DeathPanel`) : badge **« Nouveau record ! »** (meilleure distance
  persistante `AppModel.bestDistanceM`) ou rappel du record, + puces bilan (distance, pièces ramassées,
  missions terminées dans la partie, niveau).
- ⚠️ Non vérifié en simu (réservé à la fin). Game Center réel + achats se testent dans Xcode / device.

### Jalon 9 — Passe UX paysage + verrouillage de biomes + features (fait, vérifié en simu)
Premier vrai passage au simulateur (à la demande de l'utilisateur). Corrections de mise en page paysage
et plusieurs ajouts, tout vérifié à l'écran (screenshots).
- **Marges de sécurité** (`SafeInsets`, `RootView`) : respecte l'encoche / la caméra sur tous les écrans
  en paysage (accueil, boutique, panneau de mort, bouton maison en jeu).
- **Accueil resserré** : **JOUER en haut** (zéro scroll pour jouer), titre compact, sélecteur de biome,
  **Boutique + Classement épinglés en bas**. Missions **retirées de l'accueil**.
- **Boutique** : onglets en **pastilles** (texte blanc quand non sélectionné → lisible), nouvel onglet
  **Biomes**.
- **Biomes verrouillés** (`BiomeUnlock`, `AppModel.ownedBiomes`) : Western + Désert offerts ; Jungle
  2000 ◉, Ville néon 4000 ◉, Montagnes 6000 ◉ (pièces) ; **Espace 4,99 €** (IAP `com.duorun.biome_space`,
  ajouté au `Store` + `DuoRun.storekit`). Cadenas + prix à l'accueil ; achat/choix en boutique.
- **Coffre animé** (`ChestRewardView`) : coffre qui surgit/tremble/s'ouvre, pièces qui jaillissent,
  montant qui défile — remplace l'alerte.
- **Écran de pause / fin de partie** (`DeathPanel`) refondu : borné à l'écran (jamais de débordement),
  infos qui défilent en interne, **boutons épinglés** en bas. Sections **« Pièces gagnées »**
  (ramassées + bonus missions), **« Missions accomplies »** (cette partie), **« Missions en cours »**
  (les 3 actives avec progression). Missions déplacées ici depuis l'accueil.
- **Défilement stoppé à la mort** (`GameScene.isPaused`).
- **Drapeau du record** (`Western.recordFlag`, `TrackView.recordWorldX`) : damier planté à la meilleure
  distance atteinte, défile avec le monde ; posé au départ via `applyRecordFlag()`.
- **Difficulté croissante** (`WorldSim`) : paliers ~110 m jusqu'à 10 ; respiration plus rare, pièges
  (trous/doubles) plus fréquents, espacement resserré — bornes conservées (toujours franchissable).
- **3 vies offertes** au tout premier lancement (`AppModel`, flag `duorun.bootstrapped`).
- Vérifié en simu : accueil, boutique, panneau de fin (données simulées). Drapeau + difficulté = code
  OK, à voir en jouant. Achats/Game Center réels toujours à tester dans Xcode/device.

### Jalon 10 — Store blindé + déblocage double + aperçu perso (fait, vérifié en simu)
- **Déblocage de biome à deux options** (`BiomeUnlock.locked(coins, product, money)`) : chaque niveau
  verrouillé s'ouvre en **pièces (montant élevé)** OU en **achat réel**. Jungle 8000 ◉ / 2,99 €,
  Néon 15000 ◉ / 3,99 €, Neige 25000 ◉ / 4,99 €, Espace 40000 ◉ / 5,99 €. 4 produits IAP biome ajoutés
  (`Store` + `DuoRun.storekit`).
- **Redirection ciblée** : cliquer un biome verrouillé à l'accueil ouvre directement l'**onglet Biomes**
  de la boutique (`RootView.shopTab` passé à `HomeView` + `ShopView(initialTab:)`).
- **Boutique blindée** — 15 cosmétiques ajoutés, prix réajustés en échelle croissante :
  Tenues (11, recolors via `outfitColors`), Chapeaux (9, dont bonnet `.beanie`), Skins (4 : Fantôme 1,99 €,
  Robot 2,99 €, Dragon 3,99 €, Chat 18000 ◉). Nouveaux corps `HeroSkin.Body.ghost/.cat`, chapeau `.beanie`,
  produit IAP `skin_ghost`.
- **Aperçu perso** (`HeroPreview` + `HeroPreviewScene`, SpriteKit) : toucher une tenue / chapeau / skin
  affiche le coureur avec l'article ; sinon montre l'apparence équipée.
- Vérifié en simu : onglets Skins (aperçu du cowboy équipé) et Biomes (double option pièces/achat).

### Jalon 11 — Réanimation coop SOS temps réel (cœur du jeu, PRD §4.4) (fait, build OK)
Jusqu'ici, en duo, une chute mettait TOUT en pause (revive d'économie via l'UI) — ça tuait la tension
coopérative. Remplacé par le vrai sauvetage temps réel, la mécanique signature du jeu.
- `GameScene` : en **solo**, une chute = fin (inchangé). En **duo**, `updateDuoRescue(dt:)` :
  quand un joueur tombe, sa piste passe en **fenêtre de sauvetage 8 s** (`rescuing`/`rescueLeft`),
  l'autre continue de courir ; les **DEUX à terre = fin** (revive payant). Fenêtre écoulée = à terre
  définitif (`expired`).
- **Bulle qui flotte et dérive** (`TrackView.showBubble`) : placée à hauteur visible (le coureur a pu
  tomber loin sous le sol) + `moveBy` -150 pt sur 8 s ; le héros faded flotte DEDANS (`render`).
- **Pastille SOS** sur la moitié DU SAUVETEUR (`makeSOSNode`, 5 pips), pivotée `.pi` si le sauveteur
  est la piste tête-bêche du haut. `handleSOSTouch` intercepte les taps sur la pastille (hit-test rayon
  62) AVANT le routage saut ; **5 taps** → `performRescue` : `track.revive()` (2 s d'invincibilité,
  déjà dans `RunnerState`), `progress(.saves)`, **flash doux + haptique forte** (PRD §9).
- `touchesMoved`/`endTouches` durcis (ignorent les touches SOS, plus de faux hold). État de sauvetage
  remis à zéro dans `resetRescueState()` (appelé au build, à la relance et au revive payant).
- **Ralenti « sauvetage »** (demandé) : tant qu'un joueur attend d'être secouru, le monde passe en
  **slow-mo** (`timeScale` lerpé vers 0.35, appliqué au `dt` de jeu + `scene.speed`), pour laisser à
  l'autre le temps de réagir (tap SOS + esquive), puis retour progressif à la normale au sauvetage /
  à l'expiration. La fenêtre de 8 s reste comptée en temps réel.
- ✅ **Vérifié en simulateur (iOS 26.5)** : en duo, chute d'un joueur → il flotte dans sa bulle, la
  pastille **SOS** apparaît bien sur la moitié DU SAUVETEUR (orientée correctement), l'autre
  continue de courir, le jeu ne fige plus les deux. (Capture via hook `DBG_SOS` temporaire, retiré depuis.)
- **Tuning gameplay (demandé)** : (1) **position aléatoire** de la pastille SOS sur la moitié du
  sauveteur à chaque chute (l'oblige à la repérer) ; (2) **nombre de taps aléatoire 3–6** par SOS
  (`rescueTarget`, affiché « tape ×N » + N pips) → l'oblige à lire, pas de réflexe automatique ;
  (3) **budget de 3 SOS par partie** (`maxSOS`/`sosUsed`) : au 4ᵉ, une chute = à terre ; un **revive
  payant remet le budget à 0** (via `resetRescueState()` dans `doRevive`) → 3 SOS de nouveau dispo.

### Jalon 12 — Level-design & game-feel (retours user, fait, build OK)
Retours en jouant le solo (le solo n'était pas cassé, c'était du level-design) :
- **Pièces plus jamais collées aux obstacles** : la ligne de pièces du beam passe de `y=40` (contre la
  barre 42-62) à **`y=14` dans le couloir de glissade** (ramassées en slidant, bien sous la barre).
  Sommet des arches de pièces abaissé (`min(peak,84)`→`70`) pour rester atteignable avec le nouveau saut.
- **Saut moins haut** (solo) : `jumpV 1150→920`, `doubleV 1060→850` → ~150 pt de haut, proportionné aux
  obstacles (cactus 74, barrel 60) au lieu de ~236 pt « lunaire ». Trous abaissés `230→205` en conséquence.
- **Plus d'obstacles « en hauteur » (façon Chrome Dino)** : poids du **beam** (à glisser dessous) relevé
  `1.0+d·0.1 → 1.6+d·0.15` = aussi fréquent que cactus/barrel → alterne saut / glissade, plus de spam-saut.
- **Accélération plus marquée** : coefficient distance `0.004→0.005`, `maxSpeed` solo `520→640`, duo
  `500→560` → on sent la vitesse monter, plafonnée à une valeur jouable.
- ⚠️ Le ressenti exact (hauteur de saut, glissade, montée en vitesse) se juge **manette en main** :
  à playtester sur simu/appareil.

### Jalon 13 — Physique de chute & glissade (retours user, fait, build OK)
- **Glissade** : durée passée de 0,6 s à **1,5 s** (`slideTimer` dans `beginSlide`).
- **Fin de la « téléportation après le trou »** : on ne pose le coureur que s'il **traverse le sol par
  le haut** (`prevY >= groundTopY - 2`) ; le bord opposé qui défile ne le fait plus remonter d'un coup.
  Vérifié par logs (une seule `FELL`, aucun `LAND` sur un monde 100 % trous).
- **Collision de MUR** : s'il y a du sol à la position du coureur mais qu'il est passé **sous** la
  surface (il a plongé dans le trou, le bord opposé arrive), il **se cogne le mur → chute nette
  immédiate**, au lieu de traverser le bloc. Un saut qui franchit vraiment le trou (on arrive
  au-dessus de la lèvre) atterrit normalement ; un saut trop court sous la lèvre = mort au mur.

### Jalon 14 — Son & icône (fait, build OK)
- **Icône** : concept D (tête-bêche) dessiné en style toon (2 cowboys face à face autour de la charnière,
  rouge en haut tête-bêche / bleu en bas, zones chaud-froid). 1024×1024 RGB sans alpha, installé dans
  `AppIcon.appiconset` (+ Contents.json). Compilée dans Assets.car.
- **Audio** : `SoundManager` (AVAudioPlayer, pool de 5, catégorie `.ambient` = respecte l'interrupteur
  silence + se mélange à la musique, mute persistant). **10 bruitages synthétisés** (WAV embarqués dans
  `Resources/Sounds/`) : saut, double-saut, glissade, atterrissage, pièce, power-up, tap SOS, jingle de
  sauvetage, mort, coffre. Branchés sur les évènements (TrackView, GameScene, HomeView).
- **Musique de fond** : boucle chiptune 7,5 s (`music.wav`, mélodie+basse+hi-hat, accords C-G-Am-F),
  `startMusic()` au lancement (RootView), volume 0.32, `numberOfLoops=-1`. **Bruitages validés à l'oreille par l'user.**
- **Bouton mute** (accueil, barre du haut) : coupe/réactive musique + SFX via `SoundManager.setMuted`,
  choix persistant (`duorun.muted`). Musique en pause quand mute.

### Reste avant publication
Playtest du game-feel (saut/slide/vitesse) + éventuel bump de la taille des obstacles → **fiche App Store
Connect** (app `com.duorun.app` : listing FR/EN, captures, IAP depuis `DuoRun.storekit`, leaderboard
`duorun.distance`, confidentialité, âge, copyright, note de review) → signature + upload → soumission.
(jingle sauvetage) → **fiche App Store Connect** (nouvelle app `com.duorun.app` : listing, captures,
IAP depuis `DuoRun.storekit`, leaderboard Game Center `duorun.distance`, confidentialité, âge) →
upload build → soumission.
