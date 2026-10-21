# =============================================================
#  01_import.R : récupération des données brutes -> data/raw/
#
#  - Expected stats et EV/Barrels : téléchargés automatiquement,
#    avec un seuil bas (MIN_DOWNLOAD balles en jeu) pour inclure
#    les remplaçants et les jeunes joueurs.
#  - Bat tracking : À TÉLÉCHARGER À LA MAIN (l'URL ignore l'année)
#      Baseball Savant > Leaderboards > Batting > Bat Tracking
#      choisir la saison + Min swings = 100 > Download CSV
#      enregistrer sous data/raw/bat_tracking_2025.csv, etc.
#
#  Un fichier déjà présent n'est jamais retéléchargé.
#  Pour forcer une mise à jour : supprimer le fichier dans data/raw/
# =============================================================

source(here::here("R", "00_setup.R"))

savant <- "https://baseballsavant.mlb.com/leaderboard/"

telecharger <- function(type, year, extra, fichier) {
  dest <- here("data", "raw", fichier)
  if (file.exists(dest)) {
    message("Déjà présent : ", fichier)
    return(invisible(dest))
  }
  url <- paste0(savant, type, "?year=", year, extra, "&csv=true")
  message("Téléchargement : ", fichier)
  download.file(url, dest, quiet = TRUE, mode = "wb")
  invisible(dest)
}

for (y in SEASONS) {
  telecharger("expected_statistics", y,
              paste0("&type=batter&filterType=bip&min=", MIN_DOWNLOAD),
              paste0("expected_stats_", y, ".csv"))
  telecharger("statcast", y,
              paste0("&type=batter&min=", MIN_DOWNLOAD),
              paste0("ev_barrels_", y, ".csv"))
}

# Discipline au bâton (Custom Leaderboard) : chase, BB%, K%...
SELECTIONS_DISCIPLINE <- c("pa", "k_percent", "bb_percent", "oz_swing_percent",
                           "z_swing_percent", "iz_contact_percent",
                           "swing_percent")
for (y in SEASONS) {
  telecharger("custom", y,
              paste0("&type=batter&min=", MIN_DOWNLOAD, "&selections=",
                     paste(SELECTIONS_DISCIPLINE, collapse = ","),
                     "&chart=false"),
              paste0("discipline_", y, ".csv"))

  d <- read_csv(here("data", "raw", paste0("discipline_", y, ".csv")),
                show_col_types = FALSE) |>
    rename_with(~ sub("^\ufeff", "", .x))
  manquantes <- setdiff(c("player_id", "year", "oz_swing_percent",
                          "k_percent", "bb_percent"), names(d))
  if (length(manquantes) > 0 || !all(d$year == y)) {
    stop("Problème dans discipline_", y, ".csv (colonnes manquantes : ",
         paste(manquantes, collapse = ", "), " ou mauvaise saison).\n",
         "-> Supprimer le fichier et le télécharger à la main depuis ",
         "Baseball Savant > Custom Leaderboard (voir README).")
  }
}

# Vérification des fichiers bat tracking (téléchargement manuel)
attendus <- paste0("bat_tracking_", SEASONS, ".csv")
absents  <- attendus[!file.exists(here("data", "raw", attendus))]
if (length(absents) > 0) {
  stop("Fichier(s) manquant(s) dans data/raw/ : ",
       paste(absents, collapse = ", "),
       "\n-> Baseball Savant > Leaderboards > Bat Tracking, choisir la saison, Download CSV.")
}

# Contrôle de la taille des fichiers : un fichier "élargi" doit
# contenir nettement plus de joueurs que les ~210-250 qualifiés
cat("\nNombre de joueurs par fichier :\n")
for (f in list.files(here("data", "raw"), pattern = "\\.csv$")) {
  n <- nrow(read_csv(here("data", "raw", f), show_col_types = FALSE))
  cat(sprintf("  %-28s %4d %s\n", f, n,
              if (n < 300) "<- seuil bas probablement non appliqué" else ""))
}
