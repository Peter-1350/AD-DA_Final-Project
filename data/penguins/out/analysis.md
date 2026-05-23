# Analysis: FIFA 23 Players

## TL;DR
- Player market value and wage are both strongly right-skewed; log transformation is needed for readable plots and stable modeling.
- In this file, 98 players have `Value(in Euro) = 0` and 86 have `Wage(in Euro) = 0`, so zero values must be handled separately from the positive-valued sample.
- Among players with positive value, the median market value is `EUR 1,000,000` and the 90th percentile is `EUR 5,500,000`.
- In the linear model, `Overall`, `Age`, `International Reputation`, and `Skill Moves` are all associated with log market value.
- Higher `Overall` is associated with higher market value, while `Age` is negatively associated with market value after adjustment for the other predictors in the model.
- This is observational cross-sectional data, so the results should be described as associations, not causal effects.

## Data
- Source file: `data/FIFA 23 Players.csv`
- Sample size: `n = 17,524` players and `p = 89` variables.
- Distinct categories: 679 clubs, 157 nationalities, and 15 best-position categories.
- Zero values: 98 players with zero value and 86 players with zero wage.
- The core fields used in the model have no missing values after filtering to the positive-value sample.
- Positive-value quantiles: median `EUR 1,000,000`, IQR `EUR 500,000` to `EUR 2,000,000`, 90th percentile `EUR 5,500,000`.
- Positive-wage quantiles: median `EUR 3,000`, IQR `EUR 1,000` to `EUR 8,000`, 90th percentile `EUR 22,000`.
- Reference figure: `![](figs/fig_eda_distributions.png)`

## EDA
- The distributions of value and wage are long-tailed, and the log scale makes the central mass visible.
- The most common best positions are `CB`, `ST`, `CAM`, `GK`, `RM`, and `CDM`.
- The scatterplots show a strong positive relationship between `Overall` and market value.
- Age shows a curved relationship with market value, which supports including it in the model rather than relying on a purely linear one-variable description.
- Reference figure: `![](figs/fig_eda_relationships.png)`

## Main analysis
- Model used: `log10(value_eur) ~ overall + age + international_reputation + skill_moves`, restricted to players with positive value.
- This model was chosen because it is interpretable, compact enough for a poster, and directly aligned with the question about which features are associated with market value.
- The fitted model uses `n = 17,426` players after removing zero-value observations.
- Estimated coefficients on the log10 scale:
  - `overall`: 0.0826, 95% CI [0.0823, 0.0829]
  - `age`: -0.0526, 95% CI [-0.0530, -0.0523]
  - `international_reputation`: 0.0737, 95% CI [0.0691, 0.0782]
  - `skill_moves`: 0.0410, 95% CI [0.0389, 0.0430]
- Model fit: `R^2 = 0.966`, adjusted `R^2 = 0.966`.
- Reference figure: `![](figs/fig_model_coefficients.png)`

## Diagnostics & robustness
- Residual diagnostics were checked with a residual-vs-fitted plot, a normal Q-Q plot, a scale-location plot, and a Cook's distance plot.
- The common rough influence threshold `4/n` is about `0.00023`, while the maximum Cook's distance is `0.04895`, so a few observations deserve inspection.
- Collinearity is low: VIF values are 1.17 to 1.67 across the predictors.
- The model is statistically strong, but the diagnostics still matter because a high `R^2` does not guarantee perfect assumptions.
- Reference figure: `![](figs/fig_model_diagnostics.png)`

## Conclusions
- In this sample, players with higher `Overall` ratings tend to have higher market values, and older players tend to have lower market values after adjustment for the other modeled variables.
- `International Reputation` and `Skill Moves` also show positive associations with market value.
- Because the data are observational and cross-sectional, these findings should be framed as associations, not causal effects.

**Limitations**: Zero-valued players were excluded from the log-scale model, so the fitted model applies to the positive-valued subset rather than the full file. Unmeasured factors such as injuries, contract terms, league strength, and team context may also matter.

## Notes for the team
- The repository directory name is still `penguins`, but the actual dataset used here is FIFA 23 Players. Keep the folder name if that is required by the harness, but avoid writing Palmer Penguins in the analysis materials.
- `performance::check_model()` was not used because the local environment was missing the `see` dependency, so I used explicit residual and influence diagnostics instead.
- The analysis is intentionally narrow: a poster only needs a few strong findings, not every possible FIFA 23 variable.
