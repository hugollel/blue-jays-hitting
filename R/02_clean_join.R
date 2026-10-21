# =============================================================
#  02_clean_join.R : nettoyage + jointure -> data/processed/hitters.rds
#  Une ligne = un joueur x une saison
# =============================================================

source(here::here("R", "00_setup.R"))

lire <- function(prefixe, y) {
  read_csv(here("data", "raw", paste0(prefixe, "_", y, ".csv")),
           show_col_types = FALSE) |>
    rename_with(~ sub("^﻿", "", .x)) |>   # retire un éventuel BOM
    mutate(season = y)
}

bat <- map_dfr(SEASONS, ~ lire("bat_tracking", .x)) |>
  rename(player_id = id)

xst <- map_dfr(SEASONS, ~ lire("expected_stats", .x)) |>
  select(player_id, season, pa, woba, est_woba, est_ba, est_slg)

evb <- map_dfr(SEASONS, ~ lire("ev_barrels", .x)) |>
  select(player_id, season, avg_hit_speed, max_hit_speed,
         avg_hit_angle, ev95percent, brl_percent)

dis <- map_dfr(SEASONS, ~ lire("discipline", .x)) |>
  select(player_id, season, k_percent, bb_percent, oz_swing_percent,
         z_swing_percent, iz_contact_percent)

# --- Contrôle : les deux saisons de bat tracking doivent différer ---
part_identiques <- bat |>
  select(player_id, season, avg_bat_speed) |>
  pivot_wider(names_from = season, values_from = avg_bat_speed,
              names_prefix = "bs_") |>
  drop_na() |>
  summarise(p = mean(.data[[paste0("bs_", SEASONS[1])]] ==
                       .data[[paste0("bs_", SEASONS[2])]])) |>
  pull(p)

if (part_identiques > 0.9) {
  stop("Les fichiers bat tracking ", SEASONS[1], " et ", SEASONS[2],
       " semblent identiques : vérifier data/raw/.")
}

# --- Jointure ---
hitters <- bat |>
  inner_join(xst, by = c("player_id", "season")) |>
  inner_join(evb, by = c("player_id", "season")) |>
  left_join(dis, by = c("player_id", "season"))   # left : on ne perd personne

# --- Joueurs des Blue Jays (API officielle MLB) ---
get_roster <- function(season) {
  url <- paste0("https://statsapi.mlb.com/api/v1/teams/", JAYS_TEAM_ID,
                "/roster?rosterType=fullSeason&season=", season)
  fromJSON(url)$roster$person$id
}
# Effectif saison par saison : un joueur n'est "Jays" que pour les
# saisons où il était dans l'effectif (évite de marquer en 2026 un
# joueur parti après 2025).
jays_roster <- map_dfr(SEASONS, ~ tibble(season    = .x,
                                         player_id = get_roster(.x))) |>
  distinct() |>
  mutate(jays = TRUE)

hitters <- hitters |>
  left_join(jays_roster, by = c("player_id", "season")) |>
  mutate(jays = coalesce(jays, FALSE))

message("Joueurs des Jays par saison :")
print(hitters |> filter(jays) |> count(season))

saveRDS(hitters, here("data", "processed", "hitters.rds"))

message("Données prêtes : ", nrow(hitters), " lignes joueur-saison")
print(table(hitters$season))
