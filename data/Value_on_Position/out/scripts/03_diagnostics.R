source(file.path("data", "Value_on_Position", "out", "scripts", "00_setup.R"))

model_df <- value_df %>%
  filter(!is.na(best_position)) %>%
  mutate(best_position = fct_drop(best_position))

fit_main <- lm(
  log_value ~ best_position + age_z + total_stats_z + pace_z + shooting_z + passing_z +
    dribbling_z + defending_z + physicality_z,
  data = model_df
)

fit_interaction <- lm(
  log_value ~ best_position * (pace_z + shooting_z + passing_z + dribbling_z + defending_z + physicality_z) +
    age_z + total_stats_z,
  data = model_df
)

diag_main_df <- tibble(
  fitted = fitted(fit_main),
  residual = resid(fit_main),
  std_resid = rstandard(fit_main),
  leverage = hatvalues(fit_main),
  cooks = cooks.distance(fit_main)
)

diag_int_df <- tibble(
  fitted = fitted(fit_interaction),
  residual = resid(fit_interaction),
  std_resid = rstandard(fit_interaction),
  leverage = hatvalues(fit_interaction),
  cooks = cooks.distance(fit_interaction)
)

main_diag_tbl <- tibble(
  metric = c("Normality p", "Heteroscedasticity p", "Max VIF", "Influential points"),
  value = c(
    tryCatch(shapiro.test(sample(resid(fit_main), min(length(resid(fit_main)), 5000)))$p.value, error = function(e) NA_real_),
    tryCatch(car::ncvTest(fit_main)$p, error = function(e) NA_real_),
    tryCatch(max(performance::check_collinearity(fit_main)$VIF, na.rm = TRUE), error = function(e) NA_real_),
    tryCatch(sum(abs(rstudent(fit_main)) > 3, na.rm = TRUE), error = function(e) NA_real_)
  )
)

int_diag_tbl <- tibble(
  metric = c("Normality p", "Heteroscedasticity p", "Max VIF", "Influential points"),
  value = c(
    tryCatch(shapiro.test(sample(resid(fit_interaction), min(length(resid(fit_interaction)), 5000)))$p.value, error = function(e) NA_real_),
    tryCatch(car::ncvTest(fit_interaction)$p, error = function(e) NA_real_),
    tryCatch(max(performance::check_collinearity(fit_interaction)$VIF, na.rm = TRUE), error = function(e) NA_real_),
    tryCatch(sum(abs(rstudent(fit_interaction)) > 3, na.rm = TRUE), error = function(e) NA_real_)
  )
)

write_csv(main_diag_tbl, file.path(out_dir, "model_diagnostics_main.csv"))
write_csv(int_diag_tbl, file.path(out_dir, "model_diagnostics_interaction.csv"))

diag_pairs <- model_df %>%
  mutate(
    fitted = fitted(fit_interaction),
    residual = resid(fit_interaction),
    std_resid = rstandard(fit_interaction),
    leverage = hatvalues(fit_interaction),
    cooks = cooks.distance(fit_interaction)
  )

p_resid <- ggplot(diag_pairs, aes(x = fitted, y = residual)) +
  geom_hline(yintercept = 0, linetype = "dashed", color = "grey55") +
  geom_point(alpha = 0.22, size = 0.8, color = viridis(1, option = "D")) +
  labs(
    title = "Residuals vs fitted values show no obvious curvature",
    subtitle = "Interaction model on log10(value + 1) scale",
    x = "Fitted log10(value + 1)",
    y = "Residual"
  )
save_poster_fig(p_resid, file.path(fig_dir, "fig_model_residuals_main.png"), width = 8.5, height = 6)

p_leverage <- ggplot(diag_pairs, aes(x = leverage, y = std_resid)) +
  geom_hline(yintercept = 0, linetype = "dashed", color = "grey55") +
  geom_point(alpha = 0.25, size = 0.8, color = viridis(1, option = "C")) +
  labs(
    title = "Influential points are concentrated at the high-leverage tail",
    subtitle = "Standardized residuals against leverage for the interaction model",
    x = "Leverage",
    y = "Standardized residual"
  )
save_poster_fig(p_leverage, file.path(fig_dir, "fig_model_influence_main.png"), width = 8.5, height = 6)

p_diag_main <- (
  ggplot(diag_main_df, aes(x = fitted, y = residual)) +
    geom_hline(yintercept = 0, linetype = "dashed", color = "grey55") +
    geom_point(alpha = 0.22, size = 0.8, color = viridis(1, option = "D")) +
    labs(
      title = "Main model: residuals vs fitted",
      subtitle = "Look for curvature or changing spread",
      x = "Fitted log10(value + 1)",
      y = "Residual"
    )
) / (
  ggplot(data.frame(sample = resid(fit_main)), aes(sample = sample)) +
    stat_qq(alpha = 0.3, size = 0.8, color = viridis(1, option = "C")) +
    stat_qq_line(color = "firebrick") +
    labs(
      title = "Main model: Q-Q plot",
      subtitle = "Approximate normality is acceptable after the log transform",
      x = "Theoretical quantiles",
      y = "Sample quantiles"
    )
) / (
  ggplot(diag_main_df, aes(x = leverage, y = std_resid)) +
    geom_hline(yintercept = 0, linetype = "dashed", color = "grey55") +
    geom_point(alpha = 0.25, size = 0.8, color = viridis(1, option = "B")) +
    labs(
      title = "Main model: leverage vs standardized residuals",
      subtitle = "High leverage points deserve sensitivity checks",
      x = "Leverage",
      y = "Standardized residual"
    )
) / (
  ggplot(diag_main_df %>% arrange(desc(cooks)) %>% slice_head(n = 20) %>%
           mutate(obs = row_number()),
         aes(x = reorder(as.factor(obs), cooks), y = cooks)) +
    geom_col(fill = viridis(1, option = "D"), alpha = 0.85) +
    coord_flip() +
    labs(
      title = "Main model: top Cook's distance observations",
      subtitle = "Largest 20 observations by influence",
      x = "Observation",
      y = "Cook's distance"
    )
)
save_poster_fig(p_diag_main, file.path(fig_dir, "fig_model_diagnostics_main.png"), width = 11, height = 12)

p_diag_int <- (
  ggplot(diag_int_df, aes(x = fitted, y = residual)) +
    geom_hline(yintercept = 0, linetype = "dashed", color = "grey55") +
    geom_point(alpha = 0.22, size = 0.8, color = viridis(1, option = "D")) +
    labs(
      title = "Interaction model: residuals vs fitted",
      subtitle = "Look for curvature or changing spread",
      x = "Fitted log10(value + 1)",
      y = "Residual"
    )
) / (
  ggplot(data.frame(sample = resid(fit_interaction)), aes(sample = sample)) +
    stat_qq(alpha = 0.3, size = 0.8, color = viridis(1, option = "C")) +
    stat_qq_line(color = "firebrick") +
    labs(
      title = "Interaction model: Q-Q plot",
      subtitle = "Approximate normality is acceptable after the log transform",
      x = "Theoretical quantiles",
      y = "Sample quantiles"
    )
) / (
  ggplot(diag_int_df, aes(x = leverage, y = std_resid)) +
    geom_hline(yintercept = 0, linetype = "dashed", color = "grey55") +
    geom_point(alpha = 0.25, size = 0.8, color = viridis(1, option = "B")) +
    labs(
      title = "Interaction model: leverage vs standardized residuals",
      subtitle = "High leverage points deserve sensitivity checks",
      x = "Leverage",
      y = "Standardized residual"
    )
) / (
  ggplot(diag_int_df %>% arrange(desc(cooks)) %>% slice_head(n = 20) %>%
           mutate(obs = row_number()),
         aes(x = reorder(as.factor(obs), cooks), y = cooks)) +
    geom_col(fill = viridis(1, option = "D"), alpha = 0.85) +
    coord_flip() +
    labs(
      title = "Interaction model: top Cook's distance observations",
      subtitle = "Largest 20 observations by influence",
      x = "Observation",
      y = "Cook's distance"
    )
)
save_poster_fig(p_diag_int, file.path(fig_dir, "fig_model_diagnostics_interaction.png"), width = 11, height = 12)
