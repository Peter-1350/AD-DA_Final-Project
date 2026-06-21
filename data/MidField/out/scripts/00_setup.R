library(tidyverse)
library(broom)
library(performance)
library(scales)
library(patchwork)
library(viridis)
library(naniar)

`%||%` <- function(x, y) if (is.null(x)) y else x

base_dir <- normalizePath(file.path(getwd(), "data", "MidField"),
                          winslash = "/", mustWork = FALSE)
out_dir <- file.path(base_dir, "out")
scripts_dir <- file.path(out_dir, "scripts")
fig_dir <- file.path(out_dir, "figs")
dir.create(out_dir, showWarnings = FALSE, recursive = TRUE)
dir.create(scripts_dir, showWarnings = FALSE, recursive = TRUE)
dir.create(fig_dir, showWarnings = FALSE, recursive = TRUE)

data_path <- normalizePath(file.path(getwd(), "data", "FIFA 23 Players.csv"),
                           winslash = "/", mustWork = TRUE)

theme_set(theme_minimal(base_size = 15))

save_poster_fig <- function(plot, path, width = 8, height = 6) {
  title <- plot$labels$title %||% ""
  subtitle <- plot$labels$subtitle %||% ""
  if (nchar(title) > 60) warning("Title too long (", nchar(title), " chars): ", title)
  if (nchar(subtitle) > 80) warning("Subtitle too long (", nchar(subtitle), " chars): ", subtitle)
  ggsave(path, plot = plot, width = width, height = height, dpi = 300)
}

prep_fifa <- function() {
  readr::read_csv(data_path, show_col_types = FALSE) %>%
    mutate(
      value_eur = `Value(in Euro)`,
      wage_eur = `Wage(in Euro)`,
      overall = Overall,
      potential = Potential,
      total_stats = TotalStats,
      base_stats = BaseStats,
      age = Age,
      height_cm = `Height(in cm)`,
      weight_kg = `Weight(in kg)`,
      best_position = str_squish(`Best Position`),
      positions_played = str_squish(`Positions Played`),
      nationality = str_squish(Nationality),
      preferred_foot = str_squish(`Preferred Foot`),
      weak_foot_rating = `Weak Foot Rating`,
      international_reputation = `International Reputation`,
      shooting_total = `Shooting Total`,
      passing_total = `Passing Total`,
      dribbling_total = `Dribbling Total`,
      defending_total = `Defending Total`,
      pace_total = `Pace Total`,
      physicality_total = `Physicality Total`,
      position_group = case_when(
        best_position %in% c("ST", "LW", "RW", "CF", "LF", "RF") ~ "Attack",
        best_position %in% c("CAM", "CM", "CDM", "LM", "RM") ~ "Midfield",
        best_position %in% c("CB", "RB", "LB", "RWB", "LWB") ~ "Defense",
        best_position == "GK" ~ "GK",
        TRUE ~ "Other"
      ),
      position_group = factor(position_group, levels = c("Attack", "Midfield", "Defense", "GK", "Other")),
      preferred_foot = factor(preferred_foot, levels = c("Left", "Right")),
      weak_foot_rating = factor(weak_foot_rating, levels = 1:5, ordered = TRUE),
      log_value = log10(value_eur + 1),
      log_wage = log10(wage_eur + 1)
    )
}

fifa_df <- prep_fifa()

