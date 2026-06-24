source(file.path("data", "Work_Rate", "out", "scripts", "00_setup.R"))

model_df <- workrate_df %>%
  filter(!is.na(position_group)) %>%
  mutate(
    position_group = fct_drop(position_group),
    position_group = fct_relevel(position_group, "Forward", "Midfielder", "Defender", "Goalkeeper")
  )

tidy_multinom <- function(fit, outcome_name) {
  s <- summary(fit)
  coefs <- as.data.frame(s$coefficients) %>%
    rownames_to_column("y.level") %>%
    pivot_longer(-y.level, names_to = "term", values_to = "estimate")
  ses <- as.data.frame(s$standard.errors) %>%
    rownames_to_column("y.level") %>%
    pivot_longer(-y.level, names_to = "term", values_to = "std.error")
  left_join(coefs, ses, by = c("y.level", "term")) %>%
    mutate(
      statistic = estimate / std.error,
      p.value = 2 * pnorm(-abs(statistic)),
      conf.low = estimate - 1.96 * std.error,
      conf.high = estimate + 1.96 * std.error,
      outcome = outcome_name,
      or = exp(estimate),
      or.low = exp(conf.low),
      or.high = exp(conf.high)
    )
}

fit_attack <- multinom(
  attack_wr ~ age_z + height_z + weight_z + position_group,
  data = model_df,
  trace = FALSE,
  MaxNWts = 2000
)

fit_defend <- multinom(
  defend_wr ~ age_z + height_z + weight_z + position_group,
  data = model_df,
  trace = FALSE,
  MaxNWts = 2000
)

attack_tbl <- tidy_multinom(fit_attack, "Attacking work rate")
defend_tbl <- tidy_multinom(fit_defend, "Defensive work rate")
coef_tbl <- bind_rows(attack_tbl, defend_tbl) %>%
  mutate(
    term = dplyr::recode(term,
      `(Intercept)` = "Intercept",
      age_z = "Age (z)",
      height_z = "Height (z)",
      weight_z = "Weight (z)",
      position_groupMidfielder = "Position: Midfielder",
      position_groupDefender = "Position: Defender",
      position_groupGoalkeeper = "Position: Goalkeeper",
      position_groupOther = "Position: Other"
    ),
    y.level = factor(y.level, levels = c("Medium", "High"))
  ) %>%
  filter(term != "Intercept")

write_csv(coef_tbl, file.path(out_dir, "model_coefficients.csv"))

null_attack <- multinom(attack_wr ~ 1, data = model_df, trace = FALSE)
null_defend <- multinom(defend_wr ~ 1, data = model_df, trace = FALSE)

pred_attack <- predict(fit_attack, type = "class")
pred_defend <- predict(fit_defend, type = "class")
truth_attack <- as.character(model_df$attack_wr)
truth_defend <- as.character(model_df$defend_wr)
pred_attack_chr <- as.character(pred_attack)
pred_defend_chr <- as.character(pred_defend)

conf_mat <- function(truth, pred, outcome_name) {
  tbl <- as.data.frame.matrix(table(truth = truth, predicted = pred)) %>%
    rownames_to_column("truth") %>%
    pivot_longer(-truth, names_to = "predicted", values_to = "n") %>%
    mutate(
      outcome = outcome_name,
      share = n / sum(n)
    )
  tbl
}

attack_cm <- conf_mat(truth_attack, pred_attack_chr, "Attacking work rate")
defend_cm <- conf_mat(truth_defend, pred_defend_chr, "Defensive work rate")
cm_tbl <- bind_rows(attack_cm, defend_cm)
write_csv(cm_tbl, file.path(out_dir, "model_confusion_matrices.csv"))

metrics_tbl <- tibble(
  outcome = c("Attacking work rate", "Defensive work rate"),
  accuracy = c(mean(pred_attack_chr == truth_attack), mean(pred_defend_chr == truth_defend)),
  null_accuracy = c(max(prop.table(table(truth_attack))), max(prop.table(table(truth_defend)))),
  macro_recall = c(
    mean(diag(prop.table(table(truth = truth_attack, predicted = pred_attack_chr), 1)), na.rm = TRUE),
    mean(diag(prop.table(table(truth = truth_defend, predicted = pred_defend_chr), 1)), na.rm = TRUE)
  ),
  aic = c(AIC(fit_attack), AIC(fit_defend)),
  pseudo_r2 = c(
    1 - (as.numeric(logLik(fit_attack)) / as.numeric(logLik(null_attack))),
    1 - (as.numeric(logLik(fit_defend)) / as.numeric(logLik(null_defend)))
  ),
  n = nrow(model_df)
)
write_csv(metrics_tbl, file.path(out_dir, "model_metrics.csv"))

attack_plot_tbl <- attack_tbl %>%
  mutate(
    term = dplyr::recode(term,
      age_z = "Age (z)",
      height_z = "Height (z)",
      weight_z = "Weight (z)",
      position_groupMidfielder = "Position: Midfielder",
      position_groupDefender = "Position: Defender",
      position_groupGoalkeeper = "Position: Goalkeeper"
    ),
    term = fct_rev(fct_reorder(term, or, .fun = median))
  ) %>%
  filter(term %in% c("Age (z)", "Height (z)", "Weight (z)", "Position: Midfielder", "Position: Defender", "Position: Goalkeeper"))

defend_plot_tbl <- defend_tbl %>%
  mutate(
    term = dplyr::recode(term,
      age_z = "Age (z)",
      height_z = "Height (z)",
      weight_z = "Weight (z)",
      position_groupMidfielder = "Position: Midfielder",
      position_groupDefender = "Position: Defender",
      position_groupGoalkeeper = "Position: Goalkeeper"
    ),
    term = fct_rev(fct_reorder(term, or, .fun = median))
  ) %>%
  filter(term %in% c("Age (z)", "Height (z)", "Weight (z)", "Position: Midfielder", "Position: Defender", "Position: Goalkeeper"))

p_attack <- ggplot(attack_plot_tbl, aes(x = or, y = term)) +
  geom_vline(xintercept = 1, linetype = "dashed", color = "grey60") +
  geom_errorbar(aes(xmin = or.low, xmax = or.high), orientation = "y", width = 0.18, color = "grey45") +
  geom_point(size = 3, color = "#355C7D") +
  facet_wrap(~y.level, ncol = 1) +
  scale_x_log10() +
  labs(
    title = "Adjusted associations with attacking work rate",
    subtitle = sprintf(
      "Multinomial logit; n = %d; accuracy = %.3f; pseudo-R2 = %.3f",
      nrow(model_df), metrics_tbl$accuracy[1], metrics_tbl$pseudo_r2[1]
    ),
    x = "Relative risk ratio [95% CI]",
    y = NULL
  ) +
  theme(
    plot.title = element_text(face = "bold"),
    strip.text = element_text(face = "bold")
  )

save_poster_fig(p_attack, file.path(fig_dir, "fig_model_attack_coefficients.png"), width = 9.5, height = 7)

p_defend <- ggplot(defend_plot_tbl, aes(x = or, y = term)) +
  geom_vline(xintercept = 1, linetype = "dashed", color = "grey60") +
  geom_errorbar(aes(xmin = or.low, xmax = or.high), orientation = "y", width = 0.18, color = "grey45") +
  geom_point(size = 3, color = "#C06C84") +
  facet_wrap(~y.level, ncol = 1) +
  scale_x_log10() +
  labs(
    title = "Adjusted associations with defensive work rate",
    subtitle = sprintf(
      "Multinomial logit; n = %d; accuracy = %.3f; pseudo-R2 = %.3f",
      nrow(model_df), metrics_tbl$accuracy[2], metrics_tbl$pseudo_r2[2]
    ),
    x = "Relative risk ratio [95% CI]",
    y = NULL
  ) +
  theme(
    plot.title = element_text(face = "bold"),
    strip.text = element_text(face = "bold")
  )

save_poster_fig(p_defend, file.path(fig_dir, "fig_model_defense_coefficients.png"), width = 9.5, height = 7)
