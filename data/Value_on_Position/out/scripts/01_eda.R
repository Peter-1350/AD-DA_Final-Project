source(file.path("data", "Value_on_Position", "out", "scripts", "00_setup.R"))

eda_df <- value_df %>%
  mutate(
    zero_value = value_eur == 0,
    zero_value_flag = if_else(zero_value, "Zero value", "Positive value"),
    skill_sd = pmax(pace_total, shooting_total, passing_total, dribbling_total, defending_total, physicality_total)
  )

missing_tbl <- tibble(
  variable = c(
    "value_eur", "wage_eur", "age", "overall", "potential", "total_stats",
    "pace_total", "shooting_total", "passing_total", "dribbling_total",
    "defending_total", "physicality_total", "best_position"
  ),
  missing_n = c(
    map_int(eda_df[c("value_eur", "wage_eur", "age", "overall", "potential", "total_stats",
                     "pace_total", "shooting_total", "passing_total", "dribbling_total",
                     "defending_total", "physicality_total")], ~ sum(is.na(.x))),
    sum(is.na(eda_df$best_position))
  )
)

write_csv(missing_tbl, file.path(out_dir, "eda_missingness.csv"))

overview_tbl <- tibble(
  metric = c(
    "Rows", "Columns", "Zero-value players", "Median value", "Median age",
    "Median total stats", "Best position levels"
  ),
  value = c(
    nrow(eda_df),
    ncol(eda_df),
    sum(eda_df$zero_value, na.rm = TRUE),
    median(eda_df$value_eur, na.rm = TRUE),
    median(eda_df$age, na.rm = TRUE),
    median(eda_df$total_stats, na.rm = TRUE),
    nlevels(eda_df$best_position)
  )
)
write_csv(overview_tbl, file.path(out_dir, "eda_overview.csv"))

position_value_tbl <- eda_df %>%
  group_by(best_position) %>%
  summarise(
    n = n(),
    zero_value_n = sum(zero_value, na.rm = TRUE),
    median_value = median(value_eur, na.rm = TRUE),
    median_log_value = median(log_value, na.rm = TRUE),
    q25_log_value = quantile(log_value, 0.25, na.rm = TRUE),
    q75_log_value = quantile(log_value, 0.75, na.rm = TRUE),
    .groups = "drop"
  ) %>%
  arrange(desc(median_log_value))

skill_position_tbl <- eda_df %>%
  pivot_longer(
    c(pace_total, shooting_total, passing_total, dribbling_total, defending_total, physicality_total),
    names_to = "skill",
    values_to = "score"
  ) %>%
  mutate(skill = dplyr::recode(skill,
                        pace_total = "Pace",
                        shooting_total = "Shooting",
                        passing_total = "Passing",
                        dribbling_total = "Dribbling",
                        defending_total = "Defending",
                        physicality_total = "Physicality")) %>%
  group_by(best_position, skill) %>%
  summarise(mean_score = mean(score, na.rm = TRUE), .groups = "drop")

write_csv(position_value_tbl, file.path(out_dir, "eda_position_value_summary.csv"))
write_csv(skill_position_tbl, file.path(out_dir, "eda_skill_position_summary.csv"))

p_value_dist <- eda_df %>%
  filter(value_eur > 0) %>%
  ggplot(aes(x = log_value, fill = position_group)) +
  geom_histogram(bins = 45, alpha = 0.7, color = "white") +
  facet_wrap(~position_group, scales = "free_y", nrow = 2) +
  scale_fill_viridis_d(end = 0.9, guide = "none") +
  labs(
    title = "Market value is right-skewed within every role",
    subtitle = sprintf("log10(value + 1) shown for all positive-value players; n = %d", sum(eda_df$value_eur > 0)),
    x = "log10(market value + 1)",
    y = "Players"
  )
save_poster_fig(p_value_dist, file.path(fig_dir, "fig_eda_value_distribution.png"), width = 10, height = 6.5)

p_role_value <- position_value_tbl %>%
  mutate(best_position = fct_reorder(best_position, median_log_value)) %>%
  ggplot(aes(x = best_position, y = median_value, fill = best_position)) +
  geom_col(width = 0.72, alpha = 0.9) +
  coord_flip() +
  scale_fill_viridis_d(end = 0.9, guide = "none") +
  scale_y_continuous(labels = label_dollar(prefix = "EUR ", scale_cut = cut_short_scale())) +
  labs(
    title = "Player value differs sharply across positions",
    subtitle = sprintf("Median market value by best position; zero-value players retained, n = %d", nrow(eda_df)),
    x = NULL,
    y = "Median market value"
  )
save_poster_fig(p_role_value, file.path(fig_dir, "fig_eda_position_value.png"), width = 10, height = 8)

p_skill_profile <- skill_position_tbl %>%
  mutate(
    skill = factor(skill, levels = c("Pace", "Shooting", "Passing", "Dribbling", "Defending", "Physicality")),
    best_position = fct_reorder(best_position, mean_score)
  ) %>%
  ggplot(aes(x = skill, y = best_position, fill = mean_score)) +
  geom_tile(color = "white", linewidth = 0.3) +
  scale_fill_viridis_c(option = "C", end = 0.95) +
  labs(
    title = "Skill profiles differ systematically by position",
    subtitle = "Cell color shows mean skill total for each best position",
    x = NULL,
    y = NULL,
    fill = "Mean score"
  ) +
  theme(axis.text.x = element_text(angle = 25, hjust = 1))
save_poster_fig(p_skill_profile, file.path(fig_dir, "fig_eda_skill_profile.png"), width = 10.5, height = 8)

p_skill_value <- eda_df %>%
  pivot_longer(
    c(pace_total, shooting_total, passing_total, dribbling_total, defending_total, physicality_total),
    names_to = "skill",
    values_to = "score"
  ) %>%
  mutate(
    skill = dplyr::recode(skill,
                   pace_total = "Pace",
                   shooting_total = "Shooting",
                   passing_total = "Passing",
                   dribbling_total = "Dribbling",
                   defending_total = "Defending",
                   physicality_total = "Physicality"),
    skill = factor(skill, levels = c("Pace", "Shooting", "Passing", "Dribbling", "Defending", "Physicality"))
  ) %>%
  ggplot(aes(x = score, y = log_value, color = position_group)) +
  geom_point(alpha = 0.18, size = 0.7) +
  geom_smooth(method = "loess", se = TRUE, linewidth = 0.8) +
  facet_wrap(~skill, ncol = 3, scales = "free_x") +
  scale_color_viridis_d(end = 0.88) +
  labs(
    title = "Skill-value relationships vary by skill and role",
    subtitle = "Loess smooths are shown separately for each skill; value uses log10(value + 1)",
    x = "Skill total",
    y = "log10(market value + 1)",
    color = "Role"
  )
save_poster_fig(p_skill_value, file.path(fig_dir, "fig_eda_skill_vs_value_by_position.png"), width = 12, height = 8)
