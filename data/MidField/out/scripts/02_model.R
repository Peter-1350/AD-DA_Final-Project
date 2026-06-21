source(file.path("data", "MidField", "out", "scripts", "00_setup.R"))

model_df <- fifa_df %>%
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

fit_m1 <- lm(log10(value_eur) ~ position_group, data = model_df)
fit_m2 <- lm(log10(value_eur) ~ position_group + total_stats_z, data = model_df)
fit_m3 <- lm(log10(value_eur) ~ position_group + total_stats_z + shooting_z + passing_z + dribbling_z + defending_z, data = model_df)
fit_m4 <- lm(log10(value_eur) ~ position_group + total_stats_z + shooting_z + passing_z + dribbling_z + defending_z + age_z + reputation_z, data = model_df)

models <- list(Model_1 = fit_m1, Model_2 = fit_m2, Model_3 = fit_m3, Model_4 = fit_m4)

coef_path <- map_dfr(names(models), function(m) {
  fit <- models[[m]]
  broom::tidy(fit, conf.int = TRUE) %>%
    filter(term == "position_groupMidfield") %>%
    mutate(model = m)
})

write_csv(coef_path, file.path(out_dir, "midfield_coef_path.csv"))
write_csv(map_dfr(names(models), function(m) {
  broom::glance(models[[m]]) %>% mutate(model = m)
}), file.path(out_dir, "midfield_model_glance.csv"))

p_path <- ggplot(coef_path, aes(x = model, y = estimate, group = 1)) +
  geom_hline(yintercept = 0, linetype = "dashed", color = "grey60") +
  geom_line(linewidth = 0.8, color = "#3B5BA5") +
  geom_point(size = 3, color = "#3B5BA5") +
  geom_errorbar(aes(ymin = conf.low, ymax = conf.high), width = 0.12, color = "#3B5BA5") +
  labs(
    title = "The midfielder gap shrinks as controls are added",
    subtitle = "Coefficient for Midfield relative to Attack across the same sample",
    x = NULL,
    y = "Midfield coefficient on log10(value)"
  )

save_poster_fig(p_path, file.path(fig_dir, "fig_model_midfield_path.png"), width = 8.2, height = 5.6)

coef_table <- bind_rows(
  broom::tidy(fit_m1, conf.int = TRUE) %>% mutate(model = "Model 1"),
  broom::tidy(fit_m2, conf.int = TRUE) %>% mutate(model = "Model 2"),
  broom::tidy(fit_m3, conf.int = TRUE) %>% mutate(model = "Model 3"),
  broom::tidy(fit_m4, conf.int = TRUE) %>% mutate(model = "Model 4")
)

write_csv(coef_table, file.path(out_dir, "midfield_coefficients_all_models.csv"))

demo_fit <- model_df %>%
  mutate(pred_m1 = predict(fit_m1), pred_m4 = predict(fit_m4)) %>%
  select(position_group, pred_m1, pred_m4, value_eur) %>%
  group_by(position_group) %>%
  summarise(
    observed_median = median(value_eur),
    pred_m1_median = median(pred_m1),
    pred_m4_median = median(pred_m4),
    .groups = "drop"
  )

p_pred <- demo_fit %>%
  pivot_longer(c(pred_m1_median, pred_m4_median), names_to = "model", values_to = "pred") %>%
  mutate(model = recode(model, pred_m1_median = "Model 1 fitted", pred_m4_median = "Model 4 fitted")) %>%
  ggplot(aes(x = position_group, y = pred, fill = model)) +
  geom_col(position = position_dodge(width = 0.75), width = 0.7) +
  scale_fill_viridis_d(end = 0.9) +
  scale_y_continuous(labels = label_dollar(prefix = "€", scale_cut = cut_short_scale())) +
  labs(
    title = "Controls move the fitted midfield gap toward zero",
    subtitle = "Predicted market value by position from the simplest and richest models",
    x = NULL,
    y = "Predicted market value",
    fill = NULL
  ) +
  theme(axis.text.x = element_text(face = "bold"))

save_poster_fig(p_pred, file.path(fig_dir, "fig_model_predicted_position_values.png"), width = 9, height = 6)

