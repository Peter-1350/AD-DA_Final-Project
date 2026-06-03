library(tidyverse)
library(broom)
library(performance)
library(scales)
library(patchwork)
library(viridis)
library(cluster)
library(naniar)

`%||%` <- function(x, y) if (is.null(x)) y else x

base_dir <- normalizePath(file.path(getwd(), "data", "FIFA"), winslash = "/", mustWork = FALSE)
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
      pace_total = `Pace Total`,
      shooting_total = `Shooting Total`,
      passing_total = `Passing Total`,
      dribbling_total = `Dribbling Total`,
      defending_total = `Defending Total`,
      physicality_total = `Physicality Total`,
      best_position = `Best Position`,
      positions_played = `Positions Played`,
      nationality = Nationality,
      nationality = str_squish(nationality),
      best_position = str_squish(best_position),
      positions_played = str_squish(positions_played),
      position_group = case_when(
        best_position %in% c("ST", "LW", "RW", "CF", "LF", "RF", "CAM") ~ "Attack",
        best_position %in% c("CM", "CDM", "RM", "LM", "RWB", "LWB") ~ "Midfield",
        best_position %in% c("CB", "RB", "LB") ~ "Defense",
        best_position == "GK" ~ "GK",
        TRUE ~ "Other"
      ),
      position_group = factor(position_group, levels = c("Attack", "Midfield", "Defense", "GK", "Other")),
      log_value = log10(value_eur),
      log_wage = log10(wage_eur + 1)
    )
}

top_level_factor <- function(x, n = 12, other_level = "Other") {
  tab <- sort(table(x), decreasing = TRUE)
  keep <- names(tab)[seq_len(min(n, length(tab)))]
  out <- ifelse(x %in% keep, as.character(x), other_level)
  factor(out, levels = c(other_level, keep))
}

group_by_nationality_band <- function(x) {
  top_level_factor(x, n = 12, other_level = "Other")
}

fifa_df <- prep_fifa()
