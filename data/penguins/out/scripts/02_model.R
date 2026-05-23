source("data/penguins/out/scripts/00_utils.R")

library(dplyr)
library(broom)
library(ggplot2)
library(performance)
library(effectsize)
library(scales)

df <- load_fifa23()

model_df <- df |>
  filter(value_eur > 0) |>
  select(log_value, overall, age, international_reputation, skill_moves) |>
  na.omit()

fit <- lm(log_value ~ overall + age + international_reputation + skill_moves, data = model_df)

coef_tbl <- broom::tidy(fit, conf.int = TRUE)
glance_tbl <- broom::glance(fit)
print(coef_tbl)
print(glance_tbl)

p_coef <- coef_tbl |>
  filter(term != "(Intercept)") |>
  mutate(term = factor(term, levels = term[order(estimate)])) |>
  ggplot(aes(x = estimate, y = term)) +
  geom_vline(xintercept = 0, linetype = "dashed", color = "grey55") +
  geom_errorbar(aes(xmin = conf.low, xmax = conf.high), orientation = "y", width = 0.2, color = "#2C7FB8") +
  geom_point(size = 3, color = "#D95F0E") +
  labs(
    title = "Associations with log market value",
    subtitle = sprintf("n = %d; R² = %.3f; adj. R² = %.3f", nobs(fit), glance_tbl$r.squared, glance_tbl$adj.r.squared),
    x = "Coefficient estimate",
    y = NULL
  ) +
  theme_minimal(base_size = 15) +
  theme(panel.grid.minor = element_blank())

save_poster_fig(p_coef, "fig_model_coefficients.png", width = 9, height = 5.5)

cat("Model complete.\n")
