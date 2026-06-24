# Analysis: FIFA 23 Players - Work Rate

## TL;DR
- In this sample of 17,524 players, both attacking and defensive work rates are concentrated in `Medium`, so the poster should emphasize relative shifts rather than raw class balance.
- Broad position is the clearest structural correlate: forwards are much more concentrated in higher attacking work rate, while defenders and midfielders are much more concentrated in higher defensive work rate.
- After adjusting for age, height, weight, stamina, and aggression, older players are less likely to be in higher work-rate categories for both outcomes, but the pattern is stronger for defensive work rate.
- Stamina is positively associated with both work-rate outcomes, while aggression is negatively associated with attacking work rate and strongly positively associated with defensive work rate.
- Weight adds little once the other predictors are in the model; height is more clearly tied to attacking than defensive work rate.
- The adjusted multinomial models are better at describing group structure than at making precise individual predictions.

## Data
- Source: `data/Work_Rate/FIFA 23 Players.csv`.
- Sample size: `n = 17,524` rows and `p = 89` columns.
- Main variables used: `Attacking Work Rate`, `Defensive Work Rate`, `Age`, `Height(in cm)`, `Weight(in kg)`, `Stamina`, `Aggression`, and `Best Position`.
- No missing values were observed in the core variables used for the EDA and models.
- Duplicate rows were not detected in the raw file.
- Work rate is imbalanced but not degenerate: attacking work rate is `Low` 4.7%, `Medium` 65.8%, `High` 29.5%; defensive work rate is `Low` 8.4%, `Medium` 73.4%, `High` 18.2%.
- Goalkeepers are a special case: all 1,965 goalkeepers are `Medium` for both attacking and defensive work rate, so they are described separately and excluded from the multinomial regressions.
- Broad position groups used in EDA were `Forward`, `Midfielder`, `Defender`, and `Goalkeeper`.
- The EDA figures are [`fig_eda_workrate_distribution.png`](figs/fig_eda_workrate_distribution.png), [`fig_eda_position_workrate.png`](figs/fig_eda_position_workrate.png), and [`fig_eda_traits_by_workrate.png`](figs/fig_eda_traits_by_workrate.png).

## EDA
- Both work-rate variables have a strong middle-category concentration, so a three-level model is more appropriate than a binary split.
- The position-work-rate heatmap shows a very strong structural pattern: goalkeepers are entirely concentrated in `Medium`, forwards are relatively concentrated in `High` attacking work rate, and defenders are relatively concentrated in `High` defensive work rate.
- Age, height, and weight differ across work-rate levels, but the clearest visual separation is by position rather than by body size.
- These plots are the most poster-friendly EDA options because they directly answer the study question and keep the visual message focused.

## Main analysis
- I used two multinomial logistic regressions, one for `Attacking Work Rate` and one for `Defensive Work Rate`, because the outcome has three unordered categories and the proportional-odds route was not stable for the position structure in this sample.
- The regressions exclude goalkeepers because their outcomes are perfectly concentrated in `Medium`, which would create separation problems and make the model uninformative.
- Both models include standardized age, height, weight, stamina, aggression, and broad position group as predictors.
- Attacking-work-rate model fit: accuracy `0.637`, null accuracy `0.614`, pseudo-R2 `0.108`, `n = 15,559`.
- Defensive-work-rate model fit: accuracy `0.711`, null accuracy `0.700`, pseudo-R2 `0.153`, `n = 15,559`.
- In the attacking-work-rate model, age is negatively associated with higher categories: `OR = 0.74` for `Medium` vs `Low` per 1 SD increase in age, and `OR = 0.79` for `High` vs `Low`.
- In the attacking-work-rate model, height is negatively associated with higher categories: `OR = 0.62` for `Medium` vs `Low`, and `OR = 0.48` for `High` vs `Low`.
- In the attacking-work-rate model, stamina is positively associated with higher categories, while aggression is negatively associated with higher categories.
- In the defensive-work-rate model, age is negatively associated with higher categories: `OR = 0.63` for `Medium` vs `Low`, and `OR = 0.72` for `High` vs `Low`.
- In the defensive-work-rate model, stamina and aggression are both positively associated with higher categories, with aggression showing the strongest association.
- In both models, midfielders and defenders are much less likely than forwards to be in higher attacking-work-rate categories, and much more likely than forwards to be in higher defensive-work-rate categories.
- The coefficient plots are [`fig_model_attack_coefficients.png`](figs/fig_model_attack_coefficients.png) and [`fig_model_defense_coefficients.png`](figs/fig_model_defense_coefficients.png).

## Diagnostics & robustness
- Collinearity is acceptable: adjusted VIF values are about `1.52` for height, `1.52` for weight, `1.14` for stamina, `1.21` for aggression, and `1.08` for the position block.
- The linear-model diagnostic panel is [`fig_model_lm_diagnostics.png`](figs/fig_model_lm_diagnostics.png).
- The classification/confusion-matrix panel is [`fig_model_diagnostics.png`](figs/fig_model_diagnostics.png).
- In-sample classification is modest rather than strong; the models are more useful for describing structure than for making high-confidence individual predictions.
- The defensive-work-rate model performs slightly better than the attacking-work-rate model on accuracy and pseudo-R2.

## Conclusions
- In this sample, age, stamina, aggression, and broad position are the clearest correlates of work-rate category.
- The strongest qualitative pattern is positional: forwards skew toward higher attacking work rate, while defenders and midfielders skew toward higher defensive work rate.
- Body size matters more weakly than functional traits, with height more relevant for attacking than for defensive work rate.

Limitations: this is a cross-sectional observational dataset, so the results support associations, not causal claims. Reverse causation and unmeasured confounding remain plausible, and the broad position grouping may hide within-role heterogeneity.

## Notes for the team
- The raw filename contains spaces, so all scripts use the full path `data/Work_Rate/FIFA 23 Players.csv` directly.
- Goalkeepers are perfectly concentrated in `Medium` for both work-rate outcomes, so they are described separately and excluded from the regressions.
- The original analysis draft should not be reused as-is because it mixed goalkeepers into the multinomial models; the current scripts and summary reflect the corrected non-goalkeeper regression.
- The best poster shortlist is: one EDA distribution chart, one position-by-work-rate heatmap, one body-trait panel, one coefficient plot for each outcome, and the diagnostic panels.
