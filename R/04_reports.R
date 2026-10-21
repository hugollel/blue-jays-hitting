# =============================================================
#  04_reports.R : génère les rapports -> reports/
#   1. une fiche par frappeur des Jays de la saison de référence
#   2. la vue équipe (qui renvoie vers chaque fiche)
#  Entrée : outputs/analysis.rds (créé par 03_analysis.R)
# =============================================================

source(here::here("R", "00_setup.R"))

slug_joueur <- function(x) x |>
  stringi::stri_trans_general("Latin-ASCII") |>
  str_replace_all("[^A-Za-z]+", "_") |>
  str_remove("_$")

render_fiche <- function(joueur) {
  quarto::quarto_render(
    input          = here("reports", "fiche_joueur.qmd"),
    execute_params = list(joueur = joueur),
    output_file    = paste0("fiche_", slug_joueur(joueur), ".html"),
    quiet          = TRUE
  )
}

# 1. Fiches individuelles -------------------------------------------
res <- readRDS(here("outputs", "analysis.rds"))
jays_ref <- res$d_ref |>
  filter(jays) |>
  arrange(desc(swings_competitive)) |>
  pull(name)

for (j in jays_ref) {
  message("Fiche : ", j)
  tryCatch(render_fiche(j),
           error = function(e) message("  -> ÉCHEC : ", conditionMessage(e)))
}

# 2. Vue équipe (après les fiches, pour que les liens existent) ------
message("Vue équipe")
quarto::quarto_render(
  input       = here("reports", "vue_equipe.qmd"),
  output_file = paste0("vue_equipe_", SEASON_REF, ".html"),
  quiet       = TRUE
)

# 3. Vue ligue = page d'accueil du projet (index.html) ----------------
message("Vue ligue")
quarto::quarto_render(
  input       = here("reports", "index.qmd"),
  output_file = "index.html",
  quiet       = TRUE
)

# 4. Copie des pages HTML dans docs/ (dossier publié par GitHub Pages) --
dir.create(here("docs"), showWarnings = FALSE)
pages <- list.files(here("reports"), pattern = "\\.html$", full.names = TRUE)
file.copy(pages, here("docs"), overwrite = TRUE)

message("Terminé : ", length(pages), " pages dans reports/ et docs/ ",
        "(point d'entrée : index.html)")

# Pour une seule fiche :
# render_fiche("Clement, Ernie")
