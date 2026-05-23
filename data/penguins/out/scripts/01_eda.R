source("data/penguins/out/scripts/00_utils.R")

library(dplyr)
library(ggplot2)
library(patchwork)
library(scales)
library(viridis)

df <- load_fifa23()
df_positive <- df |>
  filter(value_eur > 0, wage_eur > 0)

root <- get_project_root()
out_dir <- file.path(root, "data", "penguins", "out")
dir.create(file.path(out_dir, "figs"), recursive = TRUE, showWarnings = FALSE)

summary_tbl <- df |>
  summarise(
    n = n(),
    n_players = n_distinct(full_name),
    n_clubs = n_distinct(club_name),
    n_nationalities = n_distinct(nationality),
    n_positions = n_distinct(best_position),
    zero_value = sum(value_eur == 0, na.rm = TRUE),
    zero_wage = sum(wage_eur == 0, na.rm = TRUE),
    missing_value = sum(is.na(value_eur)),
    missing_wage = sum(is.na(wage_eur)),
    missing_overall = sum(is.na(overall)),
    missing_potential = sum(is.na(potential))
  )
print(summary_tbl)

top_positions <- df |>
  count(best_position, sort = TRUE) |>
  slice_head(n = 8) |>
  mutate(best_position = forcats::fct_reorder(best_position, n))

q95 <- quantile(df$value_eur, 0.95, na.rm = TRUE)

p_dist <- (
  ggplot(df_positive, aes(x = log_value)) +
    geom_histogram(bins = 40, fill = "#2C7FB8", color = "white", alpha = 0.9) +
    geom_vline(xintercept = log10(median(df_positive$value_eur)), linetype = "dashed", color = "#7A5195") +
    labs(
      title = "FIFA 23 player values are strongly right-skewed",
      subtitle = sprintf("n = %d positive observations; median value = €%s; 95th percentile = €%s", nrow(df_positive),
                         comma(median(df_positive$value_eur), accuracy = 1),
                         comma(q95, accuracy = 1)),
      x = "log10(Value in Euro)",
      y = "Number of players"
    ) +
    theme_minimal(base_size = 15) +
    theme(panel.grid.minor = element_blank())
) / (
  ggplot(df_positive, aes(x = log_wage)) +
    geom_histogram(bins = 40, fill = "#41B6C4", color = "white", alpha = 0.9) +
    labs(
      title = "Wage distribution",
      subtitle = "Log scale improves readability of the long right tail",
      x = "log10(Wage in Euro)",
      y = "Number of players"
    ) +
    theme_minimal(base_size = 15) +
    theme(panel.grid.minor = element_blank())
) +
  plot_annotation(title = "Distributional overview", theme = theme(plot.title = element_text(face = "bold", size = 18)))

save_poster_fig(p_dist, "fig_eda_distributions.png", width = 10, height = 8)

p_assoc1 <- ggplot(df_positive, aes(x = overall, y = log_value, color = age)) +
  geom_point(alpha = 0.35, size = 1.2) +
  geom_smooth(method = "loess", se = TRUE, color = "black", fill = "grey70") +
  scale_color_viridis_c(option = "C") +
  labs(
    title = "Higher overall ratings align with higher market value",
    subtitle = "Loess fit with 95% CI; color shows age",
    x = "Overall rating",
    y = "log10(Value in Euro)",
    color = "Age"
  ) +
  theme_minimal(base_size = 15) +
  theme(panel.grid.minor = element_blank())

p_assoc2 <- ggplot(df_positive, aes(x = age, y = log_value, color = overall)) +
  geom_point(alpha = 0.35, size = 1.2) +
  geom_smooth(method = "loess", se = TRUE, color = "black", fill = "grey70") +
  scale_color_viridis_c(option = "B") +
  labs(
    title = "Age and market value show a curved pattern",
    subtitle = "Color shows overall rating",
    x = "Age (years)",
    y = "log10(Value in Euro)",
    color = "Overall"
  ) +
  theme_minimal(base_size = 15) +
  theme(panel.grid.minor = element_blank())

p_assoc3 <- ggplot(top_positions, aes(x = best_position, y = n, fill = best_position)) +
  geom_col(width = 0.75, show.legend = FALSE) +
  coord_flip() +
  scale_fill_viridis_d(option = "D", end = 0.85) +
  labs(
    title = "Most common best positions in the file",
    subtitle = "Top 8 positions by count",
    x = NULL,
    y = "Number of players"
  ) +
  theme_minimal(base_size = 15) +
  theme(panel.grid.minor = element_blank())

p_eda <- (p_assoc1 | p_assoc2) / p_assoc3 +
  plot_annotation(title = "Exploratory patterns relevant to market value",
                  theme = theme(plot.title = element_text(face = "bold", size = 18)))

save_poster_fig(p_eda, "fig_eda_relationships.png", width = 12, height = 10)

cat("EDA complete. Figures written to out/figs.\n")
