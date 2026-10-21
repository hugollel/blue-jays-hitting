# =============================================================
#  run_all.R : relance tout le projet, du brut aux fiches
#  Ouvrir blue-jays-hitting.Rproj, puis lancer ce fichier (Source)
# =============================================================

source(here::here("R", "01_import.R"))
source(here::here("R", "02_clean_join.R"))
source(here::here("R", "03_analysis.R"))
source(here::here("R", "04_reports.R"))
