source(file.path("data", "Nationality", "out", "scripts", "00_setup.R"))

analysis_df <- readr::read_csv(file.path(out_dir, "analysis_model_sample.csv"), show_col_types = FALSE) %>%
  mutate(
    cell = factor(cell, levels = selected_cells),
    nationality = factor(nationality, levels = selected_nationalities),
    position_group = factor(position_group),
    ability_tier = factor(ability_tier)
  ) %>%
  droplevels()

fit_full <- glm(
  value_eur ~ cell + nationality + age + potential + overall,
  data = analysis_df,
  family = Gamma(link = "log")
)

coef_full <- broom::tidy(fit_full, exponentiate = TRUE, conf.int = TRUE) %>%
  mutate(
    percent_change = (estimate - 1) * 100,
    ci_low_percent = (conf.low - 1) * 100,
    ci_high_percent = (conf.high - 1) * 100
  )
glance_full <- broom::glance(fit_full)
anova_full <- broom::tidy(car::Anova(fit_full, test.statistic = "LR"))
vif_full <- as_tibble(performance::check_collinearity(fit_full))
outliers_full <- as_tibble(performance::check_outliers(fit_full))

save_check_model_png <- function(check_obj, filename, width = 12, height = 9, dpi = 300) {
  png(file.path(fig_dir, filename), width = width, height = height, units = "in", res = dpi)
  print(check_obj)
  dev.off()
}

readr::write_csv(coef_full, file.path(out_dir, "full_gamma_coefficients.csv"))
readr::write_csv(glance_full, file.path(out_dir, "full_gamma_glance.csv"))
readr::write_csv(anova_full, file.path(out_dir, "full_gamma_anova.csv"))
readr::write_csv(vif_full, file.path(out_dir, "full_gamma_vif.csv"))
readr::write_csv(outliers_full, file.path(out_dir, "full_gamma_outliers.csv"))

diag_full <- performance::check_model(fit_full, residual_type = "normal")
save_check_model_png(diag_full, "fig_diagnostics_full_gamma_model.png")

cell_fits <- readRDS(file.path(out_dir, "cell_gamma_fits.rds"))

walk2(cell_fits$fit, cell_fits$cell, function(fit, cell_name) {
  clean_name <- str_replace_all(str_to_lower(cell_name), "[^a-z0-9]+", "_")
  diag_plot <- performance::check_model(fit, residual_type = "normal")
  save_check_model_png(diag_plot, paste0("fig_diagnostics_gamma_", clean_name, ".png"))
})

nationality_coef <- coef_full %>%
  filter(str_detect(term, "^nationality")) %>%
  mutate(
    nationality = str_remove(term, "^nationality"),
    label = nationality
  )

p_coef <- nationality_coef %>%
  ggplot(aes(x = percent_change, y = reorder(label, percent_change))) +
  geom_vline(xintercept = 0, linetype = "dashed", color = "grey50") +
  geom_errorbar(aes(xmin = ci_low_percent, xmax = ci_high_percent), width = 0.16, color = "grey35") +
  geom_point(size = 3, color = "#2b8cbe") +
  scale_x_continuous(labels = label_percent(scale = 1)) +
  labs(
    title = "Nationality coefficients are modest after controls",
    subtitle = sprintf("Gamma(log), n=%s; reference nationality: Spain", comma(nobs(fit_full))),
    x = "Estimated value ratio vs Spain minus 1",
    y = NULL,
    caption = "Controls: position-rating cell, age, potential, and overall. 95% CIs shown."
  ) +
  theme_poster()
save_poster_fig(p_coef, "fig_full_model_nationality_coefficients.png", width = 8, height = 6)

saveRDS(fit_full, file.path(out_dir, "full_gamma_model.rds"))
