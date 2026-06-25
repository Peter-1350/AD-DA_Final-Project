source(file.path("data", "Value_on_Position", "out", "scripts", "00_setup.R"))

eda_df <- value_df %>%
  mutate(
    position_group = fct_drop(position_group)
  )

overview_tbl <- tibble(
  metric = c("Rows", "Columns", "Zero value players", "Positive value players", "Missing value", "Missing age"),
  value = c(
    nrow(eda_df),
    ncol(eda_df),
    sum(eda_df$value_eur == 0, na.rm = TRUE),
    sum(eda_df$value_eur > 0, na.rm = TRUE),
    sum(is.na(eda_df$value_eur)),
    sum(is.na(eda_df$age))
  )
)
write_csv(overview_tbl, file.path(out_dir, "eda_overview.csv"))

missing_tbl <- tibble(
  variable = c(
    "value_eur", "wage_eur", "overall", "potential", "total_stats", "age",
    "pace_total", "shooting_total", "passing_total", "dribbling_total",
    "defending_total", "physicality_total", "position_group"
  ),
  missing = c(
    map_int(eda_df[c(
      "value_eur", "wage_eur", "overall", "potential", "total_stats", "age",
      "pace_total", "shooting_total", "passing_total", "dribbling_total",
      "defending_total", "physicality_total"
    )], ~ sum(is.na(.x))),
    sum(is.na(eda_df$position_group))
  )
)
write_csv(missing_tbl, file.path(out_dir, "eda_missingness.csv"))

position_summary <- eda_df %>%
  group_by(position_group) %>%
  summarise(
    n = n(),
    zero_value_n = sum(value_eur == 0, na.rm = TRUE),
    median_value = median(value_eur, na.rm = TRUE),
    median_log_value = median(log_value, na.rm = TRUE),
    iqr_low = quantile(log_value, 0.25, na.rm = TRUE),
    iqr_high = quantile(log_value, 0.75, na.rm = TRUE),
    .groups = "drop"
  )
write_csv(position_summary, file.path(out_dir, "eda_position_summary.csv"))

skill_cols <- c("pace_total", "shooting_total", "passing_total", "dribbling_total", "defending_total", "physicality_total")
skill_profile <- eda_df %>%
  select(position_group, all_of(skill_cols)) %>%
  pivot_longer(all_of(skill_cols), names_to = "skill", values_to = "score") %>%
  group_by(position_group, skill) %>%
  summarise(mean_score = mean(score, na.rm = TRUE), .groups = "drop") %>%
  mutate(
    skill = recode(skill,
                   pace_total = "Pace",
                   shooting_total = "Shooting",
                   passing_total = "Passing",
                   dribbling_total = "Dribbling",
                   defending_total = "Defending",
                   physicality_total = "Physicality"),
    skill = factor(skill, levels = c("Pace", "Shooting", "Passing", "Dribbling", "Defending", "Physicality"))
  )
write_csv(skill_profile, file.path(out_dir, "eda_skill_profile.csv"))

value_dist_tbl <- eda_df %>%
  filter(value_eur > 0) %>%
  group_by(position_group) %>%
  summarise(
    n = n(),
    median_value = median(value_eur),
    q25 = quantile(value_eur, 0.25),
    q75 = quantile(value_eur, 0.75),
    .groups = "drop"
  )
write_csv(value_dist_tbl, file.path(out_dir, "eda_value_distribution_summary.csv"))

p_value <- eda_df %>%
  filter(value_eur > 0) %>%
  ggplot(aes(x = position_group, y = log_value, fill = position_group)) +
  geom_violin(trim = FALSE, alpha = 0.72, color = NA) +
  geom_boxplot(width = 0.15, outlier.size = 0.4, alpha = 0.85) +
  scale_fill_viridis_d(end = 0.85, guide = "none") +
  labs(
    title = "Player value differs sharply across positions",
    subtitle = sprintf("n = %d positive-value players; log10(value + 1) scale", sum(eda_df$value_eur > 0, na.rm = TRUE)),
    x = NULL,
    y = "log10(market value + 1)"
  )
save_poster_fig(p_value, file.path(fig_dir, "fig_eda_position_value.png"), width = 8.5, height = 5.8)

p_profile <- skill_profile %>%
  ggplot(aes(x = skill, y = mean_score, fill = position_group, group = position_group)) +
  geom_line(linewidth = 0.8, alpha = 0.8) +
  geom_point(size = 2.8) +
  scale_fill_viridis_d(end = 0.85) +
  labs(
    title = "Skill profiles differ by position group",
    subtitle = "Mean skill ratings within each broad role",
    x = NULL,
    y = "Mean skill rating",
    fill = "Position"
  )
save_poster_fig(p_profile, file.path(fig_dir, "fig_eda_skill_profile.png"), width = 9, height = 5.8)

p_skill_value <- eda_df %>%
  filter(value_eur > 0) %>%
  select(position_group, log_value, all_of(skill_cols)) %>%
  pivot_longer(all_of(skill_cols), names_to = "skill", values_to = "score") %>%
  mutate(
    skill = recode(skill,
                   pace_total = "Pace",
                   shooting_total = "Shooting",
                   passing_total = "Passing",
                   dribbling_total = "Dribbling",
                   defending_total = "Defending",
                   physicality_total = "Physicality"),
    skill = factor(skill, levels = c("Pace", "Shooting", "Passing", "Dribbling", "Defending", "Physicality"))
  ) %>%
  ggplot(aes(x = score, y = log_value, color = position_group)) +
  geom_point(alpha = 0.16, size = 0.5) +
  geom_smooth(method = "loess", se = TRUE, linewidth = 0.75) +
  facet_wrap(~skill, scales = "free_x", ncol = 2) +
  scale_color_viridis_d(end = 0.85) +
  labs(
    title = "Skill-value relationships vary by role",
    subtitle = "Each panel shows one core skill against log10(value + 1)",
    x = "Skill rating",
    y = "log10(market value + 1)",
    color = "Position"
  )
save_poster_fig(p_skill_value, file.path(fig_dir, "fig_eda_skill_vs_value_by_position.png"), width = 11, height = 8)

