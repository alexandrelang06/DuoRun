# PRD — « Duo Run » (titre de travail)
### Runner infini coopératif à deux joueurs sur un seul appareil, optimisé iPhone Duo

Version 1.0 — septembre 2026. Ce document sert de prompt initial et de référence produit pour le développement avec Claude Code.

---

## 1. Vision

Le premier runner infini qui se joue à DEUX sur un seul téléphone. L'écran est partagé en deux pistes, chaque joueur contrôle son personnage en tapant sur sa moitié, le monde défile en miroir et se génère procéduralement à l'infini. Quand l'un tombe, l'autre peut le sauver. Sur iPhone Duo déplié, la charnière devient la ligne qui sépare les deux pistes. L'app tourne aussi en solo et sur iPhone/iPad classiques.

**Pitch App Store.** « Courez à deux sur un seul écran. Sauvez-vous l'un l'autre. Allez toujours plus loin. »

**Boucle émotionnelle visée.** Tension partagée, éclats de rire quand l'un tombe, gratitude quand l'autre le ressuscite, rivalité douce sur qui a ramassé le plus de pièces.

---

## 2. Cibles et plateformes

- **Duo principal.** Couples, amis, fratries, parent-enfant (8+). Sessions de 2 à 5 minutes, posé à plat sur une table ou tenu entre les deux joueurs
- **Solo.** Le même jeu sur une piste unique, pour jouer dans les transports et engager avant de convertir au mode duo
- **Plateformes.** iPhone (solo et duo serré), iPad (duo confortable), iPhone Duo déplié (expérience signature). iOS 17 minimum
- **Classement.** 4+, contenu tout public, aucun contenu violent (les personnages « tombent en bulle », ne meurent pas)

---

## 3. Modes de jeu

1. **Duo co-op (mode signature).** Deux pistes synchronisées (même seed), score commun = distance + pièces des deux. La partie s'arrête quand les DEUX sont à terre. Réanimation possible (voir §4.4)
2. **Duo versus.** Mêmes pistes synchronisées, mais chacun son score, premier à terre a perdu. Débloqué après 5 parties co-op (le co-op est l'identité du jeu, le versus est un bonus)
3. **Solo.** Une piste plein écran, mêmes biomes et progression, score personnel
4. **Défi du jour.** Un seed fixe mondial par jour (solo et duo), classement Game Center

---

## 4. Gameplay

### 4.1 Contrôles (par joueur, sur SA moitié d'écran)

- **Tap court** = saut. **Tap en l'air** = double saut
- **Appui maintenu** = planer (en l'air) ou s'accrocher (tyrolienne, liane, wagon selon le biome)
- **Swipe vers le bas** = glissade sous les obstacles
- Aucun autre geste. Zones tactiles = toute la moitié du joueur, aucune précision requise

### 4.2 Défilement et pistes

- Défilement horizontal automatique, vitesse de base 320 pt/s, +4 % toutes les 30 s, plafonnée
- **Disposition duo.** Appareil à plat en paysage, écran scindé dans la longueur en deux pistes tête-bêche. Chaque piste est orientée vers son joueur (le monde du joueur B est rendu en miroir/rotation 180°). Les deux joueurs sont face à face, la charnière du Duo au milieu
- Les deux pistes affichent le MÊME parcours (même seed, mêmes obstacles au même moment), ce qui crée les réactions partagées (« attention le train ! »)
- **Disposition solo.** Une piste, paysage, plein écran

### 4.3 Génération procédurale

- Le monde est assemblé par chunks préfabriqués de 12 à 24 m (plats, bosses, gouffres, séries de plateformes, sections d'accroche, sections de glissade), taggés par difficulté 1-5
- Sélection pondérée par la distance parcourue (courbe de difficulté), jamais deux chunks « pièges » consécutifs, chunk de respiration toutes les 8-10 unités
- Pièces placées en arcs et en lignes sur les trajectoires de saut naturelles
- RNG seedé (identique pour les deux pistes, et fixé pour le défi du jour)

### 4.4 Chute et réanimation (cœur du co-op)

- Un joueur qui rate flotte dans une **bulle** qui reste visible sur SA piste et dérive lentement vers la gauche pendant 8 secondes
- L'autre joueur peut le sauver en tapant 5 fois rapidement sur une pastille « SOS » qui apparaît sur SA moitié (sans quitter sa course des yeux trop longtemps, c'est ça la tension)
- Réanimation réussie = le coureur revient avec 2 s d'invincibilité. Bulle expirée = joueur à terre jusqu'à la fin du run
- Les DEUX à terre = fin de partie, sauf revive payant (voir §7) qui relance les deux
- En solo, la bulle devient un « second souffle » utilisable une fois par run en regardant une pub récompensée ou en dépensant des pièces

### 4.5 Collectibles et bonus

- **Pièces** (monnaie douce, gagnée en jouant, jamais vendue seule en pack au-dessus de 4,99 €)
- **Aimant** (attire les pièces 10 s), **Bouclier** (encaisse un choc), **Fusée** (vol invincible 5 s). Les bonus ramassés par UN joueur profitent aux DEUX (renforce le co-op)
- **Coffre de fin de run** (1/jour gratuit, contenu cosmétique ou pièces)

---

## 5. Biomes (niveaux et styles graphiques)

Le run traverse les biomes par tranches de ~800 m avec une transition visuelle fluide (le décor se métamorphose sur 100 m). L'ordre des biomes est aléatoire par run, le premier biome est celui choisi par les joueurs (parmi les débloqués). Chaque biome = une palette, 4 couches de parallaxe, un set d'obstacles rethémé et UNE mécanique signature.

| # | Biome | Style graphique / palette | Obstacles rethémés | Mécanique signature |
|---|---|---|---|---|
| 1 | **Canyon Western** (défaut) | Ocres et terracotta `#C46A3B`, ciel sable `#F2D8A7`, mesas en parallaxe, cactus, style flat texturé grain papier | Barils, chariots, cactus, gouffres de canyon | **Le train** traverse la piste, il faut s'accrocher au wagon (appui maintenu) pour franchir un grand gouffre |
| 2 | **Montagnes enneigées** | Bleus froids `#7FA8C9`, blanc cassé, sapins, sommets brumeux, flocons discrets | Congères, stalactites, ponts de glace fragiles | **L'avalanche** arrive par derrière pendant 10 s, il faut enchaîner les glissades sans ralentir |
| 3 | **Jungle** | Verts profonds `#2E7D57`, fleurs corail `#FF8C7A`, brume, ruines moussues | Lianes, troncs, marécages | **Les lianes** remplacent les plateformes, sections entières en appui maintenu (balancement) |
| 4 | **Ville néon** | Nuit violette `#3B2E5A`, néons cyan `#5FC9C2` et rose, pluie légère, enseignes | Taxis, bennes, chantiers | **Les toits** avec ventilations qui propulsent (double saut gratuit sur les grilles) |
| 5 | **Plage tropicale** | Turquoise `#5FC9C2`, sable chaud `#F4E3C1`, palmiers, coucher de soleil dégradé | Crabes, parasols, rochers | **La vague** monte et descend, le sol devient mouvant sur certaines sections |
| 6 | **Désert des pharaons** | Or `#F4C430` et lapis `#2B4C9B`, pyramides, hiéroglyphes lumineux | Sarcophages, scarabées, sables mouvants | **Les dalles piégées** s'effondrent 0,5 s après contact, il faut garder le rythme |
| 7 | **Espace** (déblocage tardif) | Noir bleuté `#12141F`, étoiles, planètes pastel en parallaxe | Astéroïdes, satellites | **Gravité réduite**, sauts plus hauts et plus lents, timing chamboulé |

- MVP = biomes 1, 2, 3. Les biomes 4-7 arrivent en mise à jour (contenu vivant, entretient les avis et les re-téléchargements)
- Déblocage des biomes comme point de départ : à la distance cumulée (paliers) OU achat en pièces. Tous les biomes apparaissent de toute façon dans les runs longs, le déblocage ne gate que le choix du départ (jamais de contenu de gameplay bloqué derrière un paywall dur)
- Direction artistique commune : flat texturé chaleureux, formes rondes, grain léger, personnages « toon » à grosse tête lisibles en petit, cohérence stricte entre biomes (mêmes règles de lumière et d'épaisseur de traits)

---

## 6. Personnages et progression

- 2 personnages gratuits au départ (un par joueur, silhouettes et couleurs bien distinctes pour la lisibilité)
- 12+ skins à débloquer (pièces ou achat direct 0,99-1,99 €), purement cosmétiques, certains liés aux biomes (cowboy, yéti, exploratrice, robot néon...)
- **Missions** (3 actives en permanence, type « glisse 30 fois », « sauve ton partenaire 3 fois ») qui rapportent des pièces
- **Trophées de duo** partagés (distance cumulée à deux, sauvetages réussis) affichés sur un mur des exploits
- Game Center : classements distance solo, duo, défi du jour, succès

---

## 7. Monétisation (free-to-play propre, cohérent avec le reste du portefeuille)

- **Gratuit.** Tout le gameplay, tous les biomes en run, pubs = 1 interstitiel max toutes les 3 parties terminées, JAMAIS pendant une partie ni pendant une réanimation
- **Pub récompensée (opt-in uniquement).** Second souffle solo, doubler le coffre du jour, revive duo si plus de pièces
- **Pièces (consommable).** Packs 0,99 € / 2,99 € / 4,99 €. Servent aux skins, au choix de biome, au revive (200 pièces)
- **Pack Premium 4,99 € (non-consommable, Family Sharing).** Supprime toutes les pubs interstitielles + skin exclusif + coffre quotidien doublé + badge « Supporter »
- **Règle Mob Control.** N'IMPORTE quel achat, même 0,99 €, supprime définitivement les interstitiels
- Interdits : loot boxes payantes, énergie/vies limitées, timers, pubs non désactivables, pay-to-win

---

## 8. Écrans et UX

1. **Accueil.** Logo, les deux personnages qui s'échauffent, gros bouton JOUER, sélecteur de mode (Duo co-op par défaut / Versus / Solo), sélecteur de biome de départ, accès boutique, réglages, défi du jour avec compte à rebours
2. **Écran de placement duo.** Avant le run, un écran montre comment poser/tenir l'appareil (pictos), chaque joueur pose son pouce sur SA zone « prêt », le décompte 3-2-1 démarre quand les deux zones sont tenues
3. **En jeu.** HUD minimal par piste (pièces, distance commune au centre sur la ligne médiane/charnière), pastille SOS lors des chutes, pause par bouton central (fige les deux pistes)
4. **Fin de run.** Distance, pièces, records battus, missions avancées, bouton Rejouer proéminent, coffre du jour, PAS d'interstitiel avant l'écran de score
5. **Boutique.** Skins par collections de biomes, pièces, Pack Premium mis en avant sobrement. Aperçu 3D-like du skin animé
6. **Réglages.** Sons/musique séparés, haptique, mode daltonien (pièces et dangers différenciés par forme), mode gaucher (miroir des zones SOS), suppression des pubs = lien boutique, restaurer les achats, crédits
7. **Scroll.** Accueil et boutique en scroll vertical standard. Aucun scroll en jeu

---

## 9. Design system

- **UI.** Fond sombre chaleureux `#1E1A26` pour l'accueil (contraste avec les biomes colorés), CTA `#F4C430`, texte `#FBF7F0`, SF Pro Rounded pour toute l'UI, chiffres tabulaires pour les scores
- **Feedback.** Réussite de sauvetage = flash doux + haptique forte + jingle court (le moment star du jeu, le soigner). Chute = son cartoon « boing » jamais punitif
- **Musique.** Un thème par biome (boucles 60-90 s, crossfade aux transitions), coupable indépendamment des SFX
- **Accessibilité.** Mode une main par joueur garanti (tout se fait au pouce), formes + couleurs pour les dangers, taille de HUD ajustable

---

## 10. iPhone Duo et adaptativité

- Layout par size classes uniquement, jamais par orientation ni `UIScreen.main`
- **Duo déplié à plat.** Les deux pistes de part et d'autre de la charnière, la reserved region de la charnière porte UNIQUEMENT la bande de score commune (élément non interactif). Aucune zone tactile critique sur le pli
- **iPad.** Même disposition tête-bêche, ligne médiane dessinée
- **iPhone classique.** Duo possible mais resserré (avertissement doux « plus confortable sur grand écran »), solo recommandé
- **Transitions de pose.** Si l'appareil est replié en cours de partie, pause automatique et reprise à la réouverture
- Tester toutes les poses dans le simulateur Xcode 27.1 (Device Hub)

---

## 11. Technique

- **Stack.** Swift 5.10+, **SpriteKit** pour le jeu (2 SKView ou une scène scindée avec deux caméras, cible 60 fps constants), SwiftUI pour les menus/boutique/réglages
- **Rendu duo.** Une seule simulation du monde (un seed, une timeline), deux rendus caméra (piste B en rotation 180°). Les inputs sont routés par zone tactile (moitié haute/basse de l'écran physique)
- **Génération.** Chunks décrits en JSON (layout, tags difficulté, ancrages de pièces), assemblés par un LevelDirector seedé, tests unitaires sur la faisabilité des enchaînements (tout gouffre franchissable à la vitesse courante)
- **Physique.** Simplifiée maison (gravité, vélocité verticale, détection AABB), déterministe, PAS le moteur physique complet de SpriteKit pour le personnage (contrôle du game feel)
- **Persistance.** UserDefaults/SwiftData (pièces, skins, records, missions, achats en cache)
- **IAP.** StoreKit 2 (consommables pièces + non-consommable Premium, Family Sharing sur le Premium)
- **Pubs.** Un seul SDK de médiation léger, chargé UNIQUEMENT hors catégorie enfant, jamais au premier lancement, interstitiels préchargés hors gameplay
- **Game Center.** Classements et succès
- **Performances.** Atlas de textures par biome, préchargement du biome suivant pendant la transition, pooling des nodes d'obstacles, cible mémoire < 400 Mo

---

## 12. Mesure du succès

- Rétention J1 ≥ 30 %, J7 ≥ 12 % (standards runner casual)
- Durée de session moyenne ≥ 6 min, ≥ 2,5 runs par session
- Part des parties en mode duo ≥ 40 % sur iPad/Duo (c'est l'identité, à surveiller)
- Conversion payante (Premium ou pièces) ≥ 2,5 %
- Note App Store ≥ 4,5, mentions « à deux » dans les avis

---

## 13. Plan de développement (ordre pour Claude Code)

1. **Prototype solo.** Une piste, contrôles (saut, double saut, planer, glissade), défilement, chunks en dur, game feel AVANT tout le reste
2. **Génération procédurale.** LevelDirector seedé, chunks JSON, courbe de difficulté, tests de faisabilité
3. **Mode duo.** Double rendu tête-bêche, routage des inputs par zone, synchronisation du seed
4. **Chute et réanimation.** Bulle, pastille SOS, invincibilité, fin de partie
5. **Biome 1 (Western)** complet avec parallaxe, train, direction artistique de référence
6. **Économie.** Pièces, bonus partagés, missions, coffre du jour, persistance
7. **Écrans.** Accueil, placement duo, fin de run, boutique, réglages
8. **Biomes 2 et 3** (Montagnes, Jungle) + transitions de biome
9. **Monétisation.** StoreKit 2, Premium, packs de pièces, pubs récompensées puis interstitielles avec toutes les règles du §7
10. **Duo/iPad/adaptativité.** Size classes, charnière, pause au pliage, Game Center
11. **Polish.** Sons, musiques, haptique, accessibilité, performances
12. **QA et soumission.** Tests, captures App Store montrant le jeu À DEUX en premier

---

## 14. Backlog post-lancement

- Biomes 4 à 7 (Néon, Plage, Pharaons, Espace) au rythme d'un par mois
- Mode 2v2 sur iPad/Duo (4 zones tactiles, 2 équipes)
- Événements saisonniers (skins Halloween/Noël, biome enneigé remixé)
- Boss runs scriptés en fin de défi du jour
- Passe de saison LÉGER et uniquement cosmétique si la traction le justifie
- Localisation (EN, ES, DE, JA)
