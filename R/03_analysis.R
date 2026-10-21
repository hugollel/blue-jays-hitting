# =============================================================
#  03_analysis.R : modèle, profils, percentiles, évolution, figures
#  Entrée  : data/processed/hitters.rds
#  Sorties : outputs/analysis.rds (lu par les fiches Quarto)
#            outputs/figures/*.png
#
#  Principe : tout ce qui sert de RÉFÉRENCE (modèle, profils,
#  percentiles) est calculé sur les joueurs qualifiés uniquement.
#  Les autres joueurs (remplaçants, jeunes) sont ensuite situés
#  par rapport à cette référence.
# =============================================================

source(here::here("R", "00_setup.R"))

hitters <- readRDS(here("data", "processed", "hitters.rds")) |>
  mutate(qualifie          = swings_competitive >= QUALIF_SWINGS,
         petit_echantillon = swings_competitive <  MIN_SWINGS_FIABLE)

d_ref <- hitters |> filter(season == SEASON_REF)
d_q   <- d_ref |> filter(qualifie)

cat("\nSaison", SEASON_REF, ":", nrow(d_ref), "joueurs dont",
    nrow(d_q), "qualifiés\n")
cat("Jays :", sum(d_ref$jays), "joueurs dont",
    sum(d_ref$jays & d_ref$qualifie), "qualifiés\n\n")

# -------------------------------------------------------------
# 1. MODÈLE (qualifiés) : qu'est-ce qui explique le xwOBA ?
# -------------------------------------------------------------
mod <- lm(
  scale(est_woba) ~ scale(avg_bat_speed) + scale(swing_length) +
    scale(squared_up_per_swing) + scale(whiff_per_swing),
  data = d_q
)
print(summary(mod))

# Modèle 2 : + décisions au bâton (chase, swings dans la zone).
# On n'ajoute PAS K% et BB% : ce sont des résultats déjà comptés dans
# le xwOBA, le R² monterait mécaniquement.
mod_dec <- lm(
  scale(est_woba) ~ scale(avg_bat_speed) + scale(swing_length) +
    scale(squared_up_per_swing) + scale(whiff_per_swing) +
    scale(oz_swing_percent) + scale(z_swing_percent),
  data = d_q
)
print(summary(mod_dec))
cat("R² swing seul :", round(summary(mod)$r.squared, 3),
    "| avec décisions :", round(summary(mod_dec)$r.squared, 3), "\n")

# -------------------------------------------------------------
# 2. PROFILS : k-means sur les qualifiés, puis chaque joueur
#    (qualifié ou non) est rattaché au profil le plus proche.
#    Les profils sont nommés selon leur vitesse de batte moyenne.
# -------------------------------------------------------------
X       <- scale(d_q[VARS_PROFIL])
centre  <- attr(X, "scaled:center")
echelle <- attr(X, "scaled:scale")

set.seed(42)
wss <- map_dbl(2:7, ~ kmeans(X, centers = .x, nstart = 25)$tot.withinss)
km  <- kmeans(X, centers = 4, nstart = 25)

NOMS_PROFILS <- c("Contact", "Sous-puissance", "Équilibré", "Puissance brute")
noms <- character(4)
noms[order(km$centers[, "avg_bat_speed"])] <- NOMS_PROFILS

Z <- scale(as.matrix(d_ref[VARS_PROFIL]), center = centre, scale = echelle)
cluster <- apply(Z, 1, function(z) which.min(colSums((t(km$centers) - z)^2)))
d_ref$profil <- factor(noms[cluster], levels = NOMS_PROFILS)

profils <- d_ref |>
  filter(qualifie) |>
  group_by(profil) |>
  summarise(n = n(),
            across(all_of(c(VARS_PROFIL, "brl_percent", "est_woba")),
                   ~ round(mean(.x, na.rm = TRUE), 3)))
print(profils, width = Inf)
# -> Vérifier que les noms collent aux chiffres (voir README)

# -------------------------------------------------------------
# 3. PERCENTILES (1-100) par rapport aux qualifiés
#    Pour les whiffs, moins = mieux : percentile inversé.
#    La longueur de swing n'est pas inversée (compromis, affichée neutre).
# -------------------------------------------------------------
METRIQUES_FICHE <- c("avg_bat_speed", "swing_length", "squared_up_per_swing",
                     "blast_per_swing", "whiff_per_swing", "avg_hit_speed",
                     "brl_percent", "est_woba",
                     "oz_swing_percent", "bb_percent", "k_percent")
INVERSEES <- c("whiff_per_swing", "oz_swing_percent", "k_percent")

pct_vs_ref <- function(x, ref, inverse = FALSE) {
  ref <- ref[!is.na(ref)]
  if (inverse) { x <- -x; ref <- -ref }
  pmax(1, round(100 * ecdf(ref)(x)))
}

for (v in METRIQUES_FICHE) {
  d_ref[[paste0("pct_", v)]] <- pct_vs_ref(d_ref[[v]], d_q[[v]],
                                           v %in% INVERSEES)
}

# -------------------------------------------------------------
# 4. ÉVOLUTION ENTRE LES DEUX SAISONS (qualifiés les deux années)
# -------------------------------------------------------------
evol <- hitters |>
  filter(qualifie) |>
  select(player_id, name, season, jays,
         avg_bat_speed, swing_length, squared_up_per_swing,
         whiff_per_swing, est_woba) |>
  pivot_wider(names_from = season,
              values_from = c(jays, avg_bat_speed, swing_length,
                              squared_up_per_swing, whiff_per_swing,
                              est_woba)) |>
  drop_na() |>
  mutate(
    jays        = .data[[paste0("jays_", SEASON_REF)]],
    d_bat_speed = .data[[paste0("avg_bat_speed_", SEASON_REF)]] -
                  .data[[paste0("avg_bat_speed_", SEASON_REF - 1)]],
    d_xwoba     = .data[[paste0("est_woba_", SEASON_REF)]] -
                  .data[[paste0("est_woba_", SEASON_REF - 1)]]
  )

print(cor.test(evol$d_bat_speed, evol$d_xwoba))

# -------------------------------------------------------------
# 5. FIGURES (fond = qualifiés, étiquettes = tous les Jays)
# -------------------------------------------------------------
d_qp     <- filter(d_ref, qualifie)
jays_ref <- filter(d_ref, jays)

g_tradeoff <- ggplot(d_qp, aes(swing_length, avg_bat_speed)) +
  geom_point(aes(colour = est_woba), size = 2.5, alpha = 0.8) +
  geom_smooth(method = "lm", se = FALSE, colour = "grey40", linetype = 2) +
  geom_point(data = jays_ref, shape = 21, size = 4.5, stroke = 1.2,
             colour = JAYS_COLOR) +
  geom_text_repel(data = jays_ref, aes(label = name), size = 3,
                  colour = JAYS_COLOR, max.overlaps = Inf) +
  scale_colour_viridis_c(name = "xwOBA") +
  labs(title = paste("Bat speed vs swing length - MLB", SEASON_REF),
       subtitle = "Circled: Blue Jays hitters",
       x = "Swing length (ft)", y = "Average bat speed (mph)") +
  theme_minimal()

g_profils <- ggplot(d_qp, aes(swing_length, avg_bat_speed, colour = profil)) +
  geom_point(size = 2.5, alpha = 0.8) +
  geom_text_repel(data = jays_ref, aes(label = name), size = 3,
                  colour = "black", max.overlaps = Inf) +
  scale_colour_discrete(labels = c("Contact" = "Contact hitter",
                                   "Sous-puissance" = "Under-powered",
                                   "Équilibré" = "Balanced",
                                   "Puissance brute" = "Raw power")) +
  labs(title = paste("Hitter profiles - MLB", SEASON_REF),
       x = "Swing length (ft)", y = "Average bat speed (mph)",
       colour = "Profile") +
  theme_minimal()

g_evol <- ggplot(evol, aes(d_bat_speed, d_xwoba)) +
  geom_hline(yintercept = 0, colour = "grey70") +
  geom_vline(xintercept = 0, colour = "grey70") +
  geom_point(aes(colour = jays), alpha = 0.7) +
  geom_smooth(method = "lm", colour = JAYS_COLOR) +
  scale_colour_manual(values = c(`FALSE` = "grey60", `TRUE` = JAYS_COLOR),
                      name = "Blue Jays") +
  labs(title = paste("Change", SEASON_REF - 1, "->", SEASON_REF),
       x = "Change in bat speed (mph)", y = "Change in xwOBA") +
  theme_minimal()

ggsave(here("outputs", "figures", "01_tradeoff.png"), g_tradeoff,
       width = 8, height = 6, dpi = 300, bg = "white")
ggsave(here("outputs", "figures", "02_profils.png"), g_profils,
       width = 8, height = 6, dpi = 300, bg = "white")
ggsave(here("outputs", "figures", "03_evolution.png"), g_evol,
       width = 8, height = 6, dpi = 300, bg = "white")

# -------------------------------------------------------------
# 6. SAUVEGARDE
# -------------------------------------------------------------
saveRDS(
  list(d_ref = d_ref, hitters = hitters, evol = evol,
       profils = profils, mod = mod, mod_dec = mod_dec, wss = wss),
  here("outputs", "analysis.rds")
)

message("Analyse terminée : outputs/analysis.rds + 3 figures dans outputs/figures/")
