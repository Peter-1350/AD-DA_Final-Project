library(tidyverse)
library(broom)
library(scales)
library(viridis)

root_dir <- normalizePath(file.path(getwd()), winslash = "/", mustWork = TRUE)
out_dir <- file.path("data", "Nationality", "out")
fig_dir <- file.path(out_dir, "figs")
dir.create(file.path(out_dir, "scripts"), recursive = TRUE, showWarnings = FALSE)
dir.create(fig_dir, recursive = TRUE, showWarnings = FALSE)

theme_poster <- function(base_size = 16) {
  theme_minimal(base_size = base_size) +
    theme(
      plot.title = element_text(face = "bold", size = base_size + 2),
      plot.subtitle = element_text(color = "grey25", size = base_size - 2),
      plot.caption = element_text(color = "grey45", size = base_size - 5, hjust = 0),
      panel.grid.minor = element_blank(),
      legend.position = "bottom"
    )
}

save_poster_fig <- function(plot, path, width = 8, height = 6) {
  title <- plot$labels$title
  subtitle <- plot$labels$subtitle
  title <- if (is.null(title) || length(title) == 0) "" else as.character(title[[1]])
  subtitle <- if (is.null(subtitle) || length(subtitle) == 0) "" else as.character(subtitle[[1]])
  if (nchar(title) > 60) warning("Title too long (", nchar(title), " chars): ", title)
  if (nchar(subtitle) > 90) warning("Subtitle long (", nchar(subtitle), " chars): ", subtitle)
  ggsave(path, plot, width = width, height = height, dpi = 300)
}

read_fifa <- function() {
  clean_local_names <- function(x) {
    x %>%
      tolower() %>%
      stringr::str_replace_all("[^a-z0-9]+", "_") %>%
      stringr::str_replace_all("^_|_$", "")
  }

  readr::read_csv("data/FIFA 23 Players.csv", show_col_types = FALSE) %>%
    rename_with(clean_local_names) %>%
    mutate(
      value_eur = as.numeric(value_in_euro),
      wage_eur = as.numeric(wage_in_euro),
      total_stats = as.numeric(totalstats),
      base_stats = as.numeric(basestats),
      position_group = case_when(
        best_position == "GK" ~ "Goalkeeper",
        best_position %in% c("CB", "LB", "RB", "LWB", "RWB") ~ "Defender",
        best_position %in% c("CDM", "CM", "CAM", "LM", "RM") ~ "Midfielder",
        best_position %in% c("ST", "CF", "LW", "RW", "LF", "RF") ~ "Forward",
        TRUE ~ "Other"
      ),
      ability_tier = case_when(
        overall >= 85 ~ "Elite (85+)",
        overall >= 78 ~ "Starter (78-84)",
        overall >= 70 ~ "Regular (70-77)",
        TRUE ~ "Depth/Youth (<70)"
      ),
      ability_tier = factor(
        ability_tier,
        levels = c("Depth/Youth (<70)", "Regular (70-77)", "Starter (78-84)", "Elite (85+)")
      ),
      position_group = factor(
        position_group,
        levels = c("Forward", "Midfielder", "Defender", "Goalkeeper", "Other")
      )
    )
}

fmt_eur <- label_dollar(prefix = "EUR ", scale_cut = cut_short_scale())

percent_from_log <- function(x) {
  100 * (exp(x) - 1)
}
