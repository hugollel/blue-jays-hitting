# =============================================================
#  00_setup.R : packages, paramètres communs, dossiers
#  Appelé automatiquement par les autres scripts
# =============================================================

pkgs <- c("tidyverse", "jsonlite", "ggrepel", "here", "scales",
          "knitr", "rmarkdown", "quarto", "glue")
manquants <- pkgs[!pkgs %in% rownames(installed.packages())]
if (length(manquants) > 0) install.packages(manquants)
invisible(lapply(pkgs, library, character.only = TRUE))

# Paramètres du projet
SEASONS      <- c(2025, 2026)
SEASON_REF   <- 2026          # saison analysée en détail
JAYS_TEAM_ID <- 141           # identifiant MLB des Blue Jays
JAYS_COLOR   <- "#134A8E"

# Seuils d'échantillon
# - QUALIF_SWINGS : joueurs "qualifiés" (≈ 3,5 swings compétitifs par
#   match d'équipe). Ce sont eux qui servent de référence : modèle,
#   profils et percentiles sont calculés sur ce groupe uniquement.
# - MIN_SWINGS_FIABLE : en dessous, le joueur est signalé "petit échantillon"
# - MIN_DOWNLOAD : seuil utilisé pour les téléchargements élargis
QUALIF_SWINGS     <- 570
MIN_SWINGS_FIABLE <- 300
MIN_DOWNLOAD      <- 25     # balles en jeu minimum (expected stats, EV)

# Variables utilisées pour définir les profils de frappeurs
VARS_PROFIL <- c("avg_bat_speed", "swing_length",
                 "squared_up_per_swing", "whiff_per_swing")

# Dossiers (créés s'ils n'existent pas)
dir.create(here("data", "raw"),        recursive = TRUE, showWarnings = FALSE)
dir.create(here("data", "processed"),  recursive = TRUE, showWarnings = FALSE)
dir.create(here("outputs", "figures"), recursive = TRUE, showWarnings = FALSE)
