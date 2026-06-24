library(tidyverse)
library(glue)
library(scales)

root_dir <- normalizePath(file.path(getwd()), winslash = "/", mustWork = TRUE)
out_dir <- file.path(root_dir, "data", "Nationality", "out")

quality <- readr::read_csv(file.path(out_dir, "quality_summary.csv"), show_col_types = FALSE)
kruskal <- readr::read_csv(file.path(out_dir, "kruskal_results.csv"), show_col_types = FALSE)
groups <- readr::read_csv(file.path(out_dir, "nationality_group_summary.csv"), show_col_types = FALSE)
coef <- readr::read_csv(file.path(out_dir, "gamma_coef_tbl.csv"), show_col_types = FALSE)
glance <- readr::read_csv(file.path(out_dir, "gamma_glance_tbl.csv"), show_col_types = FALSE)
vif <- readr::read_csv(file.path(out_dir, "gamma_vif_tbl.csv"), show_col_types = FALSE)
levene <- readr::read_csv(file.path(out_dir, "test_assumption_levene.csv"), show_col_types = FALSE)

fmt_p <- function(p) {
  case_when(
    is.na(p) ~ "NA",
    p < 0.001 ~ "< .001",
    TRUE ~ paste0("= ", number(p, accuracy = 0.001))
  )
}

fmt_pct_ci <- function(x, lo, hi) {
  glue("{number(x, accuracy = 0.1)}% [95% CI {number(lo, accuracy = 0.1)}%, {number(hi, accuracy = 0.1)}%]")
}

kr <- function(stratum) kruskal %>% filter(stratum_label == stratum) %>% slice(1)
lev <- function(stratum) levene %>% filter(stratum_label == stratum) %>% slice(1)

top_line <- function(stratum) {
  groups %>%
    filter(stratum_label == stratum) %>%
    arrange(desc(median_value_m)) %>%
    slice(1) %>%
    transmute(txt = glue("{nationality}: median EUR {number(median_value_m, accuracy = 0.01)}M (n={n})")) %>%
    pull(txt)
}

coef_line <- function(stratum, term_clean) {
  row <- coef %>%
    filter(stratum_label == stratum, term_clean == !!term_clean) %>%
    slice(1)
  fmt_pct_ci(row$percent_diff, row$percent_low, row$percent_high)
}

max_vif <- vif %>%
  group_by(stratum_label) %>%
  slice_max(VIF, n = 1, with_ties = FALSE) %>%
  ungroup()

analysis <- glue(
"# Analysis: FIFA 23 Nationality and Player Value

## TL;DR
- After excluding 98 zero-value players, the analysis sample contains {comma(quality$analysis_n)} FIFA 23 players from {quality$nationality_n} nationalities.
- Market value is extremely right-skewed, so all value comparisons use log scale, medians, nonparametric tests, or Gamma GLM with a log link.
- Among regular midfielders, nationality differences are weak: Kruskal-Wallis p {fmt_p(kr('Regular midfielders')$p.value)}, epsilon2 = {number(kr('Regular midfielders')$epsilon2, accuracy = 0.001)}.
- Among regular defenders, nationality differences are statistically clearer but still small: p {fmt_p(kr('Regular defenders')$p.value)}, epsilon2 = {number(kr('Regular defenders')$epsilon2, accuracy = 0.001)}.
- Development midfielders show much larger observed gaps by specific nationality: p {fmt_p(kr('Development midfielders')$p.value)}, epsilon2 = {number(kr('Development midfielders')$epsilon2, accuracy = 0.001)}.
- In Gamma models controlling age, overall, and potential, nationality coefficients are mostly modest; ability and potential remain stronger value predictors than nationality labels.

## Data
- Source file: `data/FIFA 23 Players.csv`, described in `data/FIFA/README.md`.
- Raw data: n = {comma(quality$raw_n)}, columns = {quality$raw_cols}. Analysis data: n = {comma(quality$analysis_n)} after removing players with `Value(in Euro) <= 0`.
- There were no missing market values and no duplicated `Full Name` entries in this file. The main quality issue was the 98 zero-value rows, which cannot be used in log-value or Gamma value models.
- Position was collapsed only into four football role groups: Forward, Midfielder, Defender, Goalkeeper. Nationality was not collapsed into broad regions; specific nationalities were compared only when a stratum had enough observations.

![](figs/fig_data_overview_counts.png)

![](figs/fig_eda_value_distribution.png)

## EDA
- Value has a long right tail. The median value in the analysis sample is EUR {number(median(readRDS(file.path(out_dir, 'clean_fifa_nationality.rds'))$value_m), accuracy = 0.01)}M, far below the maximum superstar values.
- The most poster-useful homogeneous regular-tier groups were regular midfielders and regular defenders. They have enough observations across multiple specific nationalities while avoiding an over-broad all-player comparison.
- In raw medians, the highest regular-midfielder nationality in the selected set was {top_line('Regular midfielders')}; the highest regular-defender nationality was {top_line('Regular defenders')}. These are descriptive comparisons, not adjusted effects.

![](figs/fig_regular_midfielder_value_by_nationality.png)

![](figs/fig_regular_defender_value_by_nationality.png)

## Main Analysis
- Because log market value was not consistently normal within nationality groups, and Levene tests showed unequal variances for regular defenders and development midfielders, the group comparison uses Kruskal-Wallis tests instead of ANOVA.
- Regular midfielders: H({kr('Regular midfielders')$df}) = {number(kr('Regular midfielders')$statistic, accuracy = 0.1)}, p {fmt_p(kr('Regular midfielders')$p.value)}, epsilon2 = {number(kr('Regular midfielders')$epsilon2, accuracy = 0.001)}. This is a very small observed nationality association in this stratum.
- Regular defenders: H({kr('Regular defenders')$df}) = {number(kr('Regular defenders')$statistic, accuracy = 0.1)}, p {fmt_p(kr('Regular defenders')$p.value)}, epsilon2 = {number(kr('Regular defenders')$epsilon2, accuracy = 0.001)}. The pattern is statistically clearer, but the effect size is still small.
- Development midfielders: H({kr('Development midfielders')$df}) = {number(kr('Development midfielders')$statistic, accuracy = 0.1)}, p {fmt_p(kr('Development midfielders')$p.value)}, epsilon2 = {number(kr('Development midfielders')$epsilon2, accuracy = 0.001)}. In this lower tier, specific nationality differences are much larger.

![](figs/fig_regular_median_value_ci.png)

## Regression Results
- I fitted Gamma GLMs with log link within each selected stratum: `value_eur ~ nationality + overall + potential + age`.
- For regular midfielders, the model baseline nationality was Spain (largest group in the selected stratum). Brazil was estimated at {coef_line('Regular midfielders', 'Brazil')} relative to Spain after controls; most other nationality CIs overlapped zero percent difference.
- For regular defenders, the model baseline nationality was Brazil. Spain was estimated at {coef_line('Regular defenders', 'Spain')} and England at {coef_line('Regular defenders', 'England')} relative to Brazil after controls.
- These regression coefficients are adjusted associations in this sample. They should not be written as causal nationality effects.

![](figs/fig_gamma_nationality_coefficients_regular.png)

![](figs/fig_gamma_covariate_coefficients.png)

## Diagnostics & Robustness
- Required assumption checks were run before group testing. Levene p-values were: regular midfielders {fmt_p(lev('Regular midfielders')$p.value)}, regular defenders {fmt_p(lev('Regular defenders')$p.value)}, development midfielders {fmt_p(lev('Development midfielders')$p.value)}. This supports using nonparametric tests for the unequal-variance strata.
- Every `glm()` produced a `performance::check_model()` diagnostic figure:
  - `figs/fig_diag_gamma_regular_midfielders.png`
  - `figs/fig_diag_gamma_regular_defenders.png`
  - `figs/fig_diag_gamma_development_midfielders.png`
- Collinearity was acceptable but not zero. The highest VIFs were {number(max_vif$VIF[1], accuracy = 0.01)} for regular midfielders, {number(max_vif$VIF[2], accuracy = 0.01)} for regular defenders, and {number(max_vif$VIF[3], accuracy = 0.01)} for development midfielders, all on `potential_c`.
- Robustness note: development midfielders show much stronger nationality gaps than regular-tier players, so poster claims should specify the stratum. A single all-player statement would hide this heterogeneity.

## Conclusions
- In this FIFA 23 sample, specific nationality is associated with player market value within some position-rating strata, but the size of the association depends strongly on the stratum.
- For regular-tier players, nationality gaps are small compared with ability and potential variables. Defender comparisons show clearer differences than midfielder comparisons.
- The clearest poster finding is not that nationality universally predicts value; it is that observed nationality gaps are concentrated in some strata, especially development midfielders, while regular-tier gaps are modest.

Limitations: This is cross-sectional observational data. The analysis reports associations, not causal effects. Unobserved variables such as league, contract context, club bargaining power, injury history, and scouting visibility may partly explain the observed nationality patterns.

## Notes for the Team
- I followed the project rule against over-coarse nationality grouping: the analysis compares specific nationalities and uses an n >= 30 threshold within each stratum.
- The README suggests ANOVA as a possible route, but assumption checks did not support plain ANOVA for all target strata; I used Kruskal-Wallis tests and Gamma log-link GLMs instead.
- Figure captions and titles avoid causal language. For the poster, use wording like \"is associated with\" or \"observed gap\", not \"nationality causes value differences\".
- The strongest Development-midfielder pattern may be partly a league/club-market artifact. Treat it as a hypothesis-generating descriptive result unless more controls are added.
")

writeLines(analysis, file.path(out_dir, "analysis.md"), useBytes = TRUE)
cat("analysis.md written\n")
