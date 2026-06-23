source(file.path("data", "Value_Training", "out", "scripts", "00_setup.R"))

model_df <- value_df %>%
  mutate(
    nationality_band = group_by_nationality_band(nationality),
    total_stats_z = as.numeric(scale(total_stats)),
    age_z = as.numeric(scale(age)),
    pace_z = as.numeric(scale(pace_total)),
    shooting_z = as.numeric(scale(shooting_total)),
    passing_z = as.numeric(scale(passing_total)),
    dribbling_z = as.numeric(scale(dribbling_total)),
    defending_z = as.numeric(scale(defending_total)),
    physicality_z = as.numeric(scale(physicality_total))
  )

fit_main <- lm(
  log_value ~ total_stats_z + age_z + position_group + nationality_band,
  data = model_df
)

coef_main <- broom::tidy(fit_main, conf.int = TRUE)
glance_main <- broom::glance(fit_main)

write_csv(coef_main, file.path(out_dir, "model_coefficients_main.csv"))
write_csv(glance_main, file.path(out_dir, "model_glance_main.csv"))

vif_main <- performance::check_collinearity(fit_main) %>% as.data.frame()
write_csv(vif_main, file.path(out_dir, "model_collinearity_main.csv"))

model_df <- model_df %>%
  mutate(
    fitted = predict(fit_main, newdata = model_df),
    residual = log_value - fitted,
    undervaluation = fitted - log_value,
    undervalue_rank = percent_rank(residual),
    undervalued_flag = residual <= quantile(residual, 0.1)
  )

undervalued_tbl <- model_df %>%
  filter(value_eur > 0) %>%
  arrange(residual) %>%
  select(`Known As`, `Full Name`, best_position, position_group, nationality, age, overall, total_stats, value_eur, fitted, residual, undervaluation) %>%
  slice_head(n = 100)

write_csv(undervalued_tbl, file.path(out_dir, "top_undervalued_players.csv"))

p_coef <- coef_main %>%
  filter(term != "(Intercept)") %>%
  mutate(
    term = fct_reorder(term, estimate),
    term = recode(term,
                  total_stats_z = "Total stats (z)",
                  age_z = "Age (z)",
                  position_groupDefense = "Defense vs Attack",
                  position_groupGK = "GK vs Attack",
                  position_groupMidfield = "Midfield vs Attack",
                  position_groupOther = "Other vs Attack")
  ) %>%
  ggplot(aes(x = estimate, y = term)) +
  geom_vline(xintercept = 0, linetype = "dashed", color = "grey55") +
  geom_errorbar(aes(xmin = conf.low, xmax = conf.high), orientation = "y", width = 0.2, color = "grey45") +
  geom_point(size = 3, color = viridis(1, option = "D")) +
  labs(
    title = "Market value is most strongly associated with total stats",
    subtitle = sprintf("log10(value + 1) model; adj. R² = %.3f; n = %d",
                       glance_main$adj.r.squared, nobs(fit_main)),
    x = "Coefficient estimate",
    y = NULL
  )

save_poster_fig(p_coef, file.path(fig_dir, "fig_model_coefficients_main.png"), width = 9, height = 5.5)

p_resid <- ggplot(model_df, aes(x = fitted, y = residual, color = position_group)) +
  geom_hline(yintercept = 0, linetype = "dashed", color = "grey55") +
  geom_point(alpha = 0.35, size = 1.2) +
  scale_color_viridis_d(end = 0.85) +
  labs(
    title = "Residuals identify players priced below model expectations",
    subtitle = "Positive residuals mean the observed log value is above the fitted value",
    x = "Fitted log10(value + 1)",
    y = "Residual",
    color = "Role"
  )

save_poster_fig(p_resid, file.path(fig_dir, "fig_model_residual_map.png"), width = 8.5, height = 6)

top_undervalued_position <- model_df %>%
  filter(value_eur > 0) %>%
  group_by(position_group) %>%
  slice_min(order_by = residual, n = 5, with_ties = FALSE) %>%
  ungroup() %>%
  arrange(position_group, residual) %>%
  mutate(label = str_trunc(`Known As`, 18))

write_csv(top_undervalued_position, file.path(out_dir, "top_undervalued_by_position.csv"))

p_top <- top_undervalued_position %>%
  mutate(label = fct_reorder(label, residual)) %>%
  ggplot(aes(x = residual, y = label, fill = position_group)) +
  geom_col(width = 0.7, alpha = 0.9) +
  facet_wrap(~position_group, scales = "free_y") +
  scale_fill_viridis_d(end = 0.85, guide = "none") +
  labs(
    title = "Most undervalued players within each broad role",
    subtitle = "Five lowest residuals per role among players with positive market value",
    x = "Residual on log10(value + 1) scale",
    y = NULL
  )

save_poster_fig(p_top, file.path(fig_dir, "fig_model_top_undervalued_by_position.png"), width = 11, height = 7)
