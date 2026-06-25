source(file.path("data", "Nationality", "out", "scripts", "00_setup.R"))

df_raw <- read_fifa_clean()
df_model <- model_data(df_raw)

overview <- tibble(
  metric = c(
    "Rows in raw data",
    "Columns in raw data",
    "Rows retained for models",
    "Rows excluded for zero market value",
    "Rows excluded for missing model fields",
    "Distinct nationalities"
  ),
  value = c(
    nrow(df_raw),
    ncol(readr::read_csv(raw_path, show_col_types = FALSE, n_max = 1)),
    nrow(df_model),
    sum(df_raw$value_eur == 0, na.rm = TRUE),
    nrow(df_raw) - nrow(df_model) - sum(df_raw$value_eur == 0, na.rm = TRUE),
    n_distinct(df_raw$nationality)
  )
)

missing_tbl <- df_raw %>%
  summarise(across(everything(), ~sum(is.na(.x)))) %>%
  pivot_longer(everything(), names_to = "variable", values_to = "n_missing") %>%
  arrange(desc(n_missing))

cell_counts <- df_model %>%
  count(position_group, ability_tier, name = "n") %>%
  arrange(position_group, ability_tier)

nationality_counts <- df_model %>%
  count(nationality, sort = TRUE, name = "n")

value_summary <- df_raw %>%
  summarise(
    n = n(),
    n_zero = sum(value_eur == 0, na.rm = TRUE),
    median_eur = median(value_eur, na.rm = TRUE),
    q1_eur = quantile(value_eur, 0.25, na.rm = TRUE),
    q3_eur = quantile(value_eur, 0.75, na.rm = TRUE),
    max_eur = max(value_eur, na.rm = TRUE)
  )

selected_df <- df_model %>%
  filter(cell %in% selected_cells, nationality %in% selected_nationalities) %>%
  mutate(
    cell = factor(cell, levels = selected_cells),
    nationality = factor(nationality, levels = selected_nationalities)
  )

selected_counts <- selected_df %>%
  count(cell, nationality, name = "n") %>%
  arrange(cell, nationality)

readr::write_csv(overview, file.path(out_dir, "overview.csv"))
readr::write_csv(missing_tbl, file.path(out_dir, "missingness.csv"))
readr::write_csv(cell_counts, file.path(out_dir, "cell_counts.csv"))
readr::write_csv(nationality_counts, file.path(out_dir, "nationality_counts.csv"))
readr::write_csv(value_summary, file.path(out_dir, "value_summary.csv"))
readr::write_csv(selected_counts, file.path(out_dir, "selected_cell_counts.csv"))

p_value_dist <- df_raw %>%
  mutate(value_status = if_else(value_eur > 0, "Positive value", "Zero value")) %>%
  filter(value_eur >= 0) %>%
  ggplot(aes(x = value_eur)) +
  geom_histogram(bins = 50, fill = "#2b8cbe", color = "white", linewidth = 0.2) +
  geom_vline(xintercept = value_summary$median_eur, color = "#d95f02", linewidth = 1) +
  scale_x_log10(
    labels = label_dollar(prefix = "EUR ", scale_cut = cut_short_scale()),
    breaks = c(1e5, 5e5, 1e6, 5e6, 2e7, 1e8)
  ) +
  annotation_logticks(sides = "b") +
  labs(
    title = "Market value is strongly right-skewed",
    subtitle = sprintf("Median EUR %s; %d zero values excluded from models",
                       comma(value_summary$median_eur), value_summary$n_zero),
    x = "Market value (EUR, log scale; positive values shown)",
    y = "Number of players",
    caption = "FIFA 23 Players. Zero values are boundary observations and are not shown on the log axis."
  ) +
  theme_poster()
save_poster_fig(p_value_dist, "fig_eda_value_distribution.png", width = 8, height = 6)

p_cells <- cell_counts %>%
  mutate(cell = paste(position_group, ability_tier, sep = "\n")) %>%
  ggplot(aes(x = ability_tier, y = n, fill = position_group)) +
  geom_col(position = position_dodge(width = 0.75), width = 0.7) +
  scale_y_continuous(labels = label_comma()) +
  scale_fill_viridis_d(option = "D", end = 0.85) +
  labs(
    title = "Rotation and depth tiers contain most players",
    subtitle = sprintf("Positive-value model sample, n = %s", comma(nrow(df_model))),
    x = "Overall rating tier",
    y = "Number of players",
    fill = "Position group"
  ) +
  theme_poster() +
  theme(axis.text.x = element_text(angle = 20, hjust = 1))
save_poster_fig(p_cells, "fig_eda_position_ability_cells.png", width = 9, height = 6)

p_selected <- selected_df %>%
  ggplot(aes(x = nationality, y = value_eur, fill = nationality)) +
  geom_violin(alpha = 0.55, trim = FALSE, color = "grey35", linewidth = 0.25) +
  geom_boxplot(width = 0.13, outlier.size = 0.5, fill = "white", color = "grey20") +
  facet_wrap(~ cell, scales = "free_y", ncol = 2) +
  scale_y_log10(labels = label_dollar(prefix = "EUR ", scale_cut = cut_short_scale())) +
  scale_fill_viridis_d(option = "C", end = 0.9) +
  labs(
    title = "Same tier, different nationality distributions",
    subtitle = "Six specific nationalities compared within position-rating cells",
    x = "Nationality",
    y = "Market value (EUR, log scale)",
    caption = "Cells control broadly for best-position group and Overall rating tier."
  ) +
  theme_poster(base_size = 14) +
  theme(
    legend.position = "none",
    axis.text.x = element_text(angle = 35, hjust = 1)
  )
save_poster_fig(p_selected, "fig_eda_value_by_nationality_cells.png", width = 12, height = 8)

saveRDS(df_raw, file.path(out_dir, "df_raw.rds"))
saveRDS(df_model, file.path(out_dir, "df_model.rds"))
saveRDS(selected_df, file.path(out_dir, "selected_df.rds"))
