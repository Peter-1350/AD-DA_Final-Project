source(file.path("data", "Value_on_Position", "out", "scripts", "00_setup.R"))

diag_df <- value_df %>%
  filter(value_eur > 0) %>%
  mutate(
    position_group = fct_drop(position_group),
    age_z = as.numeric(scale(age)),
    total_stats_z = as.numeric(scale(total_stats)),
    pace_z = as.numeric(scale(pace_total)),
    shooting_z = as.numeric(scale(shooting_total)),
    passing_z = as.numeric(scale(passing_total)),
    dribbling_z = as.numeric(scale(dribbling_total)),
    defending_z = as.numeric(scale(defending_total)),
    physicality_z = as.numeric(scale(physicality_total))
  )

fit_main <- lm(
  log_value ~ position_group + age_z + total_stats_z + pace_z + shooting_z + passing_z + dribbling_z + defending_z + physicality_z,
  data = diag_df
)

fit_int <- lm(
  log_value ~ position_group * (pace_z + shooting_z + passing_z + dribbling_z + defending_z + physicality_z) + age_z + total_stats_z,
  data = diag_df
)

main_aug <- broom::augment(fit_main) %>%
  mutate(
    std_resid = rstandard(fit_main),
    leverage = hatvalues(fit_main),
    cooks = cooks.distance(fit_main),
    sqrt_abs_std_resid = sqrt(abs(std_resid))
  )

int_aug <- broom::augment(fit_int) %>%
  mutate(
    std_resid = rstandard(fit_int),
    leverage = hatvalues(fit_int),
    cooks = cooks.distance(fit_int),
    sqrt_abs_std_resid = sqrt(abs(std_resid))
  )

main_diag_panel <- (
  ggplot(main_aug, aes(sample = std_resid)) +
    stat_qq(alpha = 0.3, size = 0.55, color = viridis(1, option = "D")) +
    stat_qq_line(color = "firebrick", linewidth = 0.8) +
    labs(title = "Normal Q-Q", x = "Theoretical quantiles", y = "Standardized residuals")
) | (
  ggplot(main_aug, aes(x = .fitted, y = .resid)) +
    geom_point(alpha = 0.22, size = 0.6, color = viridis(1, option = "D")) +
    geom_hline(yintercept = 0, linetype = "dashed", color = "grey55") +
    geom_smooth(se = FALSE, color = "firebrick", linewidth = 0.8) +
    labs(title = "Residuals vs fitted", x = "Fitted log10(value + 1)", y = "Residual")
) / (
  ggplot(main_aug, aes(x = .fitted, y = sqrt_abs_std_resid)) +
    geom_point(alpha = 0.22, size = 0.6, color = viridis(1, option = "D")) +
    geom_smooth(se = FALSE, color = "firebrick", linewidth = 0.8) +
    labs(title = "Scale-location", x = "Fitted log10(value + 1)", y = "Sqrt(|standardized residual|)")
) | (
  ggplot(main_aug, aes(x = leverage, y = std_resid)) +
    geom_point(aes(size = cooks), alpha = 0.3, color = viridis(1, option = "D")) +
    geom_hline(yintercept = 0, linetype = "dashed", color = "grey55") +
    scale_size_continuous(range = c(0.5, 4), guide = "none") +
    labs(title = "Leverage vs residuals", x = "Leverage", y = "Standardized residuals")
)
save_poster_fig(main_diag_panel, file.path(fig_dir, "fig_model_diagnostics_main.png"), width = 12, height = 9)

int_diag_panel <- (
  ggplot(int_aug, aes(sample = std_resid)) +
    stat_qq(alpha = 0.3, size = 0.55, color = viridis(1, option = "C")) +
    stat_qq_line(color = "firebrick", linewidth = 0.8) +
    labs(title = "Normal Q-Q", x = "Theoretical quantiles", y = "Standardized residuals")
) | (
  ggplot(int_aug, aes(x = .fitted, y = .resid)) +
    geom_point(alpha = 0.22, size = 0.6, color = viridis(1, option = "C")) +
    geom_hline(yintercept = 0, linetype = "dashed", color = "grey55") +
    geom_smooth(se = FALSE, color = "firebrick", linewidth = 0.8) +
    labs(title = "Residuals vs fitted", x = "Fitted log10(value + 1)", y = "Residual")
) / (
  ggplot(int_aug, aes(x = .fitted, y = sqrt_abs_std_resid)) +
    geom_point(alpha = 0.22, size = 0.6, color = viridis(1, option = "C")) +
    geom_smooth(se = FALSE, color = "firebrick", linewidth = 0.8) +
    labs(title = "Scale-location", x = "Fitted log10(value + 1)", y = "Sqrt(|standardized residual|)")
) | (
  ggplot(int_aug, aes(x = leverage, y = std_resid)) +
    geom_point(aes(size = cooks), alpha = 0.3, color = viridis(1, option = "C")) +
    geom_hline(yintercept = 0, linetype = "dashed", color = "grey55") +
    scale_size_continuous(range = c(0.5, 4), guide = "none") +
    labs(title = "Leverage vs residuals", x = "Leverage", y = "Standardized residuals")
)
save_poster_fig(int_diag_panel, file.path(fig_dir, "fig_model_diagnostics_interaction.png"), width = 12, height = 9)

p_main_resid <- ggplot(main_aug, aes(x = .fitted, y = .resid)) +
  geom_point(alpha = 0.22, size = 0.6, color = viridis(1, option = "D")) +
  geom_hline(yintercept = 0, linetype = "dashed", color = "grey55") +
  geom_smooth(se = FALSE, color = "firebrick", linewidth = 0.8) +
  labs(
    title = "Residuals vs fitted for the main model",
    subtitle = "Positive residuals indicate observed value above fitted value",
    x = "Fitted log10(value + 1)",
    y = "Residual"
  )
save_poster_fig(p_main_resid, file.path(fig_dir, "fig_model_residuals_main.png"), width = 8.5, height = 6)

p_main_qq <- ggplot(main_aug, aes(sample = std_resid)) +
  stat_qq(alpha = 0.3, size = 0.55, color = viridis(1, option = "D")) +
  stat_qq_line(color = "firebrick", linewidth = 0.8) +
  labs(
    title = "Normal Q-Q for the main model",
    x = "Theoretical quantiles",
    y = "Standardized residuals"
  )
save_poster_fig(p_main_qq, file.path(fig_dir, "fig_model_qq_main.png"), width = 8, height = 6)

vif_main <- performance::check_collinearity(fit_main) %>% as.data.frame()
vif_int <- performance::check_collinearity(fit_int) %>% as.data.frame()
write_csv(vif_main, file.path(out_dir, "model_collinearity_main.csv"))
write_csv(vif_int, file.path(out_dir, "model_collinearity_interaction.csv"))

diag_summary <- tibble(
  model = c("main", "interaction"),
  n = c(nobs(fit_main), nobs(fit_int)),
  adj_r2 = c(broom::glance(fit_main)$adj.r.squared, broom::glance(fit_int)$adj.r.squared),
  aic = c(AIC(fit_main), AIC(fit_int)),
  max_vif = c(max(vif_main$VIF, na.rm = TRUE), max(vif_int$VIF, na.rm = TRUE)),
  max_cooks = c(max(cooks.distance(fit_main), na.rm = TRUE), max(cooks.distance(fit_int), na.rm = TRUE))
)
write_csv(diag_summary, file.path(out_dir, "model_diagnostics_summary.csv"))
