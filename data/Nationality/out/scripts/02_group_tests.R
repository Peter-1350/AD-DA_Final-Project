source(file.path("data", "Nationality", "out", "scripts", "00_setup.R"))

df_model <- readRDS(file.path(out_dir, "df_model.rds"))

analysis_df <- df_model %>%
  filter(cell %in% selected_cells, nationality %in% selected_nationalities) %>%
  group_by(cell, nationality) %>%
  filter(n() >= 20 | cell == "Forward / Rotation 70-77") %>%
  ungroup() %>%
  mutate(
    cell = factor(cell, levels = selected_cells),
    nationality = factor(nationality, levels = selected_nationalities)
  ) %>%
  droplevels()

assumption_tbl <- analysis_df %>%
  group_by(cell, nationality) %>%
  summarise(
    n = n(),
    mean_value_eur = mean(value_eur),
    median_value_eur = median(value_eur),
    sd_log_value = sd(log(value_eur)),
    shapiro_p_log_value = if_else(n() >= 3 & n() <= 5000, shapiro.test(log(value_eur))$p.value, NA_real_),
    .groups = "drop"
  )

levene_tbl <- analysis_df %>%
  group_by(cell) %>%
  group_modify(~{
    lev <- car::leveneTest(log(value_eur) ~ nationality, data = .x)
    broom::tidy(lev) %>% slice(1)
  }) %>%
  ungroup() %>%
  select(cell, statistic, p.value)

fit_cell_gamma <- function(dat) {
  glm(value_eur ~ nationality + age + potential,
      data = dat,
      family = Gamma(link = "log"))
}

fits <- analysis_df %>%
  group_by(cell) %>%
  nest() %>%
  mutate(
    fit = map(data, fit_cell_gamma),
    glance = map(fit, broom::glance),
    anova = map(fit, ~broom::tidy(car::Anova(.x, test.statistic = "LR"))),
    eta_log = map(data, ~{
      lm_fit <- lm(log(value_eur) ~ nationality + age + potential, data = .x)
      effectsize::eta_squared(lm_fit, partial = TRUE) %>% as_tibble()
    }),
    emm = map(fit, ~emmeans::emmeans(.x, ~ nationality, type = "response")),
    pair_summary = map(emm, ~as_tibble(summary(pairs(.x, adjust = "tukey")))),
    pair_ci = map(emm, ~as_tibble(confint(pairs(.x, adjust = "tukey"))))
  )

gamma_tests <- fits %>%
  select(cell, anova) %>%
  unnest(anova) %>%
  filter(term == "nationality") %>%
  transmute(cell, lr_chisq = statistic, df = df, p_value = p.value)

gamma_glance <- fits %>%
  transmute(cell, glance = map(glance, as_tibble)) %>%
  unnest(glance)

eta_tbl <- fits %>%
  select(cell, eta_log) %>%
  unnest(eta_log) %>%
  filter(Parameter == "nationality") %>%
  transmute(cell, partial_eta2_log_lm = Eta2_partial, eta2_ci_low = CI_low, eta2_ci_high = CI_high)

emm_tbl <- fits %>%
  select(cell, emm) %>%
  mutate(emm = map(emm, ~as_tibble(summary(.x)))) %>%
  unnest(emm) %>%
  rename(mean_value_eur = response, se_eur = SE, ci_low_eur = lower.CL, ci_high_eur = upper.CL)

pair_tbl <- fits %>%
  transmute(
    cell,
    pairs = map2(pair_summary, pair_ci, ~left_join(.x, .y, by = c("contrast", "ratio", "SE", "df")))
  ) %>%
  unnest(pairs) %>%
  separate(contrast, into = c("nationality_1", "nationality_2"), sep = " / ", remove = FALSE) %>%
  mutate(
    percent_difference = (ratio - 1) * 100,
    ci_low_percent = (lower.CL - 1) * 100,
    ci_high_percent = (upper.CL - 1) * 100
  )

readr::write_csv(analysis_df, file.path(out_dir, "analysis_model_sample.csv"))
readr::write_csv(assumption_tbl, file.path(out_dir, "assumption_normality_by_group.csv"))
readr::write_csv(levene_tbl, file.path(out_dir, "assumption_levene_by_cell.csv"))
readr::write_csv(gamma_tests, file.path(out_dir, "gamma_nationality_tests.csv"))
readr::write_csv(gamma_glance, file.path(out_dir, "gamma_model_glance.csv"))
readr::write_csv(eta_tbl, file.path(out_dir, "eta_effect_sizes.csv"))
readr::write_csv(emm_tbl, file.path(out_dir, "estimated_mean_values.csv"))
readr::write_csv(pair_tbl, file.path(out_dir, "pairwise_nationality_ratios.csv"))

plot_means <- emm_tbl %>%
  mutate(
    nationality = factor(nationality, levels = selected_nationalities),
    cell = factor(cell, levels = selected_cells)
  ) %>%
  left_join(gamma_tests, by = "cell") %>%
  left_join(eta_tbl, by = "cell") %>%
  mutate(test_label = sprintf("LR p %s; partial eta2=%.3f", fmt_p(p_value), partial_eta2_log_lm))

p_means <- plot_means %>%
  ggplot(aes(x = mean_value_eur, y = fct_rev(nationality), color = nationality)) +
  geom_errorbar(aes(xmin = ci_low_eur, xmax = ci_high_eur), width = 0.18, linewidth = 0.7) +
  geom_point(size = 2.8) +
  facet_wrap(~ paste(cell, test_label, sep = "\n"), scales = "free_x", ncol = 2) +
  scale_x_log10(labels = label_dollar(prefix = "EUR ", scale_cut = cut_short_scale())) +
  scale_color_viridis_d(option = "C", end = 0.9) +
  labs(
    title = "Nationality gaps remain within matched cells",
    subtitle = "Gamma(log) models adjust for age and potential; points are estimated means",
    x = "Estimated market value (EUR, log scale)",
    y = NULL,
    caption = "95% confidence intervals shown. Observational associations, not causal estimates."
  ) +
  theme_poster(base_size = 14) +
  theme(legend.position = "none")
save_poster_fig(p_means, "fig_gamma_adjusted_means_by_cell.png", width = 12, height = 8)

top_pairs <- pair_tbl %>%
  filter(!is.na(p.value), p.value < 0.05) %>%
  mutate(abs_pct = abs(percent_difference)) %>%
  group_by(cell) %>%
  slice_max(abs_pct, n = 4, with_ties = FALSE) %>%
  ungroup() %>%
  mutate(
    contrast_label = paste(nationality_1, "vs", nationality_2),
    cell = factor(cell, levels = selected_cells)
  )

readr::write_csv(top_pairs, file.path(out_dir, "top_pairwise_differences.csv"))

p_pairs <- top_pairs %>%
  ggplot(aes(x = percent_difference, y = reorder(contrast_label, percent_difference))) +
  geom_vline(xintercept = 0, linetype = "dashed", color = "grey50") +
  geom_errorbar(aes(xmin = ci_low_percent, xmax = ci_high_percent), width = 0.18, color = "grey35") +
  geom_point(aes(color = cell), size = 2.8) +
  facet_wrap(~ cell, scales = "free_y", ncol = 2) +
  scale_x_continuous(labels = label_percent(scale = 1)) +
  scale_color_viridis_d(option = "D", end = 0.85) +
  labs(
    title = "Largest adjusted nationality contrasts",
    subtitle = "Tukey-adjusted pairwise ratios from Gamma(log) models",
    x = "Estimated value ratio minus 1",
    y = NULL,
    caption = "Positive values mean the first nationality has the higher adjusted mean."
  ) +
  theme_poster(base_size = 14) +
  theme(legend.position = "none")
save_poster_fig(p_pairs, "fig_top_pairwise_nationality_contrasts.png", width = 12, height = 8)

saveRDS(fits, file.path(out_dir, "cell_gamma_fits.rds"))
