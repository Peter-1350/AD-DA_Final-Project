source(file.path("data", "FIFA", "out", "scripts", "00_setup.R"))

diag_df <- fifa_df %>%
  filter(value_eur > 0) %>%
  mutate(
    nationality_band = group_by_nationality_band(nationality),
    nationality_band = fct_relevel(nationality_band, "Other"),
    position_group = fct_drop(position_group),
    overall_z = as.numeric(scale(overall)),
    total_stats_z = as.numeric(scale(total_stats)),
    age_z = as.numeric(scale(age))
  )

fit <- lm(log10(value_eur) ~ total_stats_z + age_z + position_group + nationality_band, data = diag_df)

diag_plot <- performance::check_model(fit)
png(file.path(fig_dir, "fig_model_diagnostics.png"), width = 11, height = 8, units = "in", res = 300)
print(diag_plot)
dev.off()

col_tbl <- performance::check_collinearity(fit)
write_csv(as_tibble(col_tbl), file.path(out_dir, "model_collinearity.csv"))

resid_df <- tibble(
  fitted = fitted(fit),
  resid = resid(fit)
)

p_resid <- ggplot(resid_df, aes(x = fitted, y = resid)) +
  geom_point(alpha = 0.25, size = 0.7, color = "#3B5BA5") +
  geom_hline(yintercept = 0, linetype = "dashed", color = "grey50") +
  geom_smooth(se = FALSE, color = "#B23A48", linewidth = 0.8) +
  labs(
    title = "Residuals show no major pattern",
    subtitle = "A quick visual check for nonlinearity and variance changes",
    x = "Fitted log10(value)",
    y = "Residuals"
  )

save_poster_fig(p_resid, file.path(fig_dir, "fig_model_residuals.png"), width = 8.5, height = 6)
