library(tidyverse)
library(broom)
library(performance)
library(scales)
library(viridis)
library(glue)

root_dir <- normalizePath(file.path(getwd()), winslash = "/", mustWork = TRUE)
out_dir <- file.path(root_dir, "data", "Nationality", "out")
fig_dir <- file.path(out_dir, "figs")
dir.create(fig_dir, recursive = TRUE, showWarnings = FALSE)

save_poster_fig <- function(plot, filename, width = 8, height = 6) {
  title <- plot$labels$title %||% ""
  subtitle <- plot$labels$subtitle %||% ""
  if (nchar(title) > 75) warning("Long title: ", title)
  if (nchar(subtitle) > 125) warning("Long subtitle: ", subtitle)
  ggsave(file.path(fig_dir, filename), plot, width = width, height = height, dpi = 300)
}

fmt_p <- function(p) {
  case_when(
    is.na(p) ~ "NA",
    p < 0.001 ~ "< .001",
    TRUE ~ paste0("= ", number(p, accuracy = 0.001))
  )
}

model_df <- readRDS(file.path(out_dir, "nationality_test_df.rds")) %>%
  mutate(
    nationality = fct_infreq(nationality),
    position_group = factor(position_group),
    ability_tier = factor(ability_tier)
  )

fit_one <- function(stratum) {
  dat <- model_df %>%
    filter(stratum_label == stratum) %>%
    mutate(
      nationality = fct_relevel(nationality, names(sort(table(nationality), decreasing = TRUE))[1]),
      overall_c = overall - mean(overall),
      potential_c = potential - mean(potential),
      age_c = age - mean(age)
    )

  fit <- glm(
    value_eur ~ nationality + overall_c + potential_c + age_c,
    family = Gamma(link = "log"),
    data = dat
  )

  safe_name <- str_to_lower(str_replace_all(stratum, "[^A-Za-z0-9]+", "_"))

  diag_plot <- plot(performance::check_model(fit, residual_type = "normal"))
  ggsave(
    file.path(fig_dir, paste0("fig_diag_gamma_", safe_name, ".png")),
    diag_plot,
    width = 11,
    height = 8,
    dpi = 300
  )

  vif_tbl <- performance::check_collinearity(fit) %>%
    as_tibble() %>%
    mutate(stratum_label = stratum)

  tidy_tbl <- broom::tidy(fit, conf.int = TRUE, exponentiate = TRUE) %>%
    mutate(
      stratum_label = stratum,
      term_clean = case_when(
        term == "(Intercept)" ~ "Intercept",
        str_starts(term, "nationality") ~ str_remove(term, "^nationality"),
        term == "overall_c" ~ "Overall rating",
        term == "potential_c" ~ "Potential rating",
        term == "age_c" ~ "Age",
        TRUE ~ term
      ),
      percent_diff = (estimate - 1) * 100,
      percent_low = (conf.low - 1) * 100,
      percent_high = (conf.high - 1) * 100
    )

  glance_tbl <- broom::glance(fit) %>%
    mutate(
      stratum_label = stratum,
      n = nobs(fit),
      baseline_nationality = levels(dat$nationality)[1]
    )

  list(fit = fit, tidy = tidy_tbl, glance = glance_tbl, vif = vif_tbl, data = dat)
}

strata <- c("Regular midfielders", "Regular defenders", "Development midfielders")
fits <- setNames(map(strata, fit_one), strata)

coef_tbl <- map_dfr(fits, "tidy")
glance_tbl <- map_dfr(fits, "glance")
vif_tbl <- map_dfr(fits, "vif")

readr::write_csv(coef_tbl, file.path(out_dir, "gamma_coef_tbl.csv"))
readr::write_csv(glance_tbl, file.path(out_dir, "gamma_glance_tbl.csv"))
readr::write_csv(vif_tbl, file.path(out_dir, "gamma_vif_tbl.csv"))
saveRDS(fits, file.path(out_dir, "gamma_model_fits.rds"))

plot_coef <- coef_tbl %>%
  filter(stratum_label %in% c("Regular midfielders", "Regular defenders")) %>%
  filter(str_starts(term, "nationality")) %>%
  left_join(glance_tbl %>% select(stratum_label, baseline_nationality, n), by = "stratum_label") %>%
  group_by(stratum_label) %>%
  mutate(term_clean = fct_reorder(term_clean, percent_diff)) %>%
  ungroup()

regular_stats <- glance_tbl %>%
  filter(stratum_label %in% c("Regular midfielders", "Regular defenders")) %>%
  transmute(stratum_label, label = glue("{stratum_label}: n={n}, baseline={baseline_nationality}")) %>%
  pull(label) %>%
  paste(collapse = "; ")

p_coef <- ggplot(plot_coef, aes(x = percent_diff, y = term_clean, color = stratum_label)) +
  geom_vline(xintercept = 0, linetype = "dashed", color = "grey45") +
  geom_errorbar(aes(xmin = percent_low, xmax = percent_high), width = 0.18, linewidth = 0.8) +
  geom_point(size = 3) +
  facet_wrap(~ stratum_label, scales = "free_y") +
  scale_x_continuous(labels = label_percent(scale = 1)) +
  scale_color_viridis_d(option = "D", end = 0.75) +
  labs(
    title = "Nationality premiums remain modest in regular tier",
    subtitle = regular_stats,
    x = "Value ratio vs baseline nationality (95% CI)",
    y = NULL,
    color = NULL,
    caption = "Gamma GLM with log link; controls: age, overall, potential."
  ) +
  theme_minimal(base_size = 16) +
  theme(
    legend.position = "none",
    plot.title = element_text(face = "bold", size = 18),
    plot.subtitle = element_text(color = "grey30", size = 11),
    plot.caption = element_text(color = "grey45", size = 10, hjust = 0),
    panel.grid.minor = element_blank()
  )

covar_coef <- coef_tbl %>%
  filter(term %in% c("overall_c", "potential_c", "age_c")) %>%
  mutate(
    term_clean = factor(term_clean, levels = c("Age", "Potential rating", "Overall rating")),
    stratum_label = factor(stratum_label, levels = strata)
  )

p_covars <- ggplot(covar_coef, aes(x = percent_diff, y = term_clean, color = stratum_label)) +
  geom_vline(xintercept = 0, linetype = "dashed", color = "grey45") +
  geom_errorbar(aes(xmin = percent_low, xmax = percent_high), width = 0.18, position = position_dodge(width = 0.55)) +
  geom_point(size = 3, position = position_dodge(width = 0.55)) +
  scale_x_continuous(labels = label_percent(scale = 1)) +
  scale_color_viridis_d(option = "D", end = 0.85) +
  labs(
    title = "Ability and potential dominate value associations",
    subtitle = "Gamma log-link coefficients are multiplicative changes per one rating/year",
    x = "Estimated percent difference in value (95% CI)",
    y = NULL,
    color = "Stratum"
  ) +
  theme_minimal(base_size = 16) +
  theme(
    plot.title = element_text(face = "bold", size = 18),
    plot.subtitle = element_text(color = "grey30", size = 12),
    panel.grid.minor = element_blank(),
    legend.position = "bottom"
  )

save_poster_fig(p_coef, "fig_gamma_nationality_coefficients_regular.png", width = 10, height = 6.5)
save_poster_fig(p_covars, "fig_gamma_covariate_coefficients.png", width = 9, height = 6)

cat("Gamma models complete\n")
print(glance_tbl %>% select(stratum_label, n, baseline_nationality, deviance, df.residual, AIC))
print(coef_tbl %>% filter(str_starts(term, "nationality")) %>% arrange(stratum_label, desc(abs(percent_diff))) %>% group_by(stratum_label) %>% slice_head(n = 5))
