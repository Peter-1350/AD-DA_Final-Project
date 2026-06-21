source(file.path("data", "MidField", "out", "scripts", "00_setup.R"))

diag_df <- fifa_df %>%
  filter(value_eur > 0) %>%
  mutate(
    position_group = fct_relevel(position_group, "Attack"),
    total_stats_z = as.numeric(scale(total_stats)),
    shooting_z = as.numeric(scale(shooting_total)),
    passing_z = as.numeric(scale(passing_total)),
    dribbling_z = as.numeric(scale(dribbling_total)),
    defending_z = as.numeric(scale(defending_total)),
    age_z = as.numeric(scale(age)),
    reputation_z = as.numeric(scale(international_reputation))
  )

fit_m4 <- lm(log10(value_eur) ~ position_group + total_stats_z + shooting_z + passing_z + dribbling_z + defending_z + age_z + reputation_z,
             data = diag_df)

diag_tbl <- broom::augment(fit_m4) %>%
  mutate(
    std_resid = rstandard(fit_m4),
    leverage = hatvalues(fit_m4),
    cooks = cooks.distance(fit_m4),
    sqrt_abs_std_resid = sqrt(abs(std_resid))
  )

p_resid_fit <- ggplot(diag_tbl, aes(x = .fitted, y = .resid)) +
  geom_point(alpha = 0.22, size = 0.6, color = "#3B5BA5") +
  geom_hline(yintercept = 0, linetype = "dashed", color = "grey50") +
  geom_smooth(se = FALSE, color = "#B23A48", linewidth = 0.8) +
  labs(title = "Residuals vs fitted", x = "Fitted log10(value)", y = "Residuals")

p_qq <- ggplot(diag_tbl, aes(sample = std_resid)) +
  stat_qq(alpha = 0.25, size = 0.6, color = "#3B5BA5") +
  stat_qq_line(color = "#B23A48", linewidth = 0.8) +
  labs(title = "Normal Q-Q", x = "Theoretical quantiles", y = "Standardized residuals")

p_scale <- ggplot(diag_tbl, aes(x = .fitted, y = sqrt_abs_std_resid)) +
  geom_point(alpha = 0.22, size = 0.6, color = "#3B5BA5") +
  geom_smooth(se = FALSE, color = "#B23A48", linewidth = 0.8) +
  labs(title = "Scale-location", x = "Fitted log10(value)", y = "Sqrt(abs standardized residuals)")

p_leverage <- ggplot(diag_tbl, aes(x = leverage, y = std_resid)) +
  geom_point(aes(size = cooks), alpha = 0.3, color = "#3B5BA5") +
  geom_hline(yintercept = 0, linetype = "dashed", color = "grey50") +
  scale_size_continuous(range = c(0.5, 4), guide = "none") +
  labs(title = "Leverage vs residuals", x = "Leverage", y = "Standardized residuals")

diag_plot <- (p_resid_fit | p_qq) / (p_scale | p_leverage)
save_poster_fig(diag_plot, file.path(fig_dir, "fig_model_diagnostics_main.png"), width = 12, height = 9)

col_tbl <- performance::check_collinearity(fit_m4)
write_csv(as_tibble(col_tbl), file.path(out_dir, "model_collinearity_m4.csv"))

write_csv(
  tibble(
    metric = c("n", "r2", "adj_r2", "aic", "bic"),
    value = c(nobs(fit_m4), broom::glance(fit_m4)$r.squared, broom::glance(fit_m4)$adj.r.squared, AIC(fit_m4), BIC(fit_m4))
  ),
  file.path(out_dir, "model_summary_m4.csv")
)

