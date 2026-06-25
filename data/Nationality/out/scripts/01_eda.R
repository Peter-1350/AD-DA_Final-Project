source("data/Nationality/out/scripts/00_setup.R")
library(skimr)
library(patchwork)

raw <- read_fifa()

quality_summary <- tibble(
  metric = c(
    "Rows",
    "Columns",
    "Players with value = 0",
    "Players with missing value",
    "Distinct nationalities",
    "Distinct clubs"
  ),
  value = c(
    nrow(raw),
    ncol(raw),
    sum(raw$value_eur == 0, na.rm = TRUE),
    sum(is.na(raw$value_eur)),
    n_distinct(raw$nationality),
    n_distinct(raw$club_name, na.rm = TRUE)
  )
)

missing_summary <- raw %>%
  summarise(across(everything(), ~ sum(is.na(.x)))) %>%
  pivot_longer(everything(), names_to = "variable", values_to = "missing_n") %>%
  mutate(missing_pct = missing_n / nrow(raw)) %>%
  arrange(desc(missing_n), variable)

analysis_df <- raw %>%
  filter(!is.na(value_eur), value_eur > 0, !is.na(nationality), position_group != "Other") %>%
  mutate(log_value = log(value_eur))

nationality_summary <- analysis_df %>%
  count(nationality, sort = TRUE, name = "n") %>%
  mutate(pct = n / sum(n))

strata_summary <- analysis_df %>%
  count(position_group, ability_tier, name = "n") %>%
  group_by(position_group) %>%
  mutate(position_pct = n / sum(n)) %>%
  ungroup()

top_nationalities_by_stratum <- analysis_df %>%
  group_by(position_group, ability_tier, nationality) %>%
  summarise(
    n = n(),
    median_value_eur = median(value_eur),
    median_overall = median(overall),
    .groups = "drop"
  ) %>%
  group_by(position_group, ability_tier) %>%
  slice_max(n, n = 8, with_ties = FALSE) %>%
  ungroup()

readr::write_csv(quality_summary, file.path(out_dir, "quality_summary.csv"))
readr::write_csv(missing_summary, file.path(out_dir, "missing_summary.csv"))
readr::write_csv(nationality_summary, file.path(out_dir, "nationality_group_summary.csv"))
readr::write_csv(strata_summary, file.path(out_dir, "strata_summary.csv"))
readr::write_csv(top_nationalities_by_stratum, file.path(out_dir, "top_nationalities_by_stratum.csv"))
saveRDS(analysis_df, file.path(out_dir, "clean_fifa_nationality.rds"))

overview_counts <- bind_rows(
  analysis_df %>%
    count(position_group, name = "n") %>%
    mutate(panel = "Position", group = as.character(position_group)),
  analysis_df %>%
    count(ability_tier, name = "n") %>%
    mutate(panel = "Ability tier", group = as.character(ability_tier))
)

p_overview <- ggplot(overview_counts, aes(x = reorder(group, n), y = n, fill = panel)) +
  geom_col(width = 0.72, show.legend = FALSE) +
  geom_text(aes(label = comma(n)), hjust = -0.12, size = 4.7) +
  coord_flip() +
  facet_wrap(~ panel, scales = "free_y", nrow = 1) +
  scale_y_continuous(labels = comma, expand = expansion(mult = c(0, 0.18))) +
  scale_fill_viridis_d(option = "D", end = 0.75) +
  labs(
    title = "FIFA 23 sample after excluding zero values",
    subtitle = sprintf("n = %s positive-value players; 98 zero-value rows removed", comma(nrow(analysis_df))),
    x = NULL,
    y = "Number of players"
  ) +
  theme_poster()

save_poster_fig(
  p_overview,
  file.path(fig_dir, "fig_data_overview_counts.png"),
  width = 10,
  height = 5.8
)

p_value <- ggplot(analysis_df, aes(x = value_eur)) +
  geom_histogram(bins = 55, fill = viridis(1, option = "D", begin = 0.25), color = "white") +
  geom_vline(aes(xintercept = median(value_eur)), color = "firebrick", linewidth = 1.1) +
  annotate(
    "label",
    x = median(analysis_df$value_eur),
    y = Inf,
    vjust = 1.4,
    hjust = -0.04,
    label = sprintf("Median = %s", fmt_eur(median(analysis_df$value_eur))),
    size = 4.5
  ) +
  scale_x_log10(labels = fmt_eur) +
  scale_y_continuous(labels = comma) +
  labs(
    title = "Market value is strongly right-skewed",
    subtitle = "Positive values only; models use log-link scale",
    x = "Market value (EUR, log scale)",
    y = "Number of players"
  ) +
  theme_poster()

save_poster_fig(
  p_value,
  file.path(fig_dir, "fig_eda_value_distribution.png"),
  width = 8,
  height = 6
)

p_strata <- analysis_df %>%
  count(position_group, ability_tier, name = "n") %>%
  ggplot(aes(x = ability_tier, y = n, fill = position_group)) +
  geom_col(position = position_dodge(width = 0.78), width = 0.7) +
  scale_y_continuous(labels = comma) +
  scale_fill_viridis_d(option = "D", end = 0.85) +
  labs(
    title = "Local comparisons use position and ability strata",
    subtitle = sprintf("n = %s; each bar is a candidate homogeneous group", comma(nrow(analysis_df))),
    x = "Ability tier",
    y = "Number of players",
    fill = "Position"
  ) +
  theme_poster() +
  theme(axis.text.x = element_text(angle = 18, hjust = 1))

save_poster_fig(
  p_strata,
  file.path(fig_dir, "fig_strata_counts.png"),
  width = 10,
  height = 6
)
