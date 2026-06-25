source("data/Nationality/out/scripts/00_setup.R")
library(rstatix)
library(car)

df <- readRDS(file.path(out_dir, "clean_fifa_nationality.rds"))

target_strata <- df %>%
  group_by(position_group, ability_tier) %>%
  summarise(
    n = n(),
    top_nat_n = max(table(nationality)),
    n_nat_20 = sum(table(nationality) >= 20),
    .groups = "drop"
  ) %>%
  filter(n >= 250, n_nat_20 >= 4) %>%
  arrange(desc(n_nat_20), desc(n)) %>%
  slice_head(n = 5)

readr::write_csv(target_strata, file.path(out_dir, "target_strata.csv"))

test_df <- target_strata %>%
  select(position_group, ability_tier) %>%
  inner_join(df, by = c("position_group", "ability_tier")) %>%
  group_by(position_group, ability_tier, nationality) %>%
  mutate(n_in_stratum_nat = n()) %>%
  ungroup() %>%
  filter(n_in_stratum_nat >= 20) %>%
  group_by(position_group, ability_tier) %>%
  mutate(
    nationality = fct_lump_n(nationality, n = 6, other_level = "Other"),
    nationality = fct_drop(nationality)
  ) %>%
  ungroup() %>%
  filter(nationality != "Other")

saveRDS(test_df, file.path(out_dir, "nationality_test_df.rds"))

median_boot_ci <- function(data, reps = 1000) {
  set.seed(2301)
  data %>%
    group_by(position_group, ability_tier, nationality) %>%
    summarise(
      n = n(),
      median_value_eur = median(value_eur),
      mean_overall = mean(overall),
      mean_age = mean(age),
      ci = list(quantile(
        replicate(reps, median(sample(value_eur, size = n(), replace = TRUE))),
        probs = c(0.025, 0.975),
        names = FALSE
      )),
      .groups = "drop"
    ) %>%
    mutate(
      conf.low = map_dbl(ci, 1),
      conf.high = map_dbl(ci, 2)
    ) %>%
    select(-ci)
}

median_ci <- median_boot_ci(test_df)
readr::write_csv(median_ci, file.path(out_dir, "median_bootstrap_ci.csv"))

assumption_shapiro <- test_df %>%
  group_by(position_group, ability_tier, nationality) %>%
  summarise(
    n = n(),
    shapiro_p_log_value = if_else(n >= 3 & n <= 5000, shapiro.test(log_value)$p.value, NA_real_),
    .groups = "drop"
  )

assumption_levene <- test_df %>%
  group_by(position_group, ability_tier) %>%
  group_modify(~ {
    out <- car::leveneTest(log_value ~ nationality, data = .x)
    tibble(
      statistic = out[["F value"]][1],
      p_value = out[["Pr(>F)"]][1]
    )
  }) %>%
  ungroup()

kruskal_results <- test_df %>%
  group_by(position_group, ability_tier) %>%
  kruskal_test(log_value ~ nationality) %>%
  ungroup() %>%
  left_join(
    test_df %>%
      group_by(position_group, ability_tier) %>%
      kruskal_effsize(log_value ~ nationality, ci = TRUE) %>%
      ungroup(),
    by = c("position_group", "ability_tier")
  )

pairwise_wilcox <- test_df %>%
  group_by(position_group, ability_tier) %>%
  pairwise_wilcox_test(log_value ~ nationality, p.adjust.method = "BH") %>%
  ungroup()

readr::write_csv(assumption_shapiro, file.path(out_dir, "test_assumption_shapiro.csv"))
readr::write_csv(assumption_levene, file.path(out_dir, "test_assumption_levene.csv"))
readr::write_csv(kruskal_results, file.path(out_dir, "kruskal_results.csv"))
readr::write_csv(pairwise_wilcox, file.path(out_dir, "pairwise_wilcox_results.csv"))

regular_mid <- test_df %>%
  filter(position_group == "Midfielder", ability_tier == "Regular (70-77)") %>%
  mutate(nationality = fct_reorder(nationality, value_eur, .fun = median))

kw_mid <- kruskal_results %>%
  filter(position_group == "Midfielder", ability_tier == "Regular (70-77)")

p_mid <- ggplot(regular_mid, aes(x = nationality, y = value_eur, fill = nationality)) +
  geom_violin(alpha = 0.42, trim = FALSE, show.legend = FALSE) +
  geom_boxplot(width = 0.16, outlier.alpha = 0.35, fill = "white", show.legend = FALSE) +
  scale_y_log10(labels = fmt_eur) +
  scale_fill_viridis_d(option = "D", end = 0.82) +
  labs(
    title = "Regular midfielders show nationality gaps",
    subtitle = sprintf("Kruskal-Wallis H = %.1f, p = %.3g, epsilon2 = %.3f",
                       kw_mid$statistic, kw_mid$p, kw_mid$effsize),
    x = "Nationality",
    y = "Market value (EUR, log scale)",
    caption = "Same position and ability tier; observational association, not causation."
  ) +
  theme_poster() +
  theme(axis.text.x = element_text(angle = 25, hjust = 1))

save_poster_fig(
  p_mid,
  file.path(fig_dir, "fig_regular_midfielder_value_by_nationality.png"),
  width = 9,
  height = 6
)

depth_def <- test_df %>%
  filter(position_group == "Defender", ability_tier == "Depth/Youth (<70)") %>%
  mutate(nationality = fct_reorder(nationality, value_eur, .fun = median))

kw_def <- kruskal_results %>%
  filter(position_group == "Defender", ability_tier == "Depth/Youth (<70)")

p_def <- ggplot(depth_def, aes(x = nationality, y = value_eur, fill = nationality)) +
  geom_violin(alpha = 0.42, trim = FALSE, show.legend = FALSE) +
  geom_boxplot(width = 0.16, outlier.alpha = 0.35, fill = "white", show.legend = FALSE) +
  scale_y_log10(labels = fmt_eur) +
  scale_fill_viridis_d(option = "D", end = 0.82) +
  labs(
    title = "Depth defenders show nationality gaps",
    subtitle = sprintf("Kruskal-Wallis H = %.1f, p = %.3g, epsilon2 = %.3f",
                       kw_def$statistic, kw_def$p, kw_def$effsize),
    x = "Nationality",
    y = "Market value (EUR, log scale)",
    caption = "Same position and ability tier; observational association, not causation."
  ) +
  theme_poster() +
  theme(axis.text.x = element_text(angle = 25, hjust = 1))

save_poster_fig(
  p_def,
  file.path(fig_dir, "fig_depth_defender_value_by_nationality.png"),
  width = 9,
  height = 6
)

median_focus <- median_ci %>%
  filter(
    (ability_tier == "Regular (70-77)" & position_group == "Midfielder") |
      (ability_tier == "Depth/Youth (<70)" & position_group %in% c("Defender", "Forward"))
  ) %>%
  mutate(stratum_label = paste(ability_tier, position_group)) %>%
  group_by(position_group) %>%
  mutate(nationality = fct_reorder(nationality, median_value_eur)) %>%
  ungroup()

p_median <- ggplot(median_focus, aes(x = median_value_eur, y = nationality, color = stratum_label)) +
  geom_errorbar(aes(xmin = conf.low, xmax = conf.high), width = 0.18, linewidth = 0.8) +
  geom_point(size = 3.2) +
  facet_wrap(~ stratum_label, scales = "free_y") +
  scale_x_log10(labels = fmt_eur) +
  scale_color_viridis_d(option = "D", end = 0.78) +
  labs(
    title = "Median value CIs separate several nationalities",
    subtitle = "Bootstrap 95% CIs within selected position-ability strata",
    x = "Median market value (EUR, log scale)",
    y = NULL,
    color = "Position"
  ) +
  theme_poster() +
  theme(legend.position = "none")

save_poster_fig(
  p_median,
  file.path(fig_dir, "fig_regular_median_value_ci.png"),
  width = 10,
  height = 6
)
