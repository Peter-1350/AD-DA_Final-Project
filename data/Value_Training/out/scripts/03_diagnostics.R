source(file.path("data", "Value_Training", "out", "scripts", "00_setup.R"))

model_df <- value_df %>%
  mutate(
    nationality_band = group_by_nationality_band(nationality),
    total_stats_z = as.numeric(scale(total_stats)),
    age_z = as.numeric(scale(age))
  )

fit_main <- lm(
  log10(value_eur + 1) ~ total_stats_z + age_z + position_group + nationality_band,
  data = model_df
)

diag_df <- tibble(
  fitted = fitted(fit_main),
  resid = resid(fit_main),
  std_resid = rstandard(fit_main),
  leverage = hatvalues(fit_main),
  cooks = cooks.distance(fit_main)
)

diag_top <- diag_df %>%
  mutate(row_id = row_number()) %>%
  arrange(desc(cooks)) %>%
  slice_head(n = 20)

p_diag <- (
  ggplot(diag_df, aes(x = fitted, y = resid)) +
    geom_hline(yintercept = 0, linetype = "dashed", color = "grey55") +
    geom_point(alpha = 0.25, size = 0.9, color = viridis(1, option = "D")) +
    labs(
      title = "Residuals vs fitted values",
      subtitle = "Log10(value + 1) model; no strong curvature would support linear specification",
      x = "Fitted log10(value + 1)",
      y = "Residual"
    )
) / (
  ggplot(data.frame(sample = resid(fit_main)), aes(sample = sample)) +
    stat_qq(alpha = 0.3, size = 0.9, color = viridis(1, option = "D")) +
    stat_qq_line(color = "firebrick") +
    labs(
      title = "Residual QQ plot",
      subtitle = "Normality is approximate after the log transform",
      x = "Theoretical quantiles",
      y = "Sample quantiles"
    )
) / (
  ggplot(diag_df, aes(x = leverage, y = std_resid)) +
    geom_hline(yintercept = 0, linetype = "dashed", color = "grey55") +
    geom_vline(xintercept = 2 * mean(diag_df$leverage), linetype = "dotted", color = "grey55") +
    geom_point(alpha = 0.35, size = 0.9, color = viridis(1, option = "D")) +
    labs(
      title = "Leverage vs standardized residuals",
      subtitle = "Potential influence points sit far from the center with large leverage or residuals",
      x = "Leverage",
      y = "Standardized residual"
    )
) / (
  ggplot(diag_top, aes(x = reorder(as.factor(row_id), cooks), y = cooks)) +
    geom_col(fill = viridis(1, option = "D"), alpha = 0.85) +
    coord_flip() +
    labs(
      title = "Top Cook's distance observations",
      subtitle = "Largest 20 observations by influence",
      x = "Observation",
      y = "Cook's distance"
    )
)

save_poster_fig(p_diag, file.path(fig_dir, "fig_model_diagnostics_main.png"), width = 11, height = 12)

p_qq <- ggplot(data.frame(resid = resid(fit_main)), aes(sample = resid)) +
  stat_qq(alpha = 0.35, size = 1.2) +
  stat_qq_line(color = "firebrick") +
  labs(
    title = "Residual QQ plot",
    subtitle = "Diagnostic support for the transformed-value regression",
    x = "Theoretical quantiles",
    y = "Sample residual quantiles"
  )

save_poster_fig(p_qq, file.path(fig_dir, "fig_model_residuals_main.png"), width = 7.5, height = 5.5)

diag_tbl <- tibble(
  statistic = c(
    "normality_p",
    "heteroscedasticity_p",
    "collinearity_max_vif",
    "influential_points"
  ),
  value = c(
    tryCatch(shapiro.test(sample(resid(fit_main), min(length(resid(fit_main)), 5000)))$p.value, error = function(e) NA_real_),
    tryCatch(broom::tidy(lm(abs(resid(fit_main)) ~ fitted(fit_main)))$p.value[2], error = function(e) NA_real_),
    max(tryCatch(performance::check_collinearity(fit_main)$VIF, error = function(e) NA_real_), na.rm = TRUE),
    tryCatch(sum(abs(rstudent(fit_main)) > 3, na.rm = TRUE), error = function(e) NA_real_)
  )
)

write_csv(diag_tbl, file.path(out_dir, "model_diagnostics_main.csv"))
