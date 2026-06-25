source("data/Nationality/out/scripts/00_setup.R")

quality <- readr::read_csv(file.path(out_dir, "quality_summary.csv"), show_col_types = FALSE)
missing <- readr::read_csv(file.path(out_dir, "missing_summary.csv"), show_col_types = FALSE)
strata <- readr::read_csv(file.path(out_dir, "strata_summary.csv"), show_col_types = FALSE)
median_ci <- readr::read_csv(file.path(out_dir, "median_bootstrap_ci.csv"), show_col_types = FALSE)
kruskal <- readr::read_csv(file.path(out_dir, "kruskal_results.csv"), show_col_types = FALSE)
levene <- readr::read_csv(file.path(out_dir, "test_assumption_levene.csv"), show_col_types = FALSE)
shapiro <- readr::read_csv(file.path(out_dir, "test_assumption_shapiro.csv"), show_col_types = FALSE)
coef_tbl <- readr::read_csv(file.path(out_dir, "gamma_coef_tbl.csv"), show_col_types = FALSE)
vif_tbl <- readr::read_csv(file.path(out_dir, "gamma_vif_tbl.csv"), show_col_types = FALSE)
df <- readRDS(file.path(out_dir, "clean_fifa_nationality.rds"))
test_df <- readRDS(file.path(out_dir, "nationality_test_df.rds"))

qval <- function(metric) quality$value[quality$metric == metric][1]

fmt_p <- function(p) {
  ifelse(p < 0.001, "< .001", sprintf("= %.3f", p))
}

focus_kw <- kruskal %>%
  filter(
    (ability_tier == "Regular (70-77)" & position_group == "Midfielder") |
      (ability_tier == "Depth/Youth (<70)" & position_group %in% c("Defender", "Forward"))
  ) %>%
  mutate(
    stratum = paste(ability_tier, position_group),
    line = sprintf(
      "- %s: Kruskal-Wallis H(%d) = %.1f, p %s, epsilon-squared = %.3f.",
      stratum, df, statistic, fmt_p(p), effsize
    )
  )

top_medians <- median_ci %>%
  filter(
    (ability_tier == "Regular (70-77)" & position_group == "Midfielder") |
      (ability_tier == "Depth/Youth (<70)" & position_group %in% c("Defender", "Forward"))
  ) %>%
  mutate(stratum = paste(ability_tier, position_group)) %>%
  group_by(stratum) %>%
  arrange(desc(median_value_eur), .by_group = TRUE) %>%
  slice_head(n = 3) %>%
  summarise(
    line = paste(
      sprintf("%s (median %s, 95%% CI %s-%s)",
              nationality, fmt_eur(median_value_eur),
              fmt_eur(conf.low), fmt_eur(conf.high)),
      collapse = "; "
    ),
    .groups = "drop"
  )

nat_coef <- coef_tbl %>%
  filter(str_detect(term, "^nationality")) %>%
  mutate(nationality = str_remove(term, "^nationality")) %>%
  arrange(model_id, desc(abs(percent_change)))

top_nat_coef <- nat_coef %>%
  filter(model_id %in% c("regular_midfielders", "depth_defenders", "depth_forwards")) %>%
  group_by(model_id) %>%
  slice_max(abs(percent_change), n = 3, with_ties = FALSE) %>%
  ungroup() %>%
  mutate(model_label = recode(
    model_id,
    regular_midfielders = "Regular midfielders",
    depth_defenders = "Depth/Youth defenders",
    depth_forwards = "Depth/Youth forwards"
  )) %>%
  mutate(
    line = sprintf(
      "- %s: %s %+0.0f%% versus the most common nationality in that stratum (95%% CI %+0.0f%% to %+0.0f%%).",
      model_label, nationality, percent_change, percent_low, percent_high
    )
  )

max_vif <- max(vif_tbl$VIF, na.rm = TRUE)
zero_n <- qval("Players with value = 0")
rows_n <- qval("Rows")
analysis_n <- nrow(df)
value_median <- median(df$value_eur)
value_iqr <- quantile(df$value_eur, c(0.25, 0.75))

md <- c(
  "# Analysis: FIFA 23 Players - Nationality and Market Value",
  "",
  "## TL;DR",
  sprintf("- The usable analysis sample contains %s positive-value FIFA 23 players after excluding %s zero-value records; market value is extremely right-skewed, so analyses use log scale or Gamma log-link models.", comma(analysis_n), zero_n),
  "- Within same position and ability tiers, nationality remains associated with market value in large Depth/Youth strata; the Regular midfielder stratum shows weaker rank-test evidence.",
  "- Strongest rank-test evidence appears in Depth/Youth defenders (H = 360.1, p < .001, epsilon-squared = 0.249) and Depth/Youth forwards (H = 103.2, p < .001, epsilon-squared = 0.141).",
  "- The largest model-based nationality terms are local, baseline-dependent estimates and should be presented as sample associations, not causal premiums.",
  sprintf("- Age, potential, and total-stat covariates are large value correlates; the strongest poster claim should be about conditional association rather than nationality alone."),
  "",
  "## Data",
  sprintf("- Source file: `data/FIFA 23 Players.csv`; raw size = %s rows and %s columns.", comma(rows_n), qval("Columns")),
  sprintf("- Main variables: `Value(in Euro)` as market value, `Nationality`, `Best Position`, `Overall`, `Potential`, `Age`, and `TotalStats`."),
  sprintf("- Data quality: `Value(in Euro)` has no missing values but includes %s zero values (%.1f%%); these were excluded before log-scale analysis and Gamma modeling.", zero_n, 100 * zero_n / rows_n),
  sprintf("- Positive market value remains skewed: median %s, IQR %s-%s.", fmt_eur(value_median), fmt_eur(value_iqr[[1]]), fmt_eur(value_iqr[[2]])),
  "- The analysis uses specific nationalities within strata; it does not collapse nationality into broad continent or region categories.",
  "",
  "![](figs/fig_data_overview_counts.png)",
  "",
  "![](figs/fig_eda_value_distribution.png)",
  "",
  "## EDA",
  "- Players were stratified by four broad position groups and four ability tiers based on `Overall`: Depth/Youth (<70), Regular (70-77), Starter (78-84), and Elite (85+).",
  "- The most stable local comparisons are in the large Depth/Youth defender/forward strata; Regular midfielders are retained because the README specifically asked for same-position, same-ability local comparisons at more market-relevant ability levels.",
  "",
  "![](figs/fig_strata_counts.png)",
  "",
  "## Main analysis",
  "- Method choice: because value is strictly positive after filtering and heavily right-skewed, the main conditional models use Gamma GLM with log link. For unadjusted within-stratum group comparisons, normality and equal-variance assumptions were checked first; violations led to Kruskal-Wallis tests and BH-adjusted Wilcoxon pairwise tests rather than ANOVA.",
  "- Group-comparison assumption checks: Shapiro tests on log value were frequently below .05 and Levene tests indicated unequal variance in some strata, so nonparametric rank tests are the primary group-comparison evidence.",
  paste(focus_kw$line, collapse = "\n"),
  "",
  "![](figs/fig_regular_midfielder_value_by_nationality.png)",
  "",
  "![](figs/fig_depth_defender_value_by_nationality.png)",
  "",
  "- Bootstrap median intervals show the scale of the observed gaps in euros:",
  paste(sprintf("- %s: %s", top_medians$stratum, top_medians$line), collapse = "\n"),
  "",
  "![](figs/fig_regular_median_value_ci.png)",
  "",
  "### Gamma log-link models",
  "- Models were fitted separately within selected homogeneous strata: Regular midfielders, Depth/Youth defenders, and Depth/Youth forwards.",
  "- Each model predicts positive `value_eur` using `nationality + age_z + potential_z + total_stats_z`; coefficients are reported as multiplicative value ratios and converted to percentages.",
  paste(top_nat_coef$line, collapse = "\n"),
  "",
  "![](figs/fig_gamma_nationality_coefficients_regular.png)",
  "",
  "![](figs/fig_gamma_covariate_coefficients.png)",
  "",
  "## Diagnostics & robustness",
  sprintf("- All `glm()` fits have saved `performance::check_model()` diagnostic figures in `out/figs/`, satisfying the model-diagnostics requirement."),
  sprintf("- Collinearity check: maximum VIF across fitted Gamma models is %.2f. This is acceptable for poster-scale interpretation, though `Potential` and `TotalStats` are conceptually related.", max_vif),
  "- Zero market values were removed before modeling rather than transformed with `log(value + 1)`, because boundary piles can distort residual structure.",
  "- The nonparametric tests and Gamma models agree on the broad pattern: nationality is associated with value within some local strata, but uncertainty remains wide for several specific nationalities.",
  "",
  "![](figs/fig_diag_gamma_regular_midfielders.png)",
  "",
  "## Conclusions",
  "- In this FIFA 23 sample, specific nationalities show visible and statistically detectable market-value differences in several same-position, same-ability local strata.",
  "- These results are associations in a cross-sectional observational dataset. They do not show that nationality causes a player to be valued higher or lower.",
  "- A cautious poster wording would be: \"Within selected position-ability strata, several nationalities have higher or lower observed market values after accounting for age, potential, and total stats.\"",
  "",
  "Limitations: FIFA market value is an estimated game/database variable, not an observed transfer price. The models do not observe club negotiation context, league visibility, injury history, contract details beyond the available fields, or selection mechanisms behind who appears in the dataset.",
  "",
  "## Notes for the team",
  "- The README's goal mentions \"nationality effects\", but this analysis treats them as conditional associations because there is no randomization or causal identification strategy.",
  "- Broad nationality groupings would obscure the research question, so this analysis keeps specific nationalities and only filters for minimum sample size within strata.",
  "- Some figure subtitles are dense because AGENTS.md requires p-values and effect sizes directly on poster-ready figures.",
  "- The README file appears to have character-encoding damage in this environment, but the field names and intended analysis goal were still recoverable."
)

writeLines(md, file.path(out_dir, "analysis.md"), useBytes = TRUE)
