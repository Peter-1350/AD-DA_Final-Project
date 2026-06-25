source(file.path("data", "Work_Rate", "out", "scripts", "00_setup.R"))

eda_df <- workrate_df %>%
  mutate(
    position_group = fct_drop(position_group),
    attack_wr = fct_drop(attack_wr),
    defend_wr = fct_drop(defend_wr)
  )

overall_tbl <- eda_df %>%
  summarise(
    n = n(),
    attack_low = mean(attack_wr == "Low"),
    attack_medium = mean(attack_wr == "Medium"),
    attack_high = mean(attack_wr == "High"),
    defend_low = mean(defend_wr == "Low"),
    defend_medium = mean(defend_wr == "Medium"),
    defend_high = mean(defend_wr == "High")
  )

write_csv(overall_tbl, file.path(out_dir, "eda_overall_summary.csv"))

p_dist <- tibble(
  rate_type = c("Attacking", "Defensive"),
  Low = c(mean(eda_df$attack_wr == "Low"), mean(eda_df$defend_wr == "Low")),
  Medium = c(mean(eda_df$attack_wr == "Medium"), mean(eda_df$defend_wr == "Medium")),
  High = c(mean(eda_df$attack_wr == "High"), mean(eda_df$defend_wr == "High"))
) %>%
  pivot_longer(Low:High, names_to = "level", values_to = "share") %>%
  mutate(
    rate_type = factor(rate_type, levels = c("Attacking", "Defensive")),
    level = factor(level, levels = c("Low", "Medium", "High"))
  ) %>%
  ggplot(aes(x = rate_type, y = share, fill = level)) +
  geom_col(position = "stack", width = 0.65, color = "white") +
  geom_text(
    aes(label = percent(share, accuracy = 0.1)),
    position = position_stack(vjust = 0.5),
    size = 4,
    color = "white",
    fontface = "bold"
  ) +
  scale_y_continuous(labels = percent_format(accuracy = 1), expand = expansion(mult = c(0, 0.06))) +
  scale_fill_viridis_d(end = 0.85) +
  labs(
    title = "Work rate is concentrated in the middle category",
    subtitle = sprintf("n = %d players", nrow(eda_df)),
    x = NULL,
    y = "Share of players",
    fill = NULL
  ) +
  theme(
    plot.title = element_text(face = "bold"),
    axis.text.x = element_text(face = "bold"),
    legend.position = "top"
  )

save_poster_fig(p_dist, file.path(fig_dir, "fig_eda_workrate_distribution.png"), width = 8, height = 5.5)

position_share <- eda_df %>%
  count(position_group, attack_wr, name = "n") %>%
  group_by(position_group) %>%
  mutate(share = n / sum(n)) %>%
  ungroup() %>%
  mutate(
    rate_type = "Attacking",
    level = attack_wr
  ) %>%
  select(position_group, rate_type, level, share) %>%
  bind_rows(
    eda_df %>%
      count(position_group, defend_wr, name = "n") %>%
      group_by(position_group) %>%
      mutate(share = n / sum(n)) %>%
      ungroup() %>%
      mutate(
        rate_type = "Defensive",
        level = defend_wr
      ) %>%
      select(position_group, rate_type, level, share)
  ) %>%
  mutate(
    position_group = fct_relevel(position_group, "Forward", "Midfielder", "Defender", "Goalkeeper"),
    rate_type = factor(rate_type, levels = c("Attacking", "Defensive")),
    level = factor(level, levels = c("Low", "Medium", "High"))
  )

p_position <- ggplot(position_share, aes(x = level, y = position_group, fill = share)) +
  geom_tile(color = "white", linewidth = 0.4) +
  geom_text(aes(label = percent(share, accuracy = 1)), size = 4) +
  facet_wrap(~rate_type, nrow = 1) +
  scale_fill_viridis_c(option = "C", labels = percent_format(accuracy = 1)) +
  labs(
    title = "Position and work rate are strongly coupled",
    subtitle = "Row percentages within each broad position group",
    x = "Work rate level",
    y = "Broad position group",
    fill = "Share"
  ) +
  theme(
    plot.title = element_text(face = "bold"),
    legend.position = "top"
  )

save_poster_fig(p_position, file.path(fig_dir, "fig_eda_position_workrate.png"), width = 10.5, height = 5.5)

trait_long <- eda_df %>%
  select(attack_wr, defend_wr, Age, `Height(in cm)`, `Weight(in kg)`) %>%
  pivot_longer(c(Age, `Height(in cm)`, `Weight(in kg)`), names_to = "trait", values_to = "value") %>%
  mutate(
    trait = dplyr::recode(trait,
      Age = "Age (years)",
      `Height(in cm)` = "Height (cm)",
      `Weight(in kg)` = "Weight (kg)"
    ),
    attack_wr = factor(attack_wr, levels = c("Low", "Medium", "High")),
    defend_wr = factor(defend_wr, levels = c("Low", "Medium", "High"))
  )

plot_trait_panel <- function(dat, rate_var, title_text) {
  ggplot(dat, aes(x = .data[[rate_var]], y = value, fill = .data[[rate_var]])) +
    geom_violin(trim = FALSE, alpha = 0.28, color = "grey55") +
    geom_boxplot(width = 0.16, outlier.size = 0.4, alpha = 0.8) +
    facet_wrap(~trait, ncol = 1, scales = "free_y") +
    scale_fill_viridis_d(end = 0.85, guide = "none") +
    labs(
      title = title_text,
      x = "Work rate level",
      y = NULL
    ) +
    theme(
      plot.title = element_text(face = "bold"),
      strip.text = element_text(face = "bold")
    )
}

p_attack_traits <- plot_trait_panel(
  trait_long %>% select(trait, value, attack_wr),
  "attack_wr",
  "Age, height and weight by attacking work rate"
)

p_defend_traits <- plot_trait_panel(
  trait_long %>% select(trait, value, defend_wr),
  "defend_wr",
  "Age, height and weight by defensive work rate"
)

p_traits <- p_attack_traits | p_defend_traits
save_poster_fig(p_traits, file.path(fig_dir, "fig_eda_traits_by_workrate.png"), width = 12.5, height = 8)
