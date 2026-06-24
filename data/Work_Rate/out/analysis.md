# Analysis: FIFA 23 Players - Work Rate

## TL;DR
- In this sample of 17,524 players, both attacking and defensive work rates are concentrated in `Medium`, so the poster should emphasize relative shifts rather than raw class balance.
- Broad position is strongly associated with both work-rate outcomes: forwards are more likely to show `High` attacking work rate, while defenders and midfielders are much more likely to show `High` defensive work rate.
- Age is positively associated with both work-rate outcomes in the adjusted multinomial models, with the association stronger for defensive work rate than for attacking work rate.
- Taller players are less likely to be in higher attacking-work-rate categories, but height is only weakly related to defensive work rate after adjustment.
- Weight adds little once age, height, and position group are in the model.
- The adjusted models classify defensive work rate better than attacking work rate, but both models are only moderately accurate and should be treated as descriptive rather than predictive.

## Data
- Source: `data/Work_Rate/FIFA 23 Players.csv`.
- Sample size: `n = 17,524` rows and `p = 89` columns.
- Main variables used: `Attacking Work Rate`, `Defensive Work Rate`, `Age`, `Height(in cm)`, `Weight(in kg)`, and `Best Position`.
- No missing values were observed in the core variables used for the EDA and model.
- Duplicate rows were not detected in the raw file.
- Work rate is imbalanced but not degenerate: attacking work rate is `Low` 4.7%, `Medium` 65.8%, `High` 29.5%; defensive work rate is `Low` 5.3%, `Medium` 73.3%, `High` 21.5%.
- Broad position groups used in modeling were `Forward`, `Midfielder`, `Defender`, `Goalkeeper`, and `Other`; `Other` is kept only as a catch-all level.
- The EDA figures are [`fig_eda_workrate_distribution.png`](figs/fig_eda_workrate_distribution.png), [`fig_eda_position_workrate.png`](figs/fig_eda_position_workrate.png), and [`fig_eda_traits_by_workrate.png`](figs/fig_eda_traits_by_workrate.png).

## EDA
- Both work-rate variables have a strong middle-category concentration, so a three-level model is more appropriate than a binary split.
- The position-work-rate heatmap shows a very strong structural pattern: goalkeepers are entirely concentrated in `Medium` for both work-rate outcomes, forwards are relatively concentrated in `High` attacking work rate, and defenders are relatively concentrated in `High` defensive work rate.
- Age, height, and weight differ across work-rate levels, but the clearest visual separation is by position rather than by body size.
- These plots are the most poster-friendly EDA options because they directly answer the study question and keep the visual message focused.

## Main analysis
- I used two multinomial logistic regressions, one for `Attacking Work Rate` and one for `Defensive Work Rate`, because the outcome has three unordered categories and the proportional-odds route was not stable for the position structure in this sample.
- Both models include standardized age, height, and weight plus broad position group as predictors.
- Attacking-work-rate model fit: accuracy `0.657`, null accuracy `0.658`, pseudo-R2 `0.136`, `n = 17,524`.
- Defensive-work-rate model fit: accuracy `0.734`, null accuracy `0.734`, pseudo-R2 `0.142`, `n = 17,524`.
- In the attacking-work-rate model, age is positively associated with higher categories: `OR = 1.10` for `Medium` vs `Low` per 1 SD increase in age, and `OR = 1.15` for `High` vs `Low`.
- In the attacking-work-rate model, height is negatively associated with higher categories: `OR = 0.58` for `Medium` vs `Low`, and `OR = 0.45` for `High` vs `Low`.
- In the attacking-work-rate model, midfielders and defenders are much less likely than forwards to be in higher attacking-work-rate categories.
- In the defensive-work-rate model, age is positively associated with higher categories: `OR = 1.49` for `Medium` vs `Low`, and `OR = 1.05` for `High` vs `Low`.
- In the defensive-work-rate model, midfielders and defenders are much more likely than forwards to be in higher defensive-work-rate categories.
- Weight is not clearly associated with either outcome after adjustment.
- The coefficient plots are [`fig_model_attack_coefficients.png`](figs/fig_model_attack_coefficients.png) and [`fig_model_defense_coefficients.png`](figs/fig_model_defense_coefficients.png).

## Diagnostics & robustness
- Collinearity is acceptable: adjusted VIF values are about `1.58` for height, `1.54` for weight, and `1.05` for the position block.
- The diagnostic panel is [`fig_model_diagnostics.png`](figs/fig_model_diagnostics.png).
- In-sample classification is modest rather than strong; the models are more useful for describing structure than for making high-confidence individual predictions.
- The defensive-work-rate model performs slightly better than the attacking-work-rate model on accuracy.

## Conclusions
- In this sample, age and broad position are the clearest correlates of work-rate category.
- The strongest qualitative pattern is positional: forwards skew toward higher attacking work rate, while defenders and midfielders skew toward higher defensive work rate.
- Body size matters more weakly than position, with taller players tending to show lower attacking work rate in the adjusted model.

Limitations: this is a cross-sectional observational dataset, so the results support associations, not causal claims. Reverse causation and unmeasured confounding remain plausible, and the broad position grouping may hide within-role heterogeneity.

## Notes for the team
- The raw filename contains spaces, so all scripts use the full path `data/Work_Rate/FIFA 23 Players.csv` directly.
- `polr()` was not stable enough for the position structure because goalkeepers are perfectly concentrated in the middle attacking-work-rate category, so multinomial logistic regression is the safer poster-facing option here.
- The project does not need a separate BMI sensitivity check because the adjusted VIF values for height and weight are comfortably below the usual warning threshold.
- The best poster shortlist is: one EDA distribution chart, one position-by-work-rate heatmap, one body-trait boxplot panel, one coefficient plot for each outcome, and the diagnostic panel.
