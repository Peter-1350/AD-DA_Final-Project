source(file.path("data", "Value_on_Position", "out", "scripts", "00_setup.R"))

model_df <- value_df %>%
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

skill_z <- c("pace_z", "shooting_z", "passing_z", "dribbling_z", "defending_z", "physicality_z")

fit_main <- lm(
  log_value ~ position_group + age_z + total_stats_z + pace_z + shooting_z + passing_z + dribbling_z + defending_z + physicality_z,
  data = model_df
)

fit_int <- lm(
  log_value ~ position_group * (pace_z + shooting_z + passing_z + dribbling_z + defending_z + physicality_z) + age_z + total_stats_z,
  data = model_df
)

coef_main <- broom::tidy(fit_main, conf.int = TRUE)
glance_main <- broom::glance(fit_main)
coef_int <- broom::tidy(fit_int, conf.int = TRUE)
glance_int <- broom::glance(fit_int)

write_csv(coef_main, file.path(out_dir, "model_coefficients_main.csv"))
write_csv(glance_main, file.path(out_dir, "model_glance_main.csv"))
write_csv(coef_int, file.path(out_dir, "model_coefficients_interaction.csv"))
write_csv(glance_int, file.path(out_dir, "model_glance_interaction.csv"))

vif_main <- performance::check_collinearity(fit_main) %>% as.data.frame()
vif_int <- performance::check_collinearity(fit_int) %>% as.data.frame()
write_csv(vif_main, file.path(out_dir, "model_collinearity_main.csv"))
write_csv(vif_int, file.path(out_dir, "model_collinearity_interaction.csv"))

model_df <- model_df %>%
  mutate(
    fitted_main = fitted(fit_main),
    resid_main = resid(fit_main),
    fitted_int = fitted(fit_int),
    resid_int = resid(fit_int)
  )

p_main_coef <- coef_main %>%
  filter(term != "(Intercept)") %>%
  mutate(
    term = recode(term,
                  position_groupDefense = "Defense vs Attack",
                  position_groupGK = "GK vs Attack",
                  position_groupMidfield = "Midfield vs Attack",
                  age_z = "Age (z)",
                  total_stats_z = "Total stats (z)",
                  pace_z = "Pace (z)",
                  shooting_z = "Shooting (z)",
                  passing_z = "Passing (z)",
                  dribbling_z = "Dribbling (z)",
                  defending_z = "Defending (z)",
                  physicality_z = "Physicality (z)"),
    term = fct_reorder(term, estimate)
  ) %>%
  ggplot(aes(x = estimate, y = term)) +
  geom_vline(xintercept = 0, linetype = "dashed", color = "grey60") +
  geom_errorbar(aes(xmin = conf.low, xmax = conf.high), orientation = "y", width = 0.2, color = "grey40") +
  geom_point(size = 2.8, color = viridis(1, option = "D")) +
  labs(
    title = "Overall associations with player value",
    subtitle = sprintf("n = %d, adj. R² = %.3f", nobs(fit_main), glance_main$adj.r.squared),
    x = "Coefficient estimate on log10(value + 1)",
    y = NULL
  )
save_poster_fig(p_main_coef, file.path(fig_dir, "fig_model_coefficients_main.png"), width = 10, height = 6.5)

p_int_coef <- coef_int %>%
  filter(term != "(Intercept)") %>%
  mutate(
    term = recode(term,
                  position_groupDefense = "Defense vs Attack",
                  position_groupGK = "GK vs Attack",
                  position_groupMidfield = "Midfield vs Attack",
                  `position_groupDefense:pace_z` = "Defense × Pace",
                  `position_groupGK:pace_z` = "GK × Pace",
                  `position_groupMidfield:pace_z` = "Midfield × Pace",
                  `position_groupDefense:shooting_z` = "Defense × Shooting",
                  `position_groupGK:shooting_z` = "GK × Shooting",
                  `position_groupMidfield:shooting_z` = "Midfield × Shooting",
                  `position_groupDefense:passing_z` = "Defense × Passing",
                  `position_groupGK:passing_z` = "GK × Passing",
                  `position_groupMidfield:passing_z` = "Midfield × Passing",
                  `position_groupDefense:dribbling_z` = "Defense × Dribbling",
                  `position_groupGK:dribbling_z` = "GK × Dribbling",
                  `position_groupMidfield:dribbling_z` = "Midfield × Dribbling",
                  `position_groupDefense:defending_z` = "Defense × Defending",
                  `position_groupGK:defending_z` = "GK × Defending",
                  `position_groupMidfield:defending_z` = "Midfield × Defending",
                  `position_groupDefense:physicality_z` = "Defense × Physicality",
                  `position_groupGK:physicality_z` = "GK × Physicality",
                  `position_groupMidfield:physicality_z` = "Midfield × Physicality",
                  age_z = "Age (z)",
                  total_stats_z = "Total stats (z)"),
    term = fct_reorder(term, estimate)
  ) %>%
  ggplot(aes(x = estimate, y = term)) +
  geom_vline(xintercept = 0, linetype = "dashed", color = "grey60") +
  geom_errorbar(aes(xmin = conf.low, xmax = conf.high), orientation = "y", width = 0.2, color = "grey40") +
  geom_point(size = 2.5, color = viridis(1, option = "C")) +
  labs(
    title = "Position-specific skill premiums differ",
    subtitle = sprintf("Interaction model; adj. R² = %.3f", glance_int$adj.r.squared),
    x = "Coefficient estimate on log10(value + 1)",
    y = NULL
  )
save_poster_fig(p_int_coef, file.path(fig_dir, "fig_model_interaction_terms.png"), width = 11.5, height = 8.5)

get_total_slopes <- function(fit, skill, positions = c("Attack", "Midfield", "Defense", "GK")) {
  beta <- coef(fit)
  vc <- vcov(fit)
  pos_terms <- c(
    Attack = skill,
    Midfield = paste0("position_groupMidfield:", skill),
    Defense = paste0("position_groupDefense:", skill),
    GK = paste0("position_groupGK:", skill)
  )
  map_dfr(positions, function(pos) {
    terms <- c(skill, pos_terms[[pos]])
    est <- sum(beta[intersect(names(beta), terms)])
    var <- 0
    for (i in seq_along(terms)) {
      for (j in seq_along(terms)) {
        ti <- terms[i]
        tj <- terms[j]
        if (ti %in% names(beta) && tj %in% names(beta)) {
          var <- var + vc[ti, tj]
        }
      }
    }
    se <- sqrt(var)
    tibble(
      position_group = pos,
      term = skill,
      estimate = est,
      std.error = se,
      conf.low = est - qt(0.975, df.residual(fit)) * se,
      conf.high = est + qt(0.975, df.residual(fit)) * se
    )
  })
}

slopes_tbl <- map_dfr(skill_z, ~ get_total_slopes(fit_int, .x))
slopes_tbl <- slopes_tbl %>%
  mutate(
    skill = recode(term,
                   pace_z = "Pace",
                   shooting_z = "Shooting",
                   passing_z = "Passing",
                   dribbling_z = "Dribbling",
                   defending_z = "Defending",
                   physicality_z = "Physicality"),
    skill = factor(skill, levels = c("Pace", "Shooting", "Passing", "Dribbling", "Defending", "Physicality")),
    position_group = factor(position_group, levels = c("Attack", "Midfield", "Defense", "GK"))
  )
write_csv(slopes_tbl, file.path(out_dir, "model_slopes_by_position.csv"))

p_slopes <- ggplot(slopes_tbl, aes(x = estimate, y = skill)) +
  geom_vline(xintercept = 0, linetype = "dashed", color = "grey60") +
  geom_errorbar(aes(xmin = conf.low, xmax = conf.high), width = 0.15, color = "grey40") +
  geom_point(size = 2.7, color = viridis(1, option = "D")) +
  facet_wrap(~ position_group, nrow = 1) +
  labs(
    title = "Skill-value slopes differ by position",
    subtitle = "Total slopes from the interaction model with 95% confidence intervals",
    x = "Slope on log10(value + 1)",
    y = NULL
  )
save_poster_fig(p_slopes, file.path(fig_dir, "fig_model_slopes_by_position.png"), width = 14, height = 5.5)
