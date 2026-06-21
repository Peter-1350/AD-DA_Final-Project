source(file.path("data", "Weak_Foot", "out", "scripts", "00_setup.R"))

diag_df <- fifa_df %>%
  filter(value_eur > 0) %>%
  mutate(
    preferred_foot = fct_relevel(preferred_foot, "Right"),
    position_group = fct_drop(position_group),
    weak_foot_rating = fct_drop(weak_foot_rating),
    total_stats_z = as.numeric(scale(total_stats)),
    age_z = as.numeric(scale(age))
  )

fit_main <- lm(log10(value_eur) ~ total_stats_z + age_z + preferred_foot + weak_foot_rating + position_group,
               data = diag_df)

diag_tbl <- broom::augment(fit_main) %>%
  mutate(
    std_resid = rstandard(fit_main),
    leverage = hatvalues(fit_main),
    cooks = cooks.distance(fit_main),
    sqrt_abs_std_resid = sqrt(abs(std_resid))
  )

p_resid_fit <- ggplot(diag_tbl, aes(x = .fitted, y = .resid)) +
  geom_point(alpha = 0.25, size = 0.6, color = "#3B5BA5") +
  geom_hline(yintercept = 0, linetype = "dashed", color = "grey50") +
  geom_smooth(se = FALSE, color = "#B23A48", linewidth = 0.8) +
  labs(
    title = "Residuals vs fitted",
    x = "Fitted log10(value)",
    y = "Residuals"
  )

p_qq <- ggplot(diag_tbl, aes(sample = std_resid)) +
  stat_qq(alpha = 0.3, size = 0.6, color = "#3B5BA5") +
  stat_qq_line(color = "#B23A48", linewidth = 0.8) +
  labs(
    title = "Normal Q-Q",
    x = "Theoretical quantiles",
    y = "Standardized residuals"
  )

p_scale <- ggplot(diag_tbl, aes(x = .fitted, y = sqrt_abs_std_resid)) +
  geom_point(alpha = 0.25, size = 0.6, color = "#3B5BA5") +
  geom_smooth(se = FALSE, color = "#B23A48", linewidth = 0.8) +
  labs(
    title = "Scale-location",
    x = "Fitted log10(value)",
    y = "Sqrt(abs standardized residuals)"
  )

p_leverage <- ggplot(diag_tbl, aes(x = leverage, y = std_resid)) +
  geom_point(aes(size = cooks), alpha = 0.3, color = "#3B5BA5") +
  geom_hline(yintercept = 0, linetype = "dashed", color = "grey50") +
  scale_size_continuous(range = c(0.5, 4), guide = "none") +
  labs(
    title = "Leverage vs residuals",
    x = "Leverage",
    y = "Standardized residuals"
  )

diag_plot <- (p_resid_fit | p_qq) / (p_scale | p_leverage)
save_poster_fig(diag_plot, file.path(fig_dir, "fig_model_diagnostics_main.png"), width = 12, height = 9)

col_tbl <- performance::check_collinearity(fit_main)
write_csv(as_tibble(col_tbl), file.path(out_dir, "model_collinearity_main.csv"))

resid_df <- tibble(
  fitted = fitted(fit_main),
  resid = resid(fit_main)
)

p_resid <- ggplot(resid_df, aes(x = fitted, y = resid)) +
  geom_point(alpha = 0.25, size = 0.7, color = "#3B5BA5") +
  geom_hline(yintercept = 0, linetype = "dashed", color = "grey50") +
  geom_smooth(se = FALSE, color = "#B23A48", linewidth = 0.8) +
  labs(
    title = "Residuals show limited structure after transformation",
    subtitle = "Quick visual check for nonlinearity and heteroscedasticity",
    x = "Fitted log10(value)",
    y = "Residuals"
  )

save_poster_fig(p_resid, file.path(fig_dir, "fig_model_residuals_main.png"), width = 8.5, height = 6)

model_summary <- tibble(
  metric = c("n", "r2", "adj_r2", "aic", "bic"),
  value = c(nobs(fit_main), glance(fit_main)$r.squared, glance(fit_main)$adj.r.squared, AIC(fit_main), BIC(fit_main))
)

write_csv(model_summary, file.path(out_dir, "model_summary_main.csv"))
