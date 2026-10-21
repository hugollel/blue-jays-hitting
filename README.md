# What Drives MLB Hitting Production? – Bat tracking, swing profiles and development levers

A reproducible R + Quarto pipeline that turns public Statcast data into
league, team and player-level hitting development reports.

**Live reports:** `https://hugollel.github.io/blue-jays-hitting/`

| Page | Audience | Question it answers |
|---|---|---|
| League overview (`index.html`) | Research, decision-makers | What drives hitting production? Which hitter profiles exist? |
| Blue Jays team overview | Player development staff | Where should development time go, and for whom? |
| Player reports (one per hitter) | Coaches, players | What is this hitter's profile, main lever and plan? |

## Key findings (2026, 232 qualified hitters)

- **Bat speed is the strongest driver of production**: about +10 points of xwOBA per mph
  between hitters, and about +11 points per mph *within* the same hitter from 2025 to 2026.
- **Efficiency matters**: at equal bat speed, a longer swing tends to go with lower production.
- **No single ideal swing**: four hitter profiles reach similar production by different routes.
- **Public data explains about half of the picture** (adjusted R² ≈ 0.41 for swing metrics,
  ≈ 0.45 with swing decisions); the rest is where biomechanics data adds the most value.

## Method

- **Data:** Baseball Savant public leaderboards – bat tracking, expected statistics,
  exit velocity & barrels, plate discipline (2025–2026).
- **Reference group:** qualified hitters (570+ competitive swings). Models, profiles
  and percentiles are built on this group; hitters with fewer swings are placed
  against it and flagged as small samples.
- **Models:** standardised linear models of xwOBA on swing and decision metrics;
  k-means profiles on bat speed, swing length, squared-up and whiff rates;
  year-over-year change analysis.
- **Limits:** cross-sectional associations, not causal effects; no biomechanical,
  force-plate or timing data.

## Structure

```
R/
  00_setup.R        packages and parameters
  01_import.R       downloads raw data (some files are downloaded manually, see script)
  02_clean_join.R   joins sources, flags Blue Jays hitters season by season
  03_analysis.R     models, profiles, percentiles, year-over-year
  04_reports.R      renders all reports and copies them to docs/
reports/
  index.qmd         league overview
  vue_equipe.qmd    team overview
  fiche_joueur.qmd  parameterised player report
docs/               rendered HTML pages (published with GitHub Pages)
run_all.R           runs the full pipeline
```

To reproduce: open `blue-jays-hitting.Rproj` in RStudio and run `run_all.R`.

---
Hugo Leligny · Built with R (tidyverse, ggplot2) and Quarto.
