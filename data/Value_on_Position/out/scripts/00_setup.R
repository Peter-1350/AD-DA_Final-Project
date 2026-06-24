library(tidyverse)
library(broom)
library(performance)
library(car)
library(patchwork)
library(scales)
library(viridis)
library(naniar)

`%||%` <- function(x, y) if (is.null(x)) y else x

base_dir <- normalizePath(file.path(getwd(), "data", "Value_on_Position"),
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

read_value_position_data <- function() {
  readr::read_csv(data_path, show_col_types = FALSE) %>%
    rename_with(~ str_squish(.x)) %>%
    mutate(
      value_eur = `Value(in Euro)`,
      wage_eur = `Wage(in Euro)`,
      age = Age,
      overall = Overall,
      potential = Potential,
      total_stats = TotalStats,
      base_stats = BaseStats,
      best_position = str_squish(`Best Position`),
      best_position = factor(best_position),
      position_group = case_when(
        best_position %in% c("ST", "LW", "RW", "CF", "LF", "RF", "CAM") ~ "Attack",
        best_position %in% c("CM", "CDM", "RM", "LM", "RWB", "LWB") ~ "Midfield",
        best_position %in% c("CB", "RB", "LB") ~ "Defense",
        best_position == "GK" ~ "GK",
        TRUE ~ "Other"
      ),
      position_group = factor(position_group, levels = c("Attack", "Midfield", "Defense", "GK", "Other")),
      best_position = factor(best_position),
      pace_total = `Pace Total`,
      shooting_total = `Shooting Total`,
      passing_total = `Passing Total`,
      dribbling_total = `Dribbling Total`,
      defending_total = `Defending Total`,
      physicality_total = `Physicality Total`,
      log_value = log10(value_eur + 1),
      age_z = as.numeric(scale(age)),
      total_stats_z = as.numeric(scale(total_stats)),
      pace_z = as.numeric(scale(pace_total)),
      shooting_z = as.numeric(scale(shooting_total)),
      passing_z = as.numeric(scale(passing_total)),
      dribbling_z = as.numeric(scale(dribbling_total)),
      defending_z = as.numeric(scale(defending_total)),
      physicality_z = as.numeric(scale(physicality_total))
    )
}

value_df <- read_value_position_data()
