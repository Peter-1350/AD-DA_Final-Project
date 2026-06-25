library(tidyverse)
library(broom)
library(performance)
library(effectsize)
library(car)
library(rstatix)
library(emmeans)
library(patchwork)
library(scales)
library(viridis)

root_dir <- normalizePath(file.path("data", "Nationality", "out"), winslash = "/", mustWork = FALSE)
fig_dir <- file.path(root_dir, "figs")
out_dir <- root_dir
dir.create(fig_dir, recursive = TRUE, showWarnings = FALSE)

raw_path <- file.path("data", "FIFA 23 Players.csv")

theme_poster <- function(base_size = 16) {
  theme_minimal(base_size = base_size) +
    theme(
      plot.title = element_text(face = "bold", size = base_size + 2),
      plot.subtitle = element_text(color = "grey30", size = base_size - 2),
      plot.caption = element_text(color = "grey45", size = base_size - 5, hjust = 0),
      panel.grid.minor = element_blank(),
      legend.position = "bottom"
    )
}

save_poster_fig <- function(plot, filename, width = 8, height = 6) {
  title <- plot$labels$title %||% ""
  subtitle <- plot$labels$subtitle %||% ""
  if (nchar(title) > 70) warning("Long title (", nchar(title), " chars): ", title)
  if (nchar(subtitle) > 95) warning("Long subtitle (", nchar(subtitle), " chars): ", subtitle)
  ggsave(file.path(fig_dir, filename), plot, width = width, height = height, dpi = 300)
}

fmt_p <- function(p) {
  case_when(
    is.na(p) ~ "NA",
    p < 0.001 ~ "< .001",
    TRUE ~ paste0("= ", sprintf("%.3f", p))
  )
}

read_fifa_clean <- function() {
  readr::read_csv(raw_path, show_col_types = FALSE) %>%
    mutate(
      player = `Known As`,
      overall = as.numeric(Overall),
      potential = as.numeric(Potential),
      value_eur = as.numeric(`Value(in Euro)`),
      age = as.numeric(Age),
      total_stats = as.numeric(TotalStats),
      best_position = `Best Position`,
      nationality = Nationality,
      position_group = case_when(
        best_position %in% c("ST", "CF", "LW", "RW", "LF", "RF") ~ "Forward",
        best_position %in% c("CAM", "CM", "CDM", "LM", "RM") ~ "Midfield",
        best_position %in% c("CB", "LB", "RB", "LWB", "RWB") ~ "Defender",
        best_position == "GK" ~ "Goalkeeper",
        TRUE ~ "Other"
      ),
      ability_tier = case_when(
        overall >= 85 ~ "Elite 85+",
        overall >= 78 ~ "Starter 78-84",
        overall >= 70 ~ "Rotation 70-77",
        TRUE ~ "Depth <70"
      ),
      cell = paste(position_group, ability_tier, sep = " / ")
    ) %>%
    mutate(
      position_group = factor(position_group, levels = c("Forward", "Midfield", "Defender", "Goalkeeper", "Other")),
      ability_tier = factor(ability_tier, levels = c("Elite 85+", "Starter 78-84", "Rotation 70-77", "Depth <70"))
    )
}

model_data <- function(df) {
  df %>%
    filter(
      !is.na(value_eur),
      !is.na(nationality),
      !is.na(position_group),
      !is.na(ability_tier),
      !is.na(age),
      !is.na(potential),
      !is.na(overall),
      value_eur > 0,
      position_group != "Other"
    )
}

selected_cells <- c(
  "Midfield / Rotation 70-77",
  "Defender / Rotation 70-77",
  "Forward / Rotation 70-77",
  "Midfield / Starter 78-84"
)

selected_nationalities <- c("Spain", "Brazil", "Argentina", "France", "England", "Germany")
