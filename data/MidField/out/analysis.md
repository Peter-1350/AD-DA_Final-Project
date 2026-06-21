# Analysis: MidField

## TL;DR
- Raw market value differs by position, with midfielders sitting below attackers in the unadjusted comparison.
- Midfielders show a distinctive skill profile: relatively high passing and dribbling, but not the same attacking ceiling as forwards.
- The midfielder coefficient shrinks steadily as total ability, skill structure, age, and reputation are added to the model.
- This suggests that part of the raw midfield gap is explained by observed player characteristics rather than the position label alone.
- This is observational data, so the results support association, not causation.

## Data
- The dataset contains 17,524 players and 89 columns, with no missing values in the key variables used here.
- `Best Position` is concentrated in CB, ST, CAM, GK, RM, CDM, and CM, so midfield is a large and heterogeneous group.
- Market value is right-skewed and includes 98 zero values, so the models use `log10(value + 1)`.
- The analysis target in `data/MidField/README.md` matches the FIFA 23 player file and focuses on why the midfield coefficient turns negative in the earlier model.
- Reference figure: `![](figs/fig_eda_position_share.png)`

## EDA
- Midfielders are not the highest-value group in the raw data; attackers are higher, while defenders and goalkeepers occupy different parts of the distribution.
- Passing and dribbling are the clearest strengths of midfielders relative to the other broad position groups.
- Midfielders are slightly older on median, and their median international reputation is not obviously higher than attackers.
- Reference figures: `![](figs/fig_eda_value_by_position.png)`, `![](figs/fig_eda_skill_profile.png)`, and `![](figs/fig_eda_age_overall_reputation.png)`

## Main analysis
- I used the same positive-value sample across all models and fit a progressive adjustment sequence on `log10(value + 1)`.
- Model 1 included only position group; Models 2 to 4 added total stats, skill structure, age, and international reputation.
- The midpoint result is the coefficient path for `position_groupMidfield`, which is saved in `out/midfield_coef_path.csv`.
- Reference figures: `![](figs/fig_model_midfield_path.png)` and `![](figs/fig_model_predicted_position_values.png)`

## Diagnostics & robustness
- Because `performance::check_model()` was blocked by a missing `see` dependency in this environment, I used a manual four-panel diagnostic figure for the richest model.
- I also checked collinearity for Model 4 and saved the summary to `out/model_collinearity_m4.csv`.
- The log transform makes the residual structure much more manageable than the raw value scale.
- Reference figures: `![](figs/fig_model_diagnostics_main.png)`

## Conclusions
- In the raw comparison, midfielders sit below attackers in market value.
- Once total ability and skill structure are controlled for, the midfielder gap becomes smaller, which means the position coefficient is partly picking up observable player characteristics.
- Age and international reputation add further explanation, but the analysis still remains observational and cannot identify a causal effect of being a midfielder.

Limitations: the midfielder group is broad and internally heterogeneous, so a single position coefficient compresses several distinct player archetypes into one label.

## Notes for the team
- The cleanest poster figures are likely `fig_eda_skill_profile.png`, `fig_model_midfield_path.png`, and `fig_model_predicted_position_values.png`.
- If you want a tighter story, we can turn the coefficient path into a single annotated slope chart and drop one of the descriptive panels.

