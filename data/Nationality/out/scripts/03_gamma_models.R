source("data/Nationality/out/scripts/00_setup.R")
library(performance)

test_df <- readRDS(file.path(out_dir, "nationality_test_df.rds"))

model_strata <- tibble(
  position_group = factor(c("Midfielder", "Defender", "Forward"),
                          levels = levels(test_df$position_group)),
  ability_tier = factor(c("Regular (70-77)", "Depth/Youth (<70)", "Depth/Youth (<70)"),
                        levels = levels(test_df$ability_tier)),
  model_id = c("regular_midfielders", "depth_defenders", "depth_forwards")
)

fit_one <- function(position, tier) {
  model_data <- test_df %>%
    filter(position_group == position, ability_tier == tier) %>%
    mutate(
      nationality = fct_infreq(nationality),
      nationality = fct_relevel(nationality, names(sort(table(nationality), decreasing = TRUE))[1]),
      age_z = as.numeric(scale(age)),
      potential_z = as.numeric(scale(potential)),
      total_stats_z = as.numeric(scale(total_stats))
    )

  fit <- glm(
    value_eur ~ nationality + age_z + potential_z + total_stats_z,
    data = model_data,
    family = Gamma(link = "log")
  )

  list(data = model_data, fit = fit)
}

models <- pmap(
  list(model_strata$position_group, model_strata$ability_tier),
  fit_one
)
names(models) <- model_strata$model_id
saveRDS(models, file.path(out_dir, "gamma_model_fits.rds"))

coef_tbl <- imap_dfr(models, function(obj, id) {
  broom::tidy(obj$fit, conf.int = TRUE, exponentiate = TRUE) %>%
    mutate(
      model_id = id,
      n = nrow(obj$data),
      adj_r2 = NA_real_,
      percent_change = 100 * (estimate - 1),
      percent_low = 100 * (conf.low - 1),
      percent_high = 100 * (conf.high - 1)
    ) %>%
    relocate(model_id, n)
})

glance_tbl <- imap_dfr(models, function(obj, id) {
  broom::glance(obj$fit) %>%
    mutate(model_id = id, n = nrow(obj$data)) %>%
    relocate(model_id, n)
})

vif_tbl <- imap_dfr(models, function(obj, id) {
  as.data.frame(performance::check_collinearity(obj$fit)) %>%
    as_tibble() %>%
    mutate(model_id = id) %>%
    relocate(model_id)
})

readr::write_csv(coef_tbl, file.path(out_dir, "gamma_coef_tbl.csv"))
readr::write_csv(glance_tbl, file.path(out_dir, "gamma_glance_tbl.csv"))
readr::write_csv(vif_tbl, file.path(out_dir, "gamma_vif_tbl.csv"))

diag_paths <- imap_chr(models, function(obj, id) {
  p <- performance::check_model(obj$fit, residual_type = "normal")
  path <- file.path(fig_dir, paste0("fig_diag_gamma_", id, ".png"))
  png(path, width = 11, height = 8, units = "in", res = 300)
  print(p)
  dev.off()
  path
})

regular_coef <- coef_tbl %>%
  filter(
    model_id %in% c("regular_midfielders", "depth_defenders", "depth_forwards"),
    str_detect(term, "^nationality")
  ) %>%
  mutate(
    nationality = str_remove(term, "^nationality"),
    model_label = recode(
      model_id,
      regular_midfielders = "Regular midfielders",
      depth_defenders = "Depth defenders",
      depth_forwards = "Depth forwards"
    ),
    pct_label = sprintf("%+.0f%%", percent_change)
  )

p_nat_coef <- ggplot(
  regular_coef,
  aes(x = percent_change, y = fct_reorder(nationality, percent_change), color = model_label)
) +
  geom_vline(xintercept = 0, linetype = "dashed", color = "grey55") +
  geom_errorbar(aes(xmin = percent_low, xmax = percent_high), width = 0.17, linewidth = 0.85) +
  geom_point(size = 3.1) +
  geom_text(aes(label = pct_label), nudge_y = 0.18, size = 4, show.legend = FALSE) +
  facet_wrap(~ model_label, scales = "free_y") +
  scale_x_continuous(labels = label_percent(scale = 1)) +
  scale_color_viridis_d(option = "D", end = 0.78) +
  labs(
    title = "Nationality terms remain after controls",
    subtitle = "Gamma log-link models control age, potential, and total stats",
    x = "Value ratio vs most common nationality (%)",
    y = NULL,
    color = "Model"
  ) +
  theme_poster() +
  theme(legend.position = "none")

save_poster_fig(
  p_nat_coef,
  file.path(fig_dir, "fig_gamma_nationality_coefficients_regular.png"),
  width = 11,
  height = 6.5
)

covar_coef <- coef_tbl %>%
  filter(
    model_id %in% c("regular_midfielders", "depth_defenders", "depth_forwards"),
    term %in% c("age_z", "potential_z", "total_stats_z")
  ) %>%
  mutate(
    term_label = recode(
      term,
      age_z = "Age (1 SD)",
      potential_z = "Potential (1 SD)",
      total_stats_z = "Total stats (1 SD)"
    ),
    model_label = recode(
      model_id,
      regular_midfielders = "Regular midfielders",
      depth_defenders = "Depth defenders",
      depth_forwards = "Depth forwards"
    )
  )

p_cov <- ggplot(covar_coef, aes(x = percent_change, y = term_label, color = model_label)) +
  geom_vline(xintercept = 0, linetype = "dashed", color = "grey55") +
  geom_errorbar(aes(xmin = percent_low, xmax = percent_high), width = 0.2, linewidth = 0.85,
                position = position_dodge(width = 0.45)) +
  geom_point(size = 3, position = position_dodge(width = 0.45)) +
  scale_x_continuous(labels = label_percent(scale = 1)) +
  scale_color_viridis_d(option = "D", end = 0.78) +
  labs(
    title = "Ability covariates dwarf most nationality terms",
    subtitle = "Multiplicative value ratios from Gamma log-link models",
    x = "Expected value difference per 1 SD (%)",
    y = NULL,
    color = "Model"
  ) +
  theme_poster()

save_poster_fig(
  p_cov,
  file.path(fig_dir, "fig_gamma_covariate_coefficients.png"),
  width = 9,
  height = 5.5
)
