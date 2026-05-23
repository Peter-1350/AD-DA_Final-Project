source("data/penguins/out/scripts/00_utils.R")

library(dplyr)
library(ggplot2)
library(patchwork)
library(broom)
library(scales)
library(performance)

df <- load_fifa23()

model_df <- df |>
  filter(value_eur > 0) |>
  select(log_value, overall, age, international_reputation, skill_moves) |>
  na.omit()

fit <- lm(log_value ~ overall + age + international_reputation + skill_moves, data = model_df)

aug <- broom::augment(fit)
aug$.std_resid <- rstandard(fit)

p_resid <- ggplot(aug, aes(.fitted, .std_resid)) +
  geom_point(alpha = 0.35, size = 1.1, color = "#2C7FB8") +
  geom_hline(yintercept = 0, linetype = "dashed", color = "grey50") +
  geom_smooth(se = FALSE, color = "#D95F0E", linewidth = 0.8) +
  labs(title = "Residuals vs fitted", x = "Fitted log10(value)", y = "Standardized residuals") +
  theme_minimal(base_size = 14) +
  theme(panel.grid.minor = element_blank())

p_qq <- ggplot(aug, aes(sample = .std_resid)) +
  stat_qq(alpha = 0.35, size = 1.1, color = "#2C7FB8") +
  stat_qq_line(color = "#D95F0E") +
  labs(title = "Normal Q-Q plot", x = "Theoretical quantiles", y = "Standardized residuals") +
  theme_minimal(base_size = 14) +
  theme(panel.grid.minor = element_blank())

p_scale <- ggplot(aug, aes(.fitted, sqrt(abs(.std_resid)))) +
  geom_point(alpha = 0.35, size = 1.1, color = "#2C7FB8") +
  geom_smooth(se = FALSE, color = "#D95F0E", linewidth = 0.8) +
  labs(title = "Scale-location", x = "Fitted log10(value)", y = expression(sqrt("|Standardized residuals|"))) +
  theme_minimal(base_size = 14) +
  theme(panel.grid.minor = element_blank())

infl <- influence.measures(fit)
cook <- cooks.distance(fit)
aug$.cooks <- cook
p_cook <- ggplot(aug, aes(x = seq_along(.cooks), y = .cooks)) +
  geom_col(fill = "#7A5195", alpha = 0.8) +
  geom_hline(yintercept = 4 / nrow(model_df), linetype = "dashed", color = "grey50") +
  labs(title = "Cook's distance", x = "Observation index", y = "Cook's D") +
  theme_minimal(base_size = 14) +
  theme(panel.grid.minor = element_blank())

diag_plot <- (p_resid | p_qq) / (p_scale | p_cook) +
  plot_annotation(title = "Regression diagnostics for log10(value) model",
                  subtitle = "Manual residual checks and influence screen")

save_poster_fig(diag_plot, "fig_model_diagnostics.png", width = 12, height = 9)

cat("High influence points threshold (4/n) = ", 4 / nrow(model_df), "\n")
cat("Max Cook's distance = ", max(cook), "\n")
print(performance::check_collinearity(fit))

cat("Diagnostics complete.\n")
