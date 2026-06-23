# Analysis: Value Training

## TL;DR
- In this sample of 17,524 FIFA 23 players, market value is extremely right-skewed, and 98 players have exactly zero value, so the main regression uses `log10(value + 1)`.
- Broad role matters: goalkeepers sit far above outfield players in adjusted market value, while midfielders sit below the attack reference group.
- Ability is the strongest predictor in the adjusted model: `TotalStats` has the largest positive coefficient and dominates the coefficient plot.
- Age is negatively associated with market value in the fitted model, but this is a cross-sectional association, not a causal age effect.
- Several nationality groups remain positively associated with value after adjustment, including Brazil, Spain, France, Italy, Germany, Argentina, and the Netherlands.
- The lowest-residual players are often older or lower-profile players in goalkeeper and defensive roles, suggesting that role-specific context matters when flagging undervaluation.

## Data
- Source: `data/FIFA 23 Players.csv`.
- Sample size: `n = 17,524` rows and `p = 89` original columns; the analysis scripts expand this to 115 columns after derived variables.
- Key variables used here: `Value(in Euro)`, `Wage(in Euro)`, `Overall`, `Potential`, `TotalStats`, `Age`, `Best Position`, `Positions Played`, `Nationality`, and the main skill totals.
- Missingness is not a major issue for the main variables used here; the selected fields above have no missing values.
- Boundary values are present: 98 players have zero market value and 86 players have zero wage.
- Market value is heavily right-skewed, with a median of EUR 1.0M and a maximum of EUR 190.5M.
- The broad position grouping used for poster-ready summaries is `Attack`, `Midfield`, `Defense`, and `GK`.
- Data overview and zero-value summary are shown in [`fig_eda_zero_values.png`](/d:\SCHOOL\5.2026-Spring\AS_DA\Final_Project\r-stats-harness\data\Value_Training\out\figs\fig_eda_zero_values.png) and [`fig_eda_skewed_distributions.png`](/d:\SCHOOL\5.2026-Spring\AS_DA\Final_Project\r-stats-harness\data\Value_Training\out\figs\fig_eda_skewed_distributions.png).

## EDA
- Market value and wage are both highly right-skewed, so the log-scale summaries are the most readable way to show the main structure.
- Broad position group shows a large spread in median market value, with goalkeepers clearly separated from outfield roles.
- Among the top 12 nationality groups by sample size, the log-value distributions differ enough to justify including nationality in the model.
- The most poster-ready EDA figures are [`fig_eda_value_by_position.png`](/d:\SCHOOL\5.2026-Spring\AS_DA\Final_Project\r-stats-harness\data\Value_Training\out\figs\fig_eda_value_by_position.png) and [`fig_eda_position_nationality.png`](/d:\SCHOOL\5.2026-Spring\AS_DA\Final_Project\r-stats-harness\data\Value_Training\out\figs\fig_eda_position_nationality.png).

## Main analysis
- I used a linear model for `log10(value + 1)` because the raw outcome is highly skewed and the goal is to summarize adjusted associations rather than make causal claims.
- Model specification: `log10(value_eur + 1) ~ total_stats_z + age_z + position_group + nationality_band`.
- The model explains a moderate share of variation in log-value: `R2 = 0.383`, adjusted `R2 = 0.382`, `n = 17,524`.
- `TotalStats` is the strongest term in the model: estimate `0.668` on the standardized scale, 95% CI `[0.653, 0.682]`.
- `Age` is negatively associated with log-value: estimate `-0.216`, 95% CI `[-0.225, -0.207]`.
- Relative to the attack reference group, `Midfield` is lower and `Defense` is higher on the adjusted log-value scale, while `GK` is much higher.
- Several nationality indicators remain non-zero after adjustment, including positive coefficients for Spain, France, Argentina, Brazil, Italy, Germany, and the Netherlands, and a negative coefficient for China PR.
- The regression coefficient plot is in [`fig_model_coefficients_main.png`](/d:\SCHOOL\5.2026-Spring\AS_DA\Final_Project\r-stats-harness\data\Value_Training\out\figs\fig_model_coefficients_main.png).
- The residual map is in [`fig_model_residual_map.png`](/d:\SCHOOL\5.2026-Spring\AS_DA\Final_Project\r-stats-harness\data\Value_Training\out\figs\fig_model_residual_map.png).
- The most undervalued players within each broad role are summarized in [`fig_model_top_undervalued_by_position.png`](/d:\SCHOOL\5.2026-Spring\AS_DA\Final_Project\r-stats-harness\data\Value_Training\out\figs\fig_model_top_undervalued_by_position.png).
- The top residual table is written to [`top_undervalued_players.csv`](/d:\SCHOOL\5.2026-Spring\AS_DA\Final_Project\r-stats-harness\data\Value_Training\out\top_undervalued_players.csv).

## Diagnostics & robustness
- Collinearity is acceptable: the maximum VIF is about `3.14` for `total_stats_z`, with the other terms below that level.
- Residual diagnostics are mixed: the Shapiro-style normality test is extremely small (`p < 0.001`), and the Breusch-Pagan-style heteroscedasticity check is also small (`p < 0.001`), so the linear model is useful for summary associations but not perfect.
- There are 100 observations with standardized residual magnitude above 3, so a few players are influential enough to keep in mind when interpreting the fitted line.
- The diagnostic panel is saved in [`fig_model_diagnostics_main.png`](/d:\SCHOOL\5.2026-Spring\AS_DA\Final_Project\r-stats-harness\data\Value_Training\out\figs\fig_model_diagnostics_main.png), and the QQ plot is in [`fig_model_residuals_main.png`](/d:\SCHOOL\5.2026-Spring\AS_DA\Final_Project\r-stats-harness\data\Value_Training\out\figs\fig_model_residuals_main.png).
- Because the diagnostics are not fully ideal, any poster wording should stay cautious and avoid overclaiming precision.

## Conclusions
- In this sample, player value is most clearly associated with total ability, broad role, and selected nationality groups.
- The strongest single descriptive pattern is the large separation between goalkeepers and outfield players.
- The age association is negative in the fitted model, but because this is cross-sectional observational data, it should be interpreted as an association in the current sample rather than a developmental effect.

Limitations: this is an observational cross-sectional dataset, so the results support associations, not causal effects. Residual diagnostics show some non-normality and heteroscedasticity, and a number of observations are influential. Unmeasured confounding is plausible, and role, league, contract terms, and injury history may all contribute to the observed value structure.

## Notes for the team
- The README and the actual CSV are consistent on the main research question, but the raw file lives at `data/FIFA 23 Players.csv` rather than inside `data/Value_Training`.
- The analysis is intentionally framed around undervaluation, not “cheap players,” so the poster can make a more defensible claim about residual-based value gaps.
- The most defensible figure set is: EDA value-by-position, EDA position-nationality summary, adjusted coefficient plot, residual map, and the role-specific undervaluation plot.
- The diagnostics are not perfect, so I would avoid strong language like “predicts precisely” or “explains the market.”
