source(file.path("data", "Weak_Foot", "out", "scripts", "00_setup.R"))

model_df <- fifa_df %>%
  filter(value_eur > 0) %>%
  mutate(
    preferred_foot = fct_relevel(preferred_foot, "Right"),
    position_group = fct_drop(position_group),
    weak_foot_rating = fct_drop(weak_foot_rating),
    total_stats_z = as.numeric(scale(total_stats)),
    age_z = as.numeric(scale(age))
  )

fit_main <- lm(log10(value_eur) ~ total_stats_z + age_z + preferred_foot + weak_foot_rating + position_group,
               data = model_df)

coef_main <- broom::tidy(fit_main, conf.int = TRUE)
glance_main <- broom::glance(fit_main)
write_csv(coef_main, file.path(out_dir, "model_coefficients_main.csv"))
write_csv(glance_main, file.path(out_dir, "model_glance_main.csv"))

p_coef <- coef_main %>%
  filter(term != "(Intercept)") %>%
  mutate(term = fct_reorder(term, estimate)) %>%
  ggplot(aes(x = estimate, y = term)) +
  geom_vline(xintercept = 0, linetype = "dashed", color = "grey60") +
  geom_errorbar(aes(xmin = conf.low, xmax = conf.high), orientation = "y", width = 0.2, color = "grey40") +
  geom_point(size = 2.8, color = "#3B5BA5") +
  labs(
    title = "Adjusted associations with log market value",
    subtitle = sprintf("n = %d, R2 = %.3f, adj. R2 = %.3f", nobs(fit_main), glance_main$r.squared, glance_main$adj.r.squared),
    x = "Coefficient estimate [95% CI]",
    y = NULL
  ) +
  theme(axis.text.y = element_text(size = 9))

save_poster_fig(p_coef, file.path(fig_dir, "fig_model_coefficients_main.png"), width = 10, height = 7.2)

foot_by_pos <- model_df %>%
  group_by(position_group, preferred_foot) %>%
  summarise(
    n = n(),
    median_log_value = median(log10(value_eur)),
    .groups = "drop"
  )

p_foot_pos <- ggplot(foot_by_pos, aes(x = position_group, y = median_log_value, fill = preferred_foot, group = preferred_foot)) +
  geom_col(position = position_dodge(width = 0.75), width = 0.7) +
  scale_fill_viridis_d(end = 0.85) +
  labs(
    title = "Preferred-foot differences vary by position group",
    subtitle = "Median log10(value) among positive-value players",
    x = NULL,
    y = "Median log10 market value",
    fill = "Preferred foot"
  ) +
  theme(axis.text.x = element_text(face = "bold"))

save_poster_fig(p_foot_pos, file.path(fig_dir, "fig_model_foot_by_position.png"), width = 9.5, height = 5.8)

fit_int <- lm(log10(value_eur) ~ total_stats_z + age_z + preferred_foot * position_group + weak_foot_rating,
              data = model_df)

coef_int <- broom::tidy(fit_int, conf.int = TRUE)
glance_int <- broom::glance(fit_int)
write_csv(coef_int, file.path(out_dir, "model_coefficients_interaction.csv"))
write_csv(glance_int, file.path(out_dir, "model_glance_interaction.csv"))

interaction_terms <- coef_int %>%
  filter(str_detect(term, "preferred_foot|weak_foot_rating")) %>%
  mutate(term = str_replace(term, "^preferred_foot", "Foot: "),
         term = str_replace(term, "^weak_foot_rating", "Weak foot: "))

write_csv(interaction_terms, file.path(out_dir, "interaction_terms_focus.csv"))
