source(file.path("data", "Weak_Foot", "out", "scripts", "00_setup.R"))

eda_df <- fifa_df %>%
  mutate(
    value_positive = value_eur > 0,
    foot_position = fct_lump_n(interaction(position_group, preferred_foot, sep = ": "), n = 12),
    weak_foot_num = as.integer(as.character(weak_foot_rating))
  )

miss_tbl <- tibble(
  variable = c("value_eur", "wage_eur", "overall", "potential", "total_stats", "age", "preferred_foot", "weak_foot_rating"),
  missing = map_int(eda_df[c("value_eur", "wage_eur", "overall", "potential", "total_stats", "age", "preferred_foot", "weak_foot_rating")], ~ sum(is.na(.x))),
  zeros = c(
    sum(eda_df$value_eur == 0),
    sum(eda_df$wage_eur == 0),
    NA_integer_,
    NA_integer_,
    NA_integer_,
    NA_integer_,
    NA_integer_,
    NA_integer_
  )
)

write_csv(miss_tbl, file.path(out_dir, "eda_missingness.csv"))

p_foot <- eda_df %>%
  count(preferred_foot) %>%
  mutate(prop = n / sum(n)) %>%
  ggplot(aes(x = preferred_foot, y = prop, fill = preferred_foot)) +
  geom_col(width = 0.65) +
  geom_text(aes(label = percent(prop, accuracy = 0.1)), vjust = -0.4, size = 4.5) +
  scale_fill_viridis_d(end = 0.85, guide = "none") +
  scale_y_continuous(labels = label_percent()) +
  labs(
    title = "Right-footed players dominate the sample",
    subtitle = sprintf("n = %d; left-footed = %s, right-footed = %s",
                       nrow(eda_df),
                       comma(sum(eda_df$preferred_foot == "Left")),
                       comma(sum(eda_df$preferred_foot == "Right"))),
    x = NULL,
    y = "Share of players"
  ) +
  theme(axis.text.x = element_text(face = "bold"))

save_poster_fig(p_foot, file.path(fig_dir, "fig_eda_preferred_foot_share.png"), width = 7.2, height = 5.2)

p_weak <- eda_df %>%
  count(weak_foot_rating) %>%
  mutate(prop = n / sum(n)) %>%
  ggplot(aes(x = weak_foot_rating, y = prop, fill = weak_foot_rating)) +
  geom_col(width = 0.7) +
  geom_text(aes(label = percent(prop, accuracy = 0.1)), vjust = -0.4, size = 4.2) +
  scale_fill_viridis_d(end = 0.9, guide = "none") +
  scale_y_continuous(labels = label_percent()) +
  labs(
    title = "Most players have mid-range weak-foot ratings",
    subtitle = "Weak-foot rating is concentrated at 3, with few players at the extremes",
    x = "Weak Foot Rating",
    y = "Share of players"
  )

save_poster_fig(p_weak, file.path(fig_dir, "fig_eda_weak_foot_distribution.png"), width = 7.5, height = 5.2)

foot_pos_tbl <- eda_df %>%
  count(position_group, preferred_foot) %>%
  group_by(position_group) %>%
  mutate(prop = n / sum(n)) %>%
  ungroup()

p_pos <- foot_pos_tbl %>%
  filter(position_group != "Other") %>%
  ggplot(aes(x = position_group, y = prop, fill = preferred_foot)) +
  geom_col(position = "fill", width = 0.7) +
  scale_fill_viridis_d(end = 0.85) +
  scale_y_continuous(labels = label_percent()) +
  labs(
    title = "Foot preference differs sharply by position group",
    subtitle = "Goalkeepers and defenders are mostly right-footed; left-footed share is higher in some wide roles",
    x = NULL,
    y = "Within-position share",
    fill = "Preferred foot"
  ) +
  theme(axis.text.x = element_text(face = "bold"))

save_poster_fig(p_pos, file.path(fig_dir, "fig_eda_position_foot_mix.png"), width = 9, height = 5.8)

value_by_foot <- eda_df %>%
  filter(value_eur > 0) %>%
  group_by(preferred_foot) %>%
  summarise(
    n = n(),
    median_value = median(value_eur),
    q25 = quantile(value_eur, 0.25),
    q75 = quantile(value_eur, 0.75),
    .groups = "drop"
  )

value_by_weak <- eda_df %>%
  filter(value_eur > 0) %>%
  group_by(weak_foot_rating) %>%
  summarise(
    n = n(),
    median_value = median(value_eur),
    q25 = quantile(value_eur, 0.25),
    q75 = quantile(value_eur, 0.75),
    .groups = "drop"
  )

p_value_compare <- (
  ggplot(value_by_foot, aes(x = preferred_foot, y = median_value, fill = preferred_foot)) +
    geom_col(width = 0.65) +
    geom_errorbar(aes(ymin = q25, ymax = q75), width = 0.15, linewidth = 0.8) +
    scale_fill_viridis_d(end = 0.85, guide = "none") +
    scale_y_continuous(labels = label_dollar(prefix = "€", scale_cut = cut_short_scale())) +
    labs(
      title = "Left-footed players have a modestly higher value distribution",
      subtitle = "Median and IQR among players with positive market value",
      x = NULL,
      y = "Market value"
    ) +
    theme(axis.text.x = element_text(face = "bold"))
) / (
  ggplot(value_by_weak, aes(x = weak_foot_rating, y = median_value, fill = weak_foot_rating)) +
    geom_col(width = 0.7) +
    geom_errorbar(aes(ymin = q25, ymax = q75), width = 0.15, linewidth = 0.8) +
    scale_fill_viridis_d(end = 0.9, guide = "none") +
    scale_y_continuous(labels = label_dollar(prefix = "€", scale_cut = cut_short_scale())) +
    labs(
      title = "Higher weak-foot ratings line up with higher value",
      subtitle = "Median market value rises across the ordered weak-foot scale",
      x = "Weak Foot Rating",
      y = "Market value"
    )
)

save_poster_fig(p_value_compare, file.path(fig_dir, "fig_eda_value_by_foot_and_weak_foot.png"), width = 9, height = 10)

write_csv(
  eda_df %>%
    summarise(
      n = n(),
      zero_value = sum(value_eur == 0),
      zero_wage = sum(wage_eur == 0),
      left = sum(preferred_foot == "Left"),
      right = sum(preferred_foot == "Right"),
      weak_foot_1 = sum(weak_foot_rating == 1),
      weak_foot_5 = sum(weak_foot_rating == 5)
    ),
  file.path(out_dir, "eda_overview.csv")
)
