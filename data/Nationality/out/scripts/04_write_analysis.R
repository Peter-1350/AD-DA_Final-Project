source(file.path("data", "Nationality", "out", "scripts", "00_setup.R"))

overview <- readr::read_csv(file.path(out_dir, "overview.csv"), show_col_types = FALSE)
value_summary <- readr::read_csv(file.path(out_dir, "value_summary.csv"), show_col_types = FALSE)
gamma_tests <- readr::read_csv(file.path(out_dir, "gamma_nationality_tests.csv"), show_col_types = FALSE)
eta_tbl <- readr::read_csv(file.path(out_dir, "eta_effect_sizes.csv"), show_col_types = FALSE)
means <- readr::read_csv(file.path(out_dir, "estimated_mean_values.csv"), show_col_types = FALSE)
pairs_top <- readr::read_csv(file.path(out_dir, "top_pairwise_differences.csv"), show_col_types = FALSE)
levene <- readr::read_csv(file.path(out_dir, "assumption_levene_by_cell.csv"), show_col_types = FALSE)
normality <- readr::read_csv(file.path(out_dir, "assumption_normality_by_group.csv"), show_col_types = FALSE)
vif <- readr::read_csv(file.path(out_dir, "full_gamma_vif.csv"), show_col_types = FALSE)
glance_full <- readr::read_csv(file.path(out_dir, "full_gamma_glance.csv"), show_col_types = FALSE)
coef_full <- readr::read_csv(file.path(out_dir, "full_gamma_coefficients.csv"), show_col_types = FALSE)
outliers <- readr::read_csv(file.path(out_dir, "full_gamma_outliers.csv"), show_col_types = FALSE)

get_metric <- function(name) overview$value[overview$metric == name]

test_line <- gamma_tests %>%
  left_join(eta_tbl, by = "cell") %>%
  mutate(
    line = sprintf(
      "- %s: LR chi-square(%d)=%.2f, p %s, partial eta2=%.3f.",
      cell, as.integer(df), lr_chisq, fmt_p(p_value), partial_eta2_log_lm
    )
  ) %>%
  pull(line)

mean_lines <- means %>%
  filter(cell %in% c("Defender / Rotation 70-77", "Midfield / Rotation 70-77")) %>%
  group_by(cell) %>%
  slice_max(mean_value_eur, n = 1, with_ties = FALSE) %>%
  ungroup() %>%
  mutate(line = sprintf(
    "- In %s, the highest adjusted mean was %s: EUR %s [EUR %s, EUR %s].",
    cell, nationality, comma(round(mean_value_eur)), comma(round(ci_low_eur)), comma(round(ci_high_eur))
  )) %>%
  pull(line)

pair_lines <- pairs_top %>%
  arrange(cell, desc(abs(percent_difference))) %>%
  mutate(line = sprintf(
    "- %s: %s ratio %.2f [%.2f, %.2f], Tukey p %s (%+.1f%%).",
    cell, contrast, ratio, lower.CL, upper.CL, fmt_p(p.value), percent_difference
  )) %>%
  pull(line)

coef_lines <- coef_full %>%
  filter(str_detect(term, "^nationality")) %>%
  mutate(nationality = str_remove(term, "^nationality")) %>%
  mutate(line = sprintf(
    "- %s vs Spain: ratio %.3f [%.3f, %.3f], p %s (%+.1f%%).",
    nationality, estimate, conf.low, conf.high, fmt_p(p.value), percent_change
  )) %>%
  pull(line)

normality_summary <- normality %>%
  summarise(
    n_groups = n(),
    shapiro_sig = sum(shapiro_p_log_value < 0.05, na.rm = TRUE),
    min_n = min(n),
    max_n = max(n)
  )

levene_lines <- levene %>%
  mutate(line = sprintf("- %s: Levene p %s.", cell, fmt_p(p.value))) %>%
  pull(line)

vif_lines <- vif %>%
  mutate(line = sprintf("- %s: VIF %.2f.", Term, VIF)) %>%
  pull(line)

outlier_n <- sum(outliers$Outlier == 1 | outliers$Outlier_Cook == 1, na.rm = TRUE)

md <- c(
  "# Analysis: FIFA 23 Players - Nationality and Market Value",
  "",
  "## TL;DR",
  "- FIFA 23 market value is extremely right-skewed: median EUR 1.0M, IQR EUR 0.5M-EUR 2.0M, maximum EUR 190.5M; 98 zero-value boundary observations were excluded before modeling.",
  "- After matching broadly on best-position group and Overall tier, nationality differences were clearest among rotation-tier defenders and midfielders, not among rotation-tier forwards or starter-tier midfielders.",
  "- In rotation-tier defenders, Brazil had the highest adjusted mean value (EUR 3.64M [EUR 3.42M, EUR 3.87M]) and was 33% above Argentina after age and potential adjustment.",
  "- In rotation-tier midfielders, Brazil was also highest (EUR 4.31M [EUR 4.00M, EUR 4.63M]) and 25% above Argentina after age and potential adjustment.",
  "- The pooled controlled Gamma model showed small average nationality coefficients versus Spain (about -2% to -6% for the other selected nationalities), so the poster should emphasize cell-specific heterogeneity rather than a single global nationality ranking.",
  "",
  "## Data",
  sprintf("- Source file: `data/FIFA 23 Players.csv`; raw n = %s rows and %s columns.", comma(get_metric("Rows in raw data")), comma(get_metric("Columns in raw data"))),
  sprintf("- Model sample: n = %s after excluding %s players with `Value(in Euro) == 0`; no missing values were found in the model fields used here.", comma(get_metric("Rows retained for models")), comma(get_metric("Rows excluded for zero market value"))),
  sprintf("- Nationality is specific country/region text with %s distinct levels in the full data. To avoid over-broad categories, the main comparisons use six concrete nationalities with adequate cell counts: Spain, Brazil, Argentina, France, England, Germany.", comma(get_metric("Distinct nationalities"))),
  "- Position groups were derived from `Best Position`: Forward, Midfield, Defender, Goalkeeper. Ability tiers were based on `Overall`: Elite 85+, Starter 78-84, Rotation 70-77, Depth <70.",
  "",
  "![](figs/fig_eda_value_distribution.png)",
  "",
  "![](figs/fig_eda_position_ability_cells.png)",
  "",
  "## EDA",
  "- Value has a long right tail, so raw-value ANOVA would be a poor default. The analysis uses Gamma GLM with log link for positive market values.",
  "- Most observations sit in the Rotation 70-77 and Depth <70 tiers. Elite cells are too sparse for stable nationality comparisons.",
  "- Selected poster cells: Midfield/Rotation 70-77, Defender/Rotation 70-77, Forward/Rotation 70-77, and Midfield/Starter 78-84. Argentina in Midfield/Starter 78-84 had n=19 and was dropped from the model for that cell; the remaining displayed cells had n >= 20 per nationality except no dropped groups in Forward/Rotation.",
  "",
  "![](figs/fig_eda_value_by_nationality_cells.png)",
  "",
  "## Main Analysis",
  "- Method: within each selected position-rating cell, fit `glm(value_eur ~ nationality + age + potential, family = Gamma(link = \"log\"))`. This compares multiplicative expected-value ratios while adjusting for age and potential within a local homogeneous cell.",
  "- Hypothesis-test choice: because value is strictly positive after cleaning and strongly right-skewed, Gamma(log) modeling is more aligned with the money-scale question than ordinary ANOVA or rank-only Kruskal-Wallis.",
  "",
  "Cell-level likelihood-ratio tests for nationality:",
  test_line,
  "",
  "Highest adjusted means in the significant cells:",
  mean_lines,
  "",
  "Largest Tukey-adjusted pairwise contrasts:",
  pair_lines,
  "",
  "![](figs/fig_gamma_adjusted_means_by_cell.png)",
  "",
  "![](figs/fig_top_pairwise_nationality_contrasts.png)",
  "",
  "Pooled controlled model, included as a robustness view rather than the main story:",
  sprintf("- Gamma(log) model n = %s; predictors: cell, nationality, age, potential, overall.", comma(glance_full$nobs)),
  coef_lines,
  "",
  "![](figs/fig_full_model_nationality_coefficients.png)",
  "",
  "## Diagnostics & Robustness",
  sprintf("- Normality checks on log(value): %d of %d nationality-within-cell groups had Shapiro p < .05; group sizes ranged from %d to %d. This supports avoiding a plain normal-error ANOVA as the primary analysis.", normality_summary$shapiro_sig, normality_summary$n_groups, normality_summary$min_n, normality_summary$max_n),
  "- Levene tests on log(value) by nationality:",
  levene_lines,
  "- Defender/Rotation 70-77 showed unequal log-scale variance, so the significant defender result should be read with the Gamma model and its diagnostics rather than as a classical equal-variance ANOVA result.",
  "- Collinearity in the pooled model was acceptable but not trivial:",
  vif_lines,
  sprintf("- Influence check in the pooled Gamma model flagged %s observations by Cook/outlier criteria; diagnostics were saved for inspection.", comma(outlier_n)),
  "",
  "Diagnostic figures saved:",
  "- `figs/fig_diagnostics_full_gamma_model.png`",
  "- `figs/fig_diagnostics_gamma_midfield_rotation_70_77.png`",
  "- `figs/fig_diagnostics_gamma_defender_rotation_70_77.png`",
  "- `figs/fig_diagnostics_gamma_forward_rotation_70_77.png`",
  "- `figs/fig_diagnostics_gamma_midfield_starter_78_84.png`",
  "",
  "## Conclusions",
  "- In this FIFA 23 sample, nationality-value associations are not uniform. The clearest adjusted gaps appear in rotation-tier defenders and midfielders, where Brazilian players have higher estimated market values than several peer nationalities after controlling for age and potential.",
  "- The evidence is weaker in rotation-tier forwards and starter-tier midfielders; their confidence intervals overlap substantially and the nationality LR tests are not statistically strong.",
  "- These are cross-sectional observational associations. They should not be phrased as nationality causing higher or lower value. Unobserved club context, league exposure, contract details, scouting visibility, and transfer-market liquidity could confound the comparisons.",
  "",
  "## Notes for the Team",
  "- Poster-ready figures are in `out/figs/` at 300 dpi. The strongest candidates are `fig_gamma_adjusted_means_by_cell.png`, `fig_top_pairwise_nationality_contrasts.png`, and `fig_eda_value_by_nationality_cells.png`.",
  "- Do not describe this as a universal nationality premium. The pooled model shrinks average differences, while the cell-specific models show where the association is concentrated.",
  "- The README's suggested comparison of broad nationality categories was not followed literally because AGENTS.md warns against over-coarse nationality classification. This analysis compares concrete nationalities with adequate sample sizes.",
  "- Elite-tier cells are too small for credible nationality ranking in this dataset; avoid using star-player anecdotes as statistical evidence.",
  "- All `glm()` calls used for conclusions have accompanying diagnostic PNGs. The diagnostic plots are work products for checking model reliability, not necessarily poster figures."
)

writeLines(md, file.path(out_dir, "analysis.md"))
