library(tidyverse)
library(broom)
library(nnet)
library(car)
library(effectsize)
library(performance)
library(patchwork)
library(viridis)
library(naniar)
library(scales)

`%||%` <- function(x, y) if (is.null(x)) y else x

base_dir <- normalizePath(file.path(getwd(), "data", "Work_Rate"), winslash = "/", mustWork = FALSE)
out_dir <- file.path(base_dir, "out")
scripts_dir <- file.path(out_dir, "scripts")
fig_dir <- file.path(out_dir, "figs")
dir.create(out_dir, showWarnings = FALSE, recursive = TRUE)
dir.create(scripts_dir, showWarnings = FALSE, recursive = TRUE)
dir.create(fig_dir, showWarnings = FALSE, recursive = TRUE)

data_path <- normalizePath(file.path(base_dir, "FIFA 23 Players.csv"), winslash = "/", mustWork = TRUE)

theme_set(theme_minimal(base_size = 15))

save_poster_fig <- function(plot, path, width = 8, height = 6) {
  title <- plot$labels$title %||% ""
  subtitle <- plot$labels$subtitle %||% ""
  if (nchar(title) > 60) warning("Title too long (", nchar(title), " chars): ", title)
  if (nchar(subtitle) > 80) warning("Subtitle too long (", nchar(subtitle), " chars): ", subtitle)
  ggsave(path, plot = plot, width = width, height = height, dpi = 300)
}

prep_workrate <- function() {
  readr::read_csv(data_path, show_col_types = FALSE) %>%
    mutate(
      attack_wr = factor(`Attacking Work Rate`, levels = c("Low", "Medium", "High"), ordered = TRUE),
      defend_wr = factor(`Defensive Work Rate`, levels = c("Low", "Medium", "High"), ordered = TRUE),
      position_group = case_when(
        `Best Position` == "GK" ~ "Goalkeeper",
        `Best Position` %in% c("ST", "CF", "LW", "RW", "LF", "RF", "CAM") ~ "Forward",
        `Best Position` %in% c("CM", "CDM", "LM", "RM", "LWB", "RWB") ~ "Midfielder",
        `Best Position` %in% c("CB", "LB", "RB") ~ "Defender",
        TRUE ~ "Other"
      ) %>% factor(levels = c("Forward", "Midfielder", "Defender", "Goalkeeper", "Other")),
      age_z = as.numeric(scale(Age)),
      height_z = as.numeric(scale(`Height(in cm)`)),
      weight_z = as.numeric(scale(`Weight(in kg)`)),
      stamina_z = as.numeric(scale(Stamina)),
      aggression_z = as.numeric(scale(Aggression))
    )
}

workrate_df <- prep_workrate()

