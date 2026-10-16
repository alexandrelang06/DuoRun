# Duo Run — Étude de marché App Store (runner coopératif)

Méthode : skill *app-store-product-researcher* appliqué via l'API publique iTunes (stores US + FR).
Données réelles. Date : 12/09/2026.

---

## 1. Paysage concurrentiel

Mots-clés : « endless runner », « 2 player runner », « co-op runner », « couch co-op »,
« runner offline », « run race 2 player », + FR « runner infini », « course à deux ».

**Store US (132 apps), tête de classement :**

| App | Éditeur | Prix | Note | Avis |
|-----|---------|------|------|------|
| Subway Surfers | Sybo | Free | 4.6 | 3 828 754 |
| Fun Race 3D | AI Games | Free | 4.6 | 805 036 |
| Crossy Road | Hipster Whale | Free | 4.7 | 736 023 |
| Count Masters: Crowd Runner | Freeplay | Free | 4.5 | 598 812 |
| Talking Tom Gold Run | Outfit7 | Free | 4.5 | 559 877 |
| Temple Run 2 | Imangi | Free | 4.5 | 494 339 |
| Sonic Dash | Sega | Free | 4.7 | 417 946 |
| Jetpack Joyride, Into the Dead 2… | (classiques du genre) | Free | 4.6 | — |

**Store FR (48 apps) :** Subway Surfers (542k), Rider (Ketchapp, 99k), Jetpack Joyride, Into the Dead 2.

Constats structurants :
- Genre **massif et 100 % gratuit** (avec pub + IAP), un des plus gros du casual.
- **Tous les leaders sont SOLO.** Aucun runner **coopératif à deux sur le même appareil** n'apparaît
  dans les résultats. Le seul « 2 joueurs » du haut de liste est la collection de mini-jeux Jindoblu.
- Le sous-genre « jouer ensemble sur un seul téléphone » est donc **une case blanche** dans un
  marché saturé, exactement le pari de Duo Run.

---

## 2. Où est la faille

Les runners qui font du multijoueur le font **en ligne** (course contre des inconnus, façon Fun Race
3D). Personne n'occupe le **canapé / une seule surface / deux joueurs qui s'entraident**. Or :
- la nostalgie du jeu à deux sur un écran est un moteur émotionnel fort (cf. le succès des collections
  « 2 player games » de Jindoblu, 400k+ avis) ;
- la mécanique **coopérative** (se sauver l'un l'autre) est quasi absente du genre runner, dominé par
  la compétition solo ou le versus.

Duo Run combine les deux briques qui marchent séparément (runner infini + jeu à deux local) que
**personne n'a encore fusionnées**.

---

## 3. Angles pour Duo Run

| Réalité du marché | Angle de Duo Run |
|-------------------|------------------|
| Runners = solo, on court seul | **Se jouer à DEUX sur un écran**, s'entraider (revive) |
| Multijoueur = en ligne, contre inconnus | **Local, hors-ligne, face à face** (canapé, table) |
| Pubs agressives, parfois pendant le jeu | Pub **jamais pendant une partie ni un sauvetage** (PRD §7) |
| Marché énorme mais indifférencié | **iPhone Duo déplié** = expérience signature (la charnière sépare les pistes) |

Double marché : le **solo** capte la demande massive du genre (pas gaté au Duo), et le **coop/Duo**
est le différenciateur qui fait parler (« à jouer à deux ! » dans les avis, objectif du PRD §12).

---

## 4. Positionnement & ASO

- **Accroche** : « Courez à deux sur un seul écran. Sauvez-vous l'un l'autre. »
- **Nom / sous-titre** : « Duo Run » / « Runner à deux sur un écran ».
- **Mots-clés** : `runner,endless,2 joueurs,coop,a deux,course,infini,iphone duo,hors ligne,canapé,famille`.
- **Captures** : montrer d'ABORD le jeu à deux (écran scindé, deux personnages), puis le solo.
- Le seul autre acteur qui pourrait bouger vite : un gros éditeur de runner qui ajoute un mode coop
  local. À surveiller.

---

## 5. Monétisation (cf. PRD §7)

F2P propre, éprouvé sur le genre : interstitiels rares (1 toutes les 3 parties, jamais en jeu), pub
récompensée opt-in, packs de pièces, Premium 4,99 € qui retire les pubs. Cohérent avec le reste du
portefeuille (pas de dark pattern). Le plafond de revenu dépend surtout du volume, d'où l'importance
du mode solo pour l'acquisition.

---

## 6. Score de viabilité (/10)

| Dimension | Note | Justification |
|-----------|------|---------------|
| Douleur / demande | 7 | Demande de runner énorme + envie réelle de jouer à deux, sous-servie |
| Taille du marché | 8 | Endless runner = genre casual majeur ; le solo capte le gros du marché |
| Faille concurrentielle | 8 | Aucun runner coop local dominant + angle iPhone Duo unique |
| Monétisation | 6 | F2P propre éprouvé, mais volontairement moins agressif que les concurrents |
| Difficulté de build | 5 | Jeu temps réel SpriteKit + génération procédurale + rendu duo = le plus complexe des trois apps |

**Score global ≈ 6,8 / 10 — verdict : GO, meilleur potentiel de marché des trois apps** (le solo
ouvre le genre le plus large), mais aussi **le plus gros effort technique**. La réussite dépendra du
game feel (le PRD a raison de le mettre en priorité n°1) et de captures qui vendent le « à deux ».

---

## 7. À valider
- Estimations de téléchargements/revenus (Sensor Tower) non fiables sans clé : ignorées.
- Surveiller si un gros éditeur de runner sort un mode coop local.
