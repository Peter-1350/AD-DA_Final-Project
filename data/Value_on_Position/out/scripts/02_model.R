source(file.path("data", "Value_on_Position", "out", "scripts", "00_setup.R"))

model_df <- value_df %>%
  filter(!is.na(best_position)) %>%
  mutate(
    best_position = fct_drop(best_position),
    best_position = fct_relevel(best_position, "GK"),
    value_positive = value_eur > 0
  )

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

coef_main <- broom::tidy(fit_main, conf.int = TRUE)
glance_main <- broom::glance(fit_main)
coef_int <- broom::tidy(fit_interaction, conf.int = TRUE)
glance_int <- broom::glance(fit_interaction)

vif_main <- performance::check_collinearity(fit_main) %>% as.data.frame()
vif_int <- performance::check_collinearity(fit_interaction) %>% as.data.frame()

write_csv(coef_main, file.path(out_dir, "model_coefficients_main.csv"))
write_csv(glance_main, file.path(out_dir, "model_glance_main.csv"))
write_csv(vif_main, file.path(out_dir, "model_collinearity_main.csv"))
write_csv(coef_int, file.path(out_dir, "model_coefficients_interaction.csv"))
write_csv(glance_int, file.path(out_dir, "model_glance_interaction.csv"))
write_csv(vif_int, file.path(out_dir, "model_collinearity_interaction.csv"))

main_pred <- model_df %>%
  mutate(
    fitted = predict(fit_main, newdata = model_df),
    residual = resid(fit_main),
    std_resid = rstandard(fit_main),
    leverage = hatvalues(fit_main),
    cooks = cooks.distance(fit_main)
  )

int_pred <- model_df %>%
  mutate(
    fitted = predict(fit_interaction, newdata = model_df),
    residual = resid(fit_interaction),
    std_resid = rstandard(fit_interaction),
    leverage = hatvalues(fit_interaction),
    cooks = cooks.distance(fit_interaction)
  )

write_csv(
  main_pred %>%
    select(`Known As`, `Full Name`, best_position, age, overall, total_stats, value_eur, fitted, residual, std_resid, leverage, cooks) %>%
    arrange(desc(abs(residual))) %>%
    slice_head(n = 200),
  file.path(out_dir, "model_main_residuals_top.csv")
)

write_csv(
  int_pred %>%
    select(`Known As`, `Full Name`, best_position, age, overall, total_stats, value_eur, fitted, residual, std_resid, leverage, cooks) %>%
    arrange(desc(abs(residual))) %>%
    slice_head(n = 200),
  file.path(out_dir, "model_interaction_residuals_top.csv")
)

skill_levels <- c("pace_z", "shooting_z", "passing_z", "dribbling_z", "defending_z", "physicality_z")
skill_labels <- c(
  pace_z = "Pace",
  shooting_z = "Shooting",
  passing_z = "Passing",
  dribbling_z = "Dribbling",
  defending_z = "Defending",
  physicality_z = "Physicality"
)

coef_names <- names(coef(fit_interaction))
vc <- vcov(fit_interaction)

position_slopes <- map_dfr(skill_levels, function(skill) {
  position_levels <- levels(model_df$best_position)
  map_dfr(position_levels, function(pos) {
    est <- coef(fit_interaction)[[skill]]
    var <- vc[skill, skill]
    if (pos != "GK") {
      term <- paste0("best_position", pos, ":", skill)
      term2 <- paste0(skill, ":best_position", pos)
      if (term %in% coef_names) {
        est <- est + coef(fit_interaction)[[term]]
        var <- vc[skill, skill] + vc[term, term] + 2 * vc[skill, term]
      } else if (term2 %in% coef_names) {
        est <- est + coef(fit_interaction)[[term2]]
        var <- vc[skill, skill] + vc[term2, term2] + 2 * vc[skill, term2]
      }
    }
    se <- sqrt(var)
    tibble(
      best_position = pos,
      skill = skill_labels[[skill]],
      estimate = est,
      conf.low = est - 1.96 * se,
      conf.high = est + 1.96 * se
    )
  })
})

write_csv(position_slopes, file.path(out_dir, "model_position_skill_slopes.csv"))

p_main_coef <- coef_main %>%
  filter(term != "(Intercept)") %>%
  mutate(term = dplyr::recode(term,
    best_positionCB = "CB vs GK",
    best_positionCAM = "CAM vs GK",
    best_positionCDM = "CDM vs GK",
    best_positionCM = "CM vs GK",
    best_positionLB = "LB vs GK",
    best_positionLW = "LW vs GK",
    best_positionLM = "LM vs GK",
    best_positionLWB = "LWB vs GK",
    best_positionRB = "RB vs GK",
    best_positionRM = "RM vs GK",
    best_positionRWB = "RWB vs GK",
    best_positionRW = "RW vs GK",
    best_positionST = "ST vs GK",
    best_positionCF = "CF vs GK",
    age_z = "Age (z)",
    total_stats_z = "Total stats (z)",
    pace_z = "Pace (z)",
    shooting_z = "Shooting (z)",
    passing_z = "Passing (z)",
    dribbling_z = "Dribbling (z)",
    defending_z = "Defending (z)",
    physicality_z = "Physicality (z)"
  )) %>%
  ggplot(aes(x = estimate, y = fct_reorder(term, estimate))) +
  geom_vline(xintercept = 0, linetype = "dashed", color = "grey55") +
  geom_errorbar(aes(xmin = conf.low, xmax = conf.high), orientation = "y", width = 0.2, color = "grey45") +
  geom_point(size = 2.8, color = viridis(1, option = "D")) +
  labs(
    title = "Skill premiums remain positive after controlling for position",
    subtitle = sprintf("Main-effects model; adj. R² = %.3f; n = %d", glance_main$adj.r.squared, nobs(fit_main)),
    x = "Coefficient estimate on log10(value + 1)",
    y = NULL
  )
save_poster_fig(p_main_coef, file.path(fig_dir, "fig_model_coefficients_main.png"), width = 10, height = 8)

p_int_skill <- position_slopes %>%
  mutate(
    skill = factor(skill, levels = c("Pace", "Shooting", "Passing", "Dribbling", "Defending", "Physicality")),
    best_position = fct_relevel(best_position, "GK")
  ) %>%
  ggplot(aes(x = estimate, y = skill)) +
  geom_vline(xintercept = 0, linetype = "dashed", color = "grey55") +
  geom_errorbar(aes(xmin = conf.low, xmax = conf.high), height = 0.15, color = "grey45") +
  geom_point(size = 2.4, color = viridis(1, option = "D")) +
  facet_wrap(~best_position, nrow = 2) +
  labs(
    title = "Skill slopes differ by position",
    subtitle = sprintf("Total slopes from interaction model; adj. R² = %.3f; n = %d", glance_int$adj.r.squared, nobs(fit_interaction)),
    x = "Slope on log10(value + 1) per 1 SD increase",
    y = NULL
  )
save_poster_fig(p_int_skill, file.path(fig_dir, "fig_model_slopes_by_position.png"), width = 14, height = 8)

p_int_terms <- coef_int %>%
  filter(str_detect(term, ":") | term %in% c(
    "pace_z", "shooting_z", "passing_z", "dribbling_z", "defending_z", "physicality_z"
  )) %>%
  mutate(term = str_replace(term, "best_position", "Position: "),
         term = str_replace(term, "_z", " (z)")) %>%
  ggplot(aes(x = estimate, y = fct_reorder(term, estimate))) +
  geom_vline(xintercept = 0, linetype = "dashed", color = "grey55") +
  geom_errorbar(aes(xmin = conf.low, xmax = conf.high), orientation = "y", width = 0.15, color = "grey45") +
  geom_point(size = 2.3, color = viridis(1, option = "C")) +
  labs(
    title = "Interaction terms are harder to parse than total slopes",
    subtitle = "Use the slope-by-position figure for poster interpretation",
    x = "Coefficient estimate",
    y = NULL
  )
save_poster_fig(p_int_terms, file.path(fig_dir, "fig_model_interaction_terms.png"), width = 11, height = 8)
