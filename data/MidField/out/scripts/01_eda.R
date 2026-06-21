source(file.path("data", "MidField", "out", "scripts", "00_setup.R"))

eda_df <- fifa_df %>%
  mutate(
    position_group = fct_drop(position_group)
  )

miss_tbl <- tibble(
  variable = c("value_eur", "total_stats", "shooting_total", "passing_total", "dribbling_total",
               "defending_total", "pace_total", "physicality_total", "age", "international_reputation"),
  missing = map_int(eda_df[c("value_eur", "total_stats", "shooting_total", "passing_total", "dribbling_total",
                             "defending_total", "pace_total", "physicality_total", "age", "international_reputation")],
                    ~ sum(is.na(.x))),
  zeros = c(
    sum(eda_df$value_eur == 0),
    NA_integer_, NA_integer_, NA_integer_, NA_integer_,
    NA_integer_, NA_integer_, NA_integer_, NA_integer_, NA_integer_
  )
)

write_csv(miss_tbl, file.path(out_dir, "eda_missingness.csv"))

p_value_dist <- eda_df %>%
  count(position_group) %>%
  mutate(prop = n / sum(n)) %>%
  ggplot(aes(x = position_group, y = prop, fill = position_group)) +
  geom_col(width = 0.7) +
  geom_text(aes(label = percent(prop, accuracy = 0.1)), vjust = -0.4, size = 4.2) +
  scale_fill_viridis_d(end = 0.85, guide = "none") +
  scale_y_continuous(labels = label_percent()) +
  labs(
    title = "The sample is concentrated in defense and midfield roles",
    subtitle = sprintf("n = %d players", nrow(eda_df)),
    x = NULL,
    y = "Share of players"
  ) +
  theme(axis.text.x = element_text(face = "bold"))

save_poster_fig(p_value_dist, file.path(fig_dir, "fig_eda_position_share.png"), width = 7.8, height = 5.2)

value_by_group <- eda_df %>%
  filter(value_eur > 0) %>%
  group_by(position_group) %>%
  summarise(
    n = n(),
    median_value = median(value_eur),
    q25 = quantile(value_eur, 0.25),
    q75 = quantile(value_eur, 0.75),
    .groups = "drop"
  )

p_value_group <- ggplot(value_by_group, aes(x = position_group, y = median_value, fill = position_group)) +
  geom_col(width = 0.7) +
  geom_errorbar(aes(ymin = q25, ymax = q75), width = 0.15, linewidth = 0.8) +
  scale_fill_viridis_d(end = 0.85, guide = "none") +
  scale_y_continuous(labels = label_dollar(prefix = "€", scale_cut = cut_short_scale())) +
  labs(
    title = "Midfielders sit below attackers in raw market value",
    subtitle = "Median and IQR among players with positive market value",
    x = NULL,
    y = "Market value"
  ) +
  theme(axis.text.x = element_text(face = "bold"))

save_poster_fig(p_value_group, file.path(fig_dir, "fig_eda_value_by_position.png"), width = 8.4, height = 5.4)

skill_long <- eda_df %>%
  filter(position_group %in% c("Attack", "Midfield", "Defense", "GK")) %>%
  select(position_group, shooting_total, passing_total, dribbling_total, defending_total, pace_total, physicality_total) %>%
  pivot_longer(-position_group, names_to = "skill", values_to = "score") %>%
  mutate(
    skill = recode(skill,
                   shooting_total = "Shooting",
                   passing_total = "Passing",
                   dribbling_total = "Dribbling",
                   defending_total = "Defending",
                   pace_total = "Pace",
                   physicality_total = "Physicality"),
    skill = factor(skill, levels = c("Shooting", "Passing", "Dribbling", "Defending", "Pace", "Physicality"))
  )

skill_summary <- skill_long %>%
  group_by(position_group, skill) %>%
  summarise(
    median_score = median(score),
    q25 = quantile(score, 0.25),
    q75 = quantile(score, 0.75),
    .groups = "drop"
  )

p_skill <- ggplot(skill_summary, aes(x = skill, y = median_score, fill = position_group)) +
  geom_col(position = position_dodge(width = 0.75), width = 0.7) +
  geom_errorbar(aes(ymin = q25, ymax = q75), position = position_dodge(width = 0.75), width = 0.12, linewidth = 0.7) +
  scale_fill_viridis_d(end = 0.85) +
  labs(
    title = "Midfielders are balanced across passing and defending",
    subtitle = "Median skill ratings by position group; error bars show IQR",
    x = NULL,
    y = "Median skill rating",
    fill = "Position"
  ) +
  theme(axis.text.x = element_text(angle = 25, hjust = 1))

save_poster_fig(p_skill, file.path(fig_dir, "fig_eda_skill_profile.png"), width = 10, height = 6.2)

demographic_summary <- eda_df %>%
  group_by(position_group) %>%
  summarise(
    n = n(),
    median_age = median(age),
    median_overall = median(overall),
    median_reputation = median(international_reputation),
    .groups = "drop"
  ) %>%
  filter(position_group %in% c("Attack", "Midfield", "Defense", "GK"))

p_demo <- (
  ggplot(demographic_summary, aes(x = position_group, y = median_age, fill = position_group)) +
    geom_col(width = 0.7) +
    scale_fill_viridis_d(end = 0.85, guide = "none") +
    labs(title = "Midfielders are slightly older on median", x = NULL, y = "Median age (years)") +
    theme(axis.text.x = element_text(face = "bold"))
) / (
  ggplot(demographic_summary, aes(x = position_group, y = median_overall, fill = position_group)) +
    geom_col(width = 0.7) +
    scale_fill_viridis_d(end = 0.85, guide = "none") +
    labs(title = "Overall rating is highest for attackers and defenders", x = NULL, y = "Median overall rating") +
    theme(axis.text.x = element_text(face = "bold"))
) / (
  ggplot(demographic_summary, aes(x = position_group, y = median_reputation, fill = position_group)) +
    geom_col(width = 0.7) +
    scale_fill_viridis_d(end = 0.85, guide = "none") +
    labs(title = "International reputation differs by position", x = NULL, y = "Median international reputation") +
    theme(axis.text.x = element_text(face = "bold"))
)

save_poster_fig(p_demo, file.path(fig_dir, "fig_eda_age_overall_reputation.png"), width = 8.6, height = 12)

write_csv(
  eda_df %>%
    summarise(
      n = n(),
      zero_value = sum(value_eur == 0),
      midfields = sum(position_group == "Midfield"),
      attacks = sum(position_group == "Attack"),
      defenses = sum(position_group == "Defense"),
      gk = sum(position_group == "GK")
    ),
  file.path(out_dir, "eda_overview.csv")
)

