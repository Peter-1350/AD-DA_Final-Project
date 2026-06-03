# Analysis: FIFA 23 Players

## TL;DR
- In this sample of 17,524 FIFA 23 players, market value is extremely right-skewed, so the main analysis uses `log10(value)` after dropping the 98 zero-value entries from the regression step.
- Broad role matters: goalkeepers sit far above outfield players in adjusted market value, while midfielders sit below the attack reference group.
- Ability strongly tracks value: `TotalStats` is the dominant positive predictor in the adjusted regression, even after controlling for age, broad position, and a top-nationality grouping.
- Age is negatively associated with value in the adjusted model, but this should be read as an association in cross-sectional data, not a life-cycle effect.
- Nationality still matters after adjustment: several top football nations are positively associated with value, while `China PR` is negative in this sample.
- K-means on standardized ability/value features suggests weak-to-moderate cluster separation, with the clearest silhouette at `k = 2`.

## Data
- Source: FIFA 23 Players CSV.
- Sample size: `n = 17,524` rows, `p = 89` columns.
- Key variables used here: `Value(in Euro)`, `Wage(in Euro)`, `Overall`, `Potential`, `TotalStats`, `Age`, `Best Position`, `Positions Played`, `Nationality`, and the skill totals.
- Missingness is not a major issue for the main variables used in this analysis; the selected numeric fields above have no missing values.
- Boundary values are present: 98 players have zero market value and 86 have zero wage.
- Market value is heavily right-skewed, with a maximum of EUR 190.5M and a median of EUR 1.0M.
- The strongest nationalities by count are England, Germany, Spain, France, Argentina, Brazil, and Italy.
- The broad position grouping used for poster-ready summaries is `Attack`, `Midfield`, `Defense`, and `GK`.
- Data overview and skewness are shown in [`fig_eda_zero_values.png`](figs/fig_eda_zero_values.png) and [`fig_eda_skewed_distributions.png`](figs/fig_eda_skewed_distributions.png).

## EDA
- Market value and wage are both highly right-skewed, so log-scale summaries are the most readable way to show the main structure.
- Zero entries are uncommon but non-trivial, so they were retained in the EDA and handled separately for the log-scale regression step.
- Broad position group shows a large spread in median market value, with goalkeepers notably separated from outfield roles.
- Among the top 12 nationalities by sample size, the log-value distributions differ enough to justify including nationality in the model.
- The EDA figures most suitable for a poster are [`fig_eda_position_nationality.png`](figs/fig_eda_position_nationality.png) and [`fig_eda_skewed_distributions.png`](figs/fig_eda_skewed_distributions.png).

## Main analysis
- I used a linear model for `log10(value)` because the raw outcome is highly skewed and the goal is to summarize adjusted associations rather than produce a causal claim.
- Model specification: `log10(value_eur) ~ total_stats_z + age_z + position_group + nationality_band`.
- This model explains a substantial share of variation in log-value: `R2 = 0.646`, adjusted `R2 = 0.645`, `n = 17,426`.
- `TotalStats` is the strongest term in the model: estimate `0.674` on the standardized scale, 95% CI `[0.665, 0.682]`.
- `Age` is negatively associated with log-value: estimate `-0.191`, 95% CI `[-0.196, -0.185]`.
- Relative to the attack reference group, `Midfield` is lower and `Defense` is higher on the adjusted log-value scale, while `GK` is much higher.
- Several nationality indicators remain non-zero after adjustment, including positive coefficients for Spain, France, Argentina, Brazil, Italy, Germany, and the Netherlands, and a negative coefficient for China PR.
- The regression coefficient plot is in [`fig_model_coefficients.png`](figs/fig_model_coefficients.png).
- The nationality summary plot is in [`fig_nationality_value_band.png`](figs/fig_nationality_value_band.png).

## Diagnostics & robustness
- Collinearity is acceptable: VIF is about `3.14` for `total_stats_z`, `2.92` for `position_group`, `1.33` for `age_z`, and `1.10` for `nationality_band`.
- The diagnostic panel is saved in [`fig_model_diagnostics.png`](figs/fig_model_diagnostics.png).
- The residual plot is in [`fig_model_residuals.png`](figs/fig_model_residuals.png).
- A simple silhouette sweep for k-means on standardized ability/value variables suggests `k = 2` gives the clearest separation, with average silhouette `0.262`.
- Cluster profiles and nationality composition are shown in [`fig_cluster_profiles.png`](figs/fig_cluster_profiles.png), [`fig_cluster_silhouette.png`](figs/fig_cluster_silhouette.png), and [`fig_cluster_nationality_mix.png`](figs/fig_cluster_nationality_mix.png).
- The clustering result should be treated as exploratory structure, not as a definitive latent taxonomy.

## Conclusions
- In this sample, player value is most clearly associated with overall ability, broad role, and selected nationality groups.
- The strongest single descriptive pattern is the large separation between goalkeepers and outfield players.
- The age association is negative in the fitted model, but because this is cross-sectional observational data, this should be interpreted as an association in the current sample rather than a developmental effect.

Limitations: this is an observational cross-sectional dataset, so the results support associations, not causal claims. Unmeasured confounding is plausible, and role, league, contract terms, and injury history may all contribute to the observed value structure.

## Notes for the team
- The README and the original task are consistent on the overall question, but the naming of the raw file is slightly inconsistent with the folder name: the usable file is `data/FIFA 23 Players.csv`.
- `check_model()` from `performance` is not directly saveable with `ggsave()`, so the diagnostics script uses a graphics device and `print()` instead.
- The broad nationality grouping uses the 12 most frequent nationalities plus `Other` to keep the model stable and poster-friendly.
- The k-means step is exploratory and somewhat sensitive to initialization, which is expected on standardized player-rating data with overlapping structure.
- If the team wants a tighter poster, the most defensible figure set is: EDA skewness/zero-values, position-nationality summary, adjusted coefficient plot, and the diagnostic panel.
