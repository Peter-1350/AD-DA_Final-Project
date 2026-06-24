# Analysis: Value_on_Position

## TL;DR
- In these data, market value is strongly right-skewed, so the analysis uses `log10(Value + 1)` to stabilize the scale.
- Player value differs sharply across positions, with central defenders and strikers sitting far above the goalkeeper baseline in the main model.
- In the main regression, all six core skills are positively associated with value after controlling for age, total stats, and position; dribbling, passing, and physicality are the largest main effects.
- The interaction model fits better than the main-effects model, but the skill premiums differ by position, so the slope-by-position figure is the clearest poster-ready summary.
- The diagnostics show strong heteroscedasticity and heavy collinearity, especially once interactions are added, so the results should be treated as descriptive associations rather than clean, isolated effects.

## Data
- Raw data: `n = 17,524` players and `p = 89` columns.
- Working data adds derived variables, so the analysis frame contains more columns than the raw CSV.
- The six required skills are present: Pace, Shooting, Passing, Dribbling, Defending, and Physicality.
- `Best Position` has 15 observed levels in the full dataset.
- Market value includes `98` zero entries, so the modeling workflow keeps them in EDA but uses the log transform for regression.
- The core analysis variables have no missingness; the main data issues are skewness, a zero-value floor, and strong dependence among rating variables.
- See `![](figs/fig_eda_value_distribution.png)` and `![](figs/fig_eda_position_value.png)`.

## EDA
- `![](figs/fig_eda_value_distribution.png)` shows that market value is right-skewed within every broad role.
- `![](figs/fig_eda_position_value.png)` shows large between-position differences in median value.
- `![](figs/fig_eda_skill_profile.png)` shows that position groups have clearly different skill profiles, which motivates position-by-skill interactions.
- `![](figs/fig_eda_skill_vs_value_by_position.png)` shows that the skill-value association is not visually identical across skills or roles.

## Main analysis
- Main model: `log10(Value + 1) ~ Best Position + Age + TotalStats + 6 core skills`.
- Interaction model: `log10(Value + 1) ~ Best Position * 6 core skills + Age + TotalStats`.
- Main model fit: adjusted `R² = 0.450`.
- Interaction model fit: adjusted `R² = 0.540`.
- The main-effects coefficients are summarized in `fig_model_coefficients_main.png`.
- The interaction model is easier to read through position-specific skill slopes in `fig_model_slopes_by_position.png`.
- Main-model coefficients, interaction coefficients, model fit, and collinearity outputs were written to CSV files in `out/`.
- In the main model, all six skills are positive and statistically distinguishable from zero, with the largest coefficients on dribbling, passing, and physicality.
- Age is negatively associated with value after adjustment, while total stats is small and negative once the six detailed skills are in the model, which is a sign of overlap among predictors rather than a standalone substantive claim.
- In the interaction model, the most visible position-specific differences are defensive premiums for defenders and center backs, and shooting premiums for strikers; some skill premiums weaken or reverse outside their natural role.

## Diagnostics & robustness
- The model diagnostics were saved in `fig_model_diagnostics_main.png` and `fig_model_diagnostics_interaction.png`.
- Residual and influence views are also saved separately in `fig_model_residuals_main.png` and `fig_model_influence_main.png`.
- VIF output was saved for both models to document collinearity rather than hide it.
- The workflow keeps zero-value players in the descriptive stage, but the transformed regression avoids the undefined `log(0)` problem.
- The main model already shows substantial collinearity (`max VIF ≈ 550`), and the interaction model is extremely collinear as expected when all position-by-skill terms are included.
- Both models show heteroscedasticity in the residual diagnostics, so coefficient uncertainty should be emphasized over overly literal point-estimate interpretation.

## Conclusions
- In this sample, value is associated with position and with the six core skills, but the size of that association changes by position.
- The most defensible poster takeaway is that there is no single universal "best" skill premium across all positions; the important skill depends on role.
- Because the data are observational and cross-sectional, these results should be described as associations, not causal effects.

Limitations: the dataset is observational, so reverse causation and omitted variables cannot be ruled out. The interaction model is dense and highly collinear, so the slope-by-position figure should be preferred over a raw coefficient table for poster presentation. Residual heteroscedasticity also means the model should be used for descriptive comparison, not precision claims.

## Notes for the team
- `Best Position` is richer than a coarse attack/midfield/defense split, so I kept it as the main factor in the regression and used broad position groups only for EDA.
- The core skill set is intentionally retained in the model because the README defines them as part of the research question. I did not remove variables to reduce VIF.
- If the poster needs one compact figure, `fig_model_slopes_by_position.png` is the most interpretable result.
- `performance::check_model()` could not be used in this environment because the `see` package is unavailable, so the diagnostics figure was rebuilt from explicit residual, Q-Q, leverage, and Cook's distance panels.
