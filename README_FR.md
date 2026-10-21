# Blue Jays - Hitting Analyst project

Analyse des données publiques de bat tracking (Statcast) : profils de
frappeurs MLB, modèle swing -> production, et fiches joueurs en Quarto.

## Organisation

```
blue-jays-hitting/
├── blue-jays-hitting.Rproj   <- TOUJOURS ouvrir le projet par ce fichier
├── run_all.R                 <- relance tout, du brut aux résultats
├── R/
│   ├── 00_setup.R            packages, paramètres, dossiers
│   ├── 01_import.R           données brutes -> data/raw/
│   ├── 02_clean_join.R       jointure -> data/processed/hitters.rds
│   ├── 03_analysis.R         modèle, profils, figures -> outputs/
│   └── 04_reports.R          génère les fiches joueurs -> reports/
├── data/
│   ├── raw/                  CSV bruts de Baseball Savant (ne jamais modifier)
│   └── processed/            données nettoyées
├── outputs/
│   ├── analysis.rds          résultats lus par la fiche
│   └── figures/              graphiques PNG
└── reports/
    ├── fiche_joueur.qmd      modèle de fiche (paramètre : joueur)
    └── fiche_*.html          fiches générées
```

## Ce qu'il faut lancer

1. Double-cliquer sur `blue-jays-hitting.Rproj` (RStudio s'ouvre dans le bon dossier).
2. Ouvrir `run_all.R` et cliquer sur **Source**.

C'est tout. Chaque script peut aussi être lancé seul : il recharge ce dont il a besoin.

## Données

- `bat_tracking_2025.csv` et `bat_tracking_2026.csv` : téléchargés à la main
  (Baseball Savant > Leaderboards > Bat Tracking > saison > Download CSV),
  car l'URL directe ignore l'année.
- `expected_stats_*.csv` et `ev_barrels_*.csv` : téléchargés automatiquement
  par `01_import.R`.

Pour mettre à jour une source : supprimer le fichier dans `data/raw/` et relancer.

## Points de contrôle

- `02_clean_join.R` s'arrête si les deux saisons de bat tracking sont identiques.
- Dans `03_analysis.R`, les profils sont nommés selon leur vitesse de batte
  moyenne (du plus lent au plus rapide) : Contact, Sous-puissance, Équilibré,
  Puissance brute. Vérifier dans le tableau `profils` que les noms collent
  aux chiffres (le profil "Contact" doit avoir le meilleur squared-up et le
  moins de whiffs).

## Discipline au bâton (discipline_*.csv)

Téléchargée automatiquement par `01_import.R` (Custom Leaderboard de Savant).
Si le script s'arrête sur ce fichier : Baseball Savant > Leaderboards >
Custom Leaderboard, type Batter, saison, Min PA = 25, colonnes :
PA, K%, BB%, Out of Zone Swing % (chase), Zone Swing %, In-Zone Contact %,
Swing %, puis Download CSV et enregistrer sous `data/raw/discipline_AAAA.csv`.
