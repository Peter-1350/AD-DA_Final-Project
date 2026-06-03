source(file.path("data", "FIFA", "out", "scripts", "00_setup.R"))

model_df <- fifa_df %>%
  filter(value_eur > 0) %>%
  mutate(
    nationality_band = group_by_nationality_band(nationality),
    nationality_band = fct_relevel(nationality_band, "Other"),
    position_group = fct_drop(position_group),
    overall_z = as.numeric(scale(overall)),
    total_stats_z = as.numeric(scale(total_stats)),
    age_z = as.numeric(scale(age))
  )

fit <- lm(log10(value_eur) ~ total_stats_z + age_z + position_group + nationality_band, data = model_df)

coef_tbl <- broom::tidy(fit, conf.int = TRUE) %>%
  filter(term != "(Intercept)") %>%
  mutate(
    term = str_replace(term, "^nationality_band", "Nationality: "),
    term = str_replace(term, "^position_group", "Position: ")
  )

glance_tbl <- broom::glance(fit)
write_csv(coef_tbl, file.path(out_dir, "model_coefficients.csv"))
write_csv(glance_tbl, file.path(out_dir, "model_glance.csv"))

p_coef <- coef_tbl %>%
  mutate(term = fct_reorder(term, estimate)) %>%
  ggplot(aes(x = estimate, y = term)) +
  geom_vline(xintercept = 0, linetype = "dashed", color = "grey60") +
  geom_errorbarh(aes(xmin = conf.low, xmax = conf.high), height = 0.2, color = "grey35") +
  geom_point(size = 2.8, color = "#3B5BA5") +
  labs(
    title = "Adjusted associations with log10 market value",
    subtitle = sprintf(
      "n = %d, R2 = %.3f, adj. R2 = %.3f; positive market values only",
      nobs(fit), glance_tbl$r.squared, glance_tbl$adj.r.squared
    ),
    x = "Coefficient estimate [95% CI]",
    y = NULL
  ) +
  theme(
    plot.title = element_text(face = "bold"),
    axis.text.y = element_text(size = 9)
  )

save_poster_fig(p_coef, file.path(fig_dir, "fig_model_coefficients.png"), width = 10, height = 7)

fit_by_nation <- model_df %>%
  group_by(nationality_band) %>%
  summarise(
    n = n(),
    median_log_value = median(log10(value_eur)),
    .groups = "drop"
  ) %>%
  arrange(desc(median_log_value)) %>%
  mutate(nationality_band = fct_reorder(nationality_band, median_log_value))

p_nation <- fit_by_nation %>%
  ggplot(aes(x = nationality_band, y = median_log_value, fill = nationality_band)) +
  geom_col(width = 0.7, alpha = 0.9) +
  coord_flip() +
  scale_fill_viridis_d(end = 0.9, guide = "none") +
  labs(
    title = "High-value nationalities are concentrated",
    subtitle = "Observed medians among the 12 most frequent nationalities; bands are descriptive only",
    x = NULL,
    y = "Median log10(market value)"
  )

save_poster_fig(p_nation, file.path(fig_dir, "fig_nationality_value_band.png"), width = 9, height = 6.5)
