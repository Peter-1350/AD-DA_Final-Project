source(file.path("data", "Work_Rate", "out", "scripts", "00_setup.R"))

diag_df <- workrate_df %>%
  filter(!is.na(position_group)) %>%
  mutate(
    position_group = fct_drop(position_group),
    position_group = fct_relevel(position_group, "Forward", "Midfielder", "Defender", "Goalkeeper")
  )

vif_fit <- lm(age_z ~ height_z + weight_z + position_group, data = diag_df)
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

p_vif <- vif_tbl %>%
  mutate(term = fct_reorder(term, `GVIF^(1/(2*Df))`)) %>%
  ggplot(aes(x = `GVIF^(1/(2*Df))`, y = term, fill = term)) +
  geom_col(width = 0.7, show.legend = FALSE) +
  geom_vline(xintercept = 5, linetype = "dashed", color = "grey50") +
  labs(
    title = "Predictor collinearity is acceptable",
    subtitle = "VIF values are computed from an auxiliary linear model with the same predictors",
    x = "Adjusted VIF",
    y = NULL
  ) +
  theme(plot.title = element_text(face = "bold"))

plot_cm <- function(dat, ttl) {
  ggplot(dat, aes(x = predicted, y = truth, fill = share)) +
    geom_tile(color = "white") +
    geom_text(aes(label = percent(share, accuracy = 0.1)), size = 4) +
    scale_fill_viridis_c(option = "B", labels = percent_format(accuracy = 1)) +
    labs(title = ttl, x = "Predicted class", y = "Observed class", fill = "Share") +
    theme(plot.title = element_text(face = "bold"), axis.text.x = element_text(angle = 25, hjust = 1))
}

p_cm_attack <- plot_cm(filter(cm_tbl, outcome == "Attacking work rate"), "Attack model confusion matrix")
p_cm_defend <- plot_cm(filter(cm_tbl, outcome == "Defensive work rate"), "Defense model confusion matrix")

p_diag <- (p_vif | p_cm_attack | p_cm_defend) +
  plot_layout(widths = c(1, 1.1, 1.1)) +
  plot_annotation(
    title = "Model checks and in-sample classification fit",
    subtitle = sprintf(
      "Attack accuracy = %.3f, defense accuracy = %.3f; null accuracies are %.3f and %.3f",
      diag_metrics$accuracy[1], diag_metrics$accuracy[2], diag_metrics$null_accuracy[1], diag_metrics$null_accuracy[2]
    )
  )

save_poster_fig(p_diag, file.path(fig_dir, "fig_model_diagnostics.png"), width = 13.5, height = 5.8)
