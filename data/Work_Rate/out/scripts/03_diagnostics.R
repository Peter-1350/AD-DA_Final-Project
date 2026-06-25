source(file.path("data", "Work_Rate", "out", "scripts", "00_setup.R"))

diag_df <- workrate_df %>%
  filter(!is.na(position_group), position_group != "Goalkeeper") %>%
  mutate(
    position_group = fct_drop(position_group),
    position_group = fct_relevel(position_group, "Forward", "Midfielder", "Defender")
  )

vif_fit <- lm(age_z ~ height_z + weight_z + stamina_z + aggression_z + position_group, data = diag_df)
vif_raw <- car::vif(vif_fit)
if (is.matrix(vif_raw)) {
  vif_tbl <- as.data.frame(vif_raw) %>%
    rownames_to_column("term") %>%
    as_tibble()
} else {
  vif_tbl <- tibble(
    term = names(vif_raw),
    `GVIF` = as.numeric(vif_raw),
    Df = 1,
    `GVIF^(1/(2*Df))` = as.numeric(vif_raw)
  )
}
write_csv(vif_tbl, file.path(out_dir, "model_collinearity.csv"))

diag_metrics <- read_csv(file.path(out_dir, "model_metrics.csv"), show_col_types = FALSE)
cm_tbl <- read_csv(file.path(out_dir, "model_confusion_matrices.csv"), show_col_types = FALSE)
coef_tbl <- read_csv(file.path(out_dir, "model_coefficients.csv"), show_col_types = FALSE)

diag_aug <- broom::augment(vif_fit)

p_resid <- ggplot(diag_aug, aes(x = .fitted, y = .resid)) +
  geom_hline(yintercept = 0, linetype = "dashed", color = "grey60") +
  geom_point(alpha = 0.45, size = 1.2, color = "#355C7D") +
  geom_smooth(se = FALSE, color = "#C06C84") +
  labs(
    title = "Residuals vs fitted",
    x = "Fitted values",
    y = "Residuals"
  ) +
  theme(plot.title = element_text(face = "bold"))

p_qq <- ggplot(diag_aug, aes(sample = .std.resid)) +
  stat_qq(alpha = 0.35, size = 1.2, color = "#355C7D") +
  stat_qq_line(color = "#C06C84") +
  labs(
    title = "Normal Q-Q",
    x = "Theoretical quantiles",
    y = "Standardized residuals"
  ) +
  theme(plot.title = element_text(face = "bold"))

p_scale <- ggplot(diag_aug, aes(x = .fitted, y = sqrt(abs(.std.resid)))) +
  geom_point(alpha = 0.45, size = 1.2, color = "#355C7D") +
  geom_smooth(se = FALSE, color = "#C06C84") +
  labs(
    title = "Scale-location",
    x = "Fitted values",
    y = expression(sqrt("|Standardized residuals|"))
  ) +
  theme(plot.title = element_text(face = "bold"))

p_cook <- ggplot(diag_aug, aes(x = seq_along(.cooksd), y = .cooksd)) +
  geom_col(fill = "#355C7D") +
  geom_hline(yintercept = 4 / nrow(diag_aug), linetype = "dashed", color = "grey60") +
  labs(
    title = "Cook's distance",
    x = "Observation index",
    y = "Cook's D"
  ) +
  theme(plot.title = element_text(face = "bold"))

p_model_diag <- (p_resid | p_qq) / (p_scale | p_cook) +
  plot_annotation(
    title = "Linear-model diagnostics",
    subtitle = "Auxiliary lm uses the same predictors as the multinomial models"
  )

ggsave(
  file.path(fig_dir, "fig_model_lm_diagnostics.png"),
  plot = p_model_diag,
  width = 12,
  height = 8.5,
  dpi = 300
)

p_vif <- vif_tbl %>%
  mutate(term = fct_reorder(term, `GVIF^(1/(2*Df))`)) %>%
  ggplot(aes(x = `GVIF^(1/(2*Df))`, y = term, fill = term)) +
  geom_col(width = 0.7, show.legend = FALSE) +
  geom_vline(xintercept = 5, linetype = "dashed", color = "grey50") +
  labs(
    title = "Predictor collinearity is acceptable",
    subtitle = "Adjusted VIF from an auxiliary linear model with the same predictors",
    x = "Adjusted VIF",
    y = NULL
  ) +
  theme(plot.title = element_text(face = "bold"))

plot_cm <- function(dat, ttl) {
  ggplot(dat, aes(x = predicted, y = truth, fill = share)) +
    geom_tile(color = "white") +
    geom_text(aes(label = percent(share, accuracy = 0.1)), size = 4) +
    scale_fill_viridis_c(option = "B", labels = percent_format(accuracy = 1)) +
    labs(title = NULL, x = "Predicted class", y = "Observed class", fill = "Share") +
    theme(
      axis.text.x = element_text(angle = 25, hjust = 1),
      plot.title = element_text(face = "bold")
    )
}

p_cm_attack <- plot_cm(filter(cm_tbl, outcome == "Attacking work rate"), "Attack model confusion matrix")
p_cm_defend <- plot_cm(filter(cm_tbl, outcome == "Defensive work rate"), "Defense model confusion matrix")

p_diag <- (p_vif | p_cm_attack | p_cm_defend) +
  plot_layout(widths = c(1, 1.1, 1.1)) +
  plot_annotation(
    title = "Model checks and in-sample classification fit",
    subtitle = sprintf(
      "A: collinearity check | B: attack confusion matrix | C: defense confusion matrix\nAttack accuracy = %.3f, defense accuracy = %.3f; null = %.3f and %.3f",
      diag_metrics$accuracy[1], diag_metrics$accuracy[2], diag_metrics$null_accuracy[1], diag_metrics$null_accuracy[2]
    ),
    tag_levels = "A"
  )

save_poster_fig(p_diag, file.path(fig_dir, "fig_model_diagnostics.png"), width = 13.5, height = 5.8)

write_csv(coef_tbl, file.path(out_dir, "model_coefficients_checked.csv"))
