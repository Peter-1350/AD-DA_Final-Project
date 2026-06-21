# Analysis: Weak_Foot

## TL;DR
- In this sample, right-footed players dominate numerically, while left-footed players have a modestly higher market-value distribution.
- Weak-foot rating is concentrated at level 3, and higher ratings are associated with higher market value in the raw EDA.
- After adjusting for total ability, age, and position group, left-footed players still show a small negative difference on the log-value scale relative to right-footed players.
- Weak-foot rating shows an overall positive association with log market value, but the pattern is not perfectly linear across levels.
- Position matters: the foot association is not uniform across roles, so a single overall comparison hides some heterogeneity.

## Data
- The dataset contains 17,524 players and 89 columns, with no missing values in the key variables used here.
- Market value and wage are heavily right-skewed, and there are 98 zero market values and 86 zero wages.
- `Preferred Foot` is imbalanced: 4,246 left-footed players versus 13,278 right-footed players.
- `Weak Foot Rating` is concentrated at 3, with relatively few players at the extremes 1 and 5.
- The provided `data/Weak_Foot/README.md` does not match the actual analysis target; I used the current user request and the FIFA 23 player file as the source of truth.
- Reference figure: `![](figs/fig_eda_preferred_foot_share.png)`

## EDA
- The left-footed share is much larger in some roles, especially left-sided defensive and wide positions, while goalkeepers are overwhelmingly right-footed.
- Market value is modestly higher for left-footed players in this sample, but the difference is not large relative to the spread.
- Higher weak-foot ratings track with higher median market value in the raw data.
- Reference figures: `![](figs/fig_eda_position_foot_mix.png)` and `![](figs/fig_eda_value_by_foot_and_weak_foot.png)`

## Main analysis
- I used a multiple linear regression on `log10(value + 1)` to handle the skewed outcome and the zero-value cases.
- Main covariates: `total_stats`, `age`, `preferred_foot`, `weak_foot_rating`, and `position_group`.
- The coefficient table and model fit summary are saved in `out/model_coefficients_main.csv` and `out/model_glance_main.csv`.
- A second specification adds `preferred_foot * position_group` to check whether the foot association varies by role.
- Reference figures: `![](figs/fig_model_coefficients_main.png)` and `![](figs/fig_model_foot_by_position.png)`

## Diagnostics & robustness
- I used a manual four-panel diagnostic figure because `performance::check_model()` was blocked by a missing `see` dependency in this environment.
- I also checked collinearity and saved the summary to `out/model_collinearity_main.csv`.
- Residuals look reasonably contained after the log transform, though the raw outcome remains highly skewed.
- Reference figures: `![](figs/fig_model_diagnostics_main.png)` and `![](figs/fig_model_residuals_main.png)`

## Conclusions
- In this sample, left-footed players show a small negative adjusted difference in log market value relative to right-footed players, while higher weak-foot ratings are associated with higher value overall.
- The role-specific figures suggest that the foot-value relationship varies by position, so the pooled result should not be over-interpreted.
- This analysis is cross-sectional and observational, so it reports associations rather than causal effects.

Limitations: market value is extremely skewed, and some of the apparent associations may partly reflect position mix, scouting conventions, or contract-related factors that are not fully captured here.

## Notes for the team
- The supplied `data/Weak_Foot/README.md` appears to describe a different nationality-focused project. I followed the user’s explicit target instead: preferred foot and weak-foot rating versus market value.
- If you want a cleaner poster, the strongest visuals are likely `fig_eda_position_foot_mix.png`, `fig_eda_value_by_foot_and_weak_foot.png`, and `fig_model_coefficients_main.png`.
- If needed, I can tighten the interaction model further and turn the heterogeneity result into a dedicated heatmap or predicted-value plot.
