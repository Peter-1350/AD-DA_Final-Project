source(file.path("data", "Value_Training", "out", "scripts", "00_setup.R"))

eda_df <- value_df %>%
  mutate(
    nationality_band = group_by_nationality_band(nationality),
    value_positive = value_eur > 0,
    wage_positive = wage_eur > 0
  )

miss_tbl <- tibble(
  variable = c("value_eur", "wage_eur", "overall", "potential", "total_stats", "age"),
  missing = map_int(eda_df[c("value_eur", "wage_eur", "overall", "potential", "total_stats", "age")], ~ sum(is.na(.x))),
  zeros = c(
    sum(eda_df$value_eur == 0),
    sum(eda_df$wage_eur == 0),
    NA_integer_,
    NA_integer_,
    NA_integer_,
    NA_integer_
  )
)

write_csv(miss_tbl, file.path(out_dir, "eda_missingness.csv"))

overview_tbl <- tibble(
  metric = c("Rows", "Columns", "Zero value players", "Zero wage players", "Median value", "Median wage"),
  value = c(
    nrow(eda_df),
    ncol(eda_df),
    sum(eda_df$value_eur == 0),
    sum(eda_df$wage_eur == 0),
    median(eda_df$value_eur),
    median(eda_df$wage_eur)
  )
)

write_csv(overview_tbl, file.path(out_dir, "eda_overview.csv"))

p_zero <- tibble(
  metric = c("Market value", "Weekly wage"),
  zeros = c(sum(eda_df$value_eur == 0), sum(eda_df$wage_eur == 0))
) %>%
  mutate(metric = factor(metric, levels = metric)) %>%
  ggplot(aes(x = metric, y = zeros, fill = metric)) +
  geom_col(width = 0.6, alpha = 0.9) +
  geom_text(aes(label = comma(zeros)), vjust = -0.4, size = 4.5) +
  scale_fill_viridis_d(end = 0.8, guide = "none") +
  labs(
    title = "Zero entries are uncommon but non-trivial",
    subtitle = sprintf("n = %d players; %d market values and %d wages are exactly zero",
                       nrow(eda_df), sum(eda_df$value_eur == 0), sum(eda_df$wage_eur == 0)),
    x = NULL,
    y = "Count of zero entries"
  )

save_poster_fig(p_zero, file.path(fig_dir, "fig_eda_zero_values.png"), width = 7.5, height = 5)

p_skew <- eda_df %>%
  pivot_longer(c(value_eur, wage_eur), names_to = "metric", values_to = "amount") %>%
  mutate(
    metric = recode(metric, value_eur = "Market value", wage_eur = "Weekly wage"),
    log_amount = log10(amount + 1)
  ) %>%
  ggplot(aes(x = log_amount, fill = metric)) +
  geom_histogram(bins = 40, alpha = 0.7, position = "identity") +
  facet_wrap(~metric, scales = "free_y") +
  scale_fill_viridis_d(end = 0.9, guide = "none") +
  labs(
    title = "Value and wage are strongly right-skewed",
    subtitle = "Log10 scale used only for visualization; zeros are retained via +1",
    x = "log10(amount + 1)",
    y = "Number of players"
  )

save_poster_fig(p_skew, file.path(fig_dir, "fig_eda_skewed_distributions.png"), width = 8.5, height = 5.5)

position_summary <- eda_df %>%
  group_by(position_group) %>%
  summarise(
    n = n(),
    median_value = median(value_eur),
    median_log_value = median(log10(value_eur + 1)),
    q25 = quantile(log10(value_eur + 1), 0.25),
    q75 = quantile(log10(value_eur + 1), 0.75),
    .groups = "drop"
  )

top_nat <- eda_df %>%
  mutate(nationality_band = group_by_nationality_band(nationality)) %>%
  group_by(nationality_band) %>%
  summarise(
    n = n(),
    median_log_value = median(log10(value_eur + 1)),
    q25 = quantile(log10(value_eur + 1), 0.25),
    q75 = quantile(log10(value_eur + 1), 0.75),
    .groups = "drop"
  ) %>%
  arrange(median_log_value) %>%
  mutate(nationality_band = fct_inorder(nationality_band))

p_structure <- (
  ggplot(position_summary, aes(x = position_group, y = median_value, fill = position_group)) +
    geom_col(width = 0.65, alpha = 0.9) +
    geom_text(aes(label = comma(median_value)), vjust = -0.35, size = 4) +
    scale_fill_viridis_d(end = 0.85, guide = "none") +
    scale_y_continuous(labels = label_dollar(prefix = "EUR ", scale_cut = cut_short_scale())) +
    labs(
      title = "Player value differs sharply by role",
      subtitle = "Median market value by broad position group",
      x = NULL,
      y = "Median market value"
    )
) / (
  ggplot(top_nat, aes(y = nationality_band, x = median_log_value)) +
    geom_point(size = 2.6, color = viridis(1, option = "D")) +
    geom_errorbar(
      aes(xmin = q25, xmax = q75),
      orientation = "y",
      height = 0.18,
      color = "grey40"
    ) +
    labs(
      title = "Some nationality groups sit higher in value",
      subtitle = "Top 12 nationalities by sample size, plus an Other bucket",
      x = "Median log10(market value + 1)",
      y = NULL
    )
)

save_poster_fig(p_structure, file.path(fig_dir, "fig_eda_position_nationality.png"), width = 10, height = 10)

p_value_position <- eda_df %>%
  filter(value_eur > 0) %>%
  ggplot(aes(x = position_group, y = log10(value_eur + 1), fill = position_group)) +
  geom_violin(trim = FALSE, alpha = 0.65) +
  geom_boxplot(width = 0.16, outlier.size = 0.4, alpha = 0.8) +
  scale_fill_viridis_d(end = 0.85, guide = "none") +
  labs(
    title = "Market value varies strongly across broad roles",
    subtitle = "Violin + boxplot on the log10(value + 1) scale",
    x = NULL,
    y = "log10(market value + 1)"
  )

save_poster_fig(p_value_position, file.path(fig_dir, "fig_eda_value_by_position.png"), width = 8.5, height = 5.5)
