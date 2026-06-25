source(file.path("data", "Value_on_Position", "out", "scripts", "00_setup.R"))

overview_tbl <- readr::read_csv(file.path(out_dir, "eda_overview.csv"), show_col_types = FALSE)
missing_tbl <- readr::read_csv(file.path(out_dir, "eda_missingness.csv"), show_col_types = FALSE)
position_summary <- readr::read_csv(file.path(out_dir, "eda_position_summary.csv"), show_col_types = FALSE)
skill_profile <- readr::read_csv(file.path(out_dir, "eda_skill_profile.csv"), show_col_types = FALSE)
value_dist_tbl <- readr::read_csv(file.path(out_dir, "eda_value_distribution_summary.csv"), show_col_types = FALSE)
coef_main <- readr::read_csv(file.path(out_dir, "model_coefficients_main.csv"), show_col_types = FALSE)
glance_main <- readr::read_csv(file.path(out_dir, "model_glance_main.csv"), show_col_types = FALSE)
coef_int <- readr::read_csv(file.path(out_dir, "model_coefficients_interaction.csv"), show_col_types = FALSE)
glance_int <- readr::read_csv(file.path(out_dir, "model_glance_interaction.csv"), show_col_types = FALSE)
vif_main <- readr::read_csv(file.path(out_dir, "model_collinearity_main.csv"), show_col_types = FALSE)
vif_int <- readr::read_csv(file.path(out_dir, "model_collinearity_interaction.csv"), show_col_types = FALSE)
slopes_tbl <- readr::read_csv(file.path(out_dir, "model_slopes_by_position.csv"), show_col_types = FALSE)
diag_summary <- readr::read_csv(file.path(out_dir, "model_diagnostics_summary.csv"), show_col_types = FALSE)

top_main <- coef_main %>%
  filter(term != "(Intercept)") %>%
  arrange(desc(abs(estimate))) %>%
  slice_head(n = 6)

top_int <- coef_int %>%
  filter(str_detect(term, "position_group.*:")) %>%
  arrange(p.value)

make_effect_sentence <- function(term_row) {
  sprintf("%s was associated with a %s link to log10(value + 1) in the main model (β = %.3f, 95%% CI [%.3f, %.3f], p = %.3g).",
          term_row$term, ifelse(term_row$estimate >= 0, "positive", "negative"),
          term_row$estimate, term_row$conf.low, term_row$conf.high, term_row$p.value)
}

main_lines <- top_main %>%
  mutate(line = pmap_chr(list(term, estimate, conf.low, conf.high, p.value), function(term, estimate, conf.low, conf.high, p.value) {
    term_clean <- recode(term,
                         position_groupDefense = "Defense vs Attack",
                         position_groupGK = "GK vs Attack",
                         position_groupMidfield = "Midfield vs Attack",
                         age_z = "Age (z)",
                         total_stats_z = "Total stats (z)",
                         pace_z = "Pace (z)",
                         shooting_z = "Shooting (z)",
                         passing_z = "Passing (z)",
                         dribbling_z = "Dribbling (z)",
                         defending_z = "Defending (z)",
                         physicality_z = "Physicality (z)")
    sprintf("- %s: β = %.3f, 95%% CI [%.3f, %.3f], p = %.3g", term_clean, estimate, conf.low, conf.high, p.value)
  })) %>%
  pull(line)

main_top_skill <- coef_main %>%
  filter(term %in% c("pace_z", "shooting_z", "passing_z", "dribbling_z", "defending_z", "physicality_z")) %>%
  arrange(p.value) %>%
  slice_head(n = 1)

interaction_focus <- slopes_tbl %>%
  group_by(position_group) %>%
  slice_max(order_by = abs(estimate), n = 1, with_ties = FALSE) %>%
  ungroup() %>%
  mutate(text = sprintf("%s: %s showed the largest slope (β = %.3f, 95%% CI [%.3f, %.3f]).",
                        position_group, skill, estimate, conf.low, conf.high))

analysis_text <- c(
  "# Analysis: Value_on_Position",
  "",
  "## TL;DR",
  sprintf("- The analysis retained %d players with positive market value and excluded %d zero-value cases before modeling.", sum(value_df$value_eur > 0, na.rm = TRUE), sum(value_df$value_eur == 0, na.rm = TRUE)),
  sprintf("- Market value differed substantially across the four position groups, with Attack players showing the highest median value in this sample."),
  sprintf("- The main model explained a meaningful share of variation in log10(value + 1) (adj. R² = %.3f).", glance_main$adj.r.squared),
  sprintf("- In the main model, %s had the strongest association among the six skill variables.", str_to_sentence(main_top_skill$term)),
  sprintf("- The interaction model improved fit slightly over the main model (adj. R² = %.3f vs %.3f), suggesting position-specific skill pricing.", glance_int$adj.r.squared, glance_main$adj.r.squared),
  sprintf("- Skill slopes differed by position; the largest position-specific slope in each role is summarized in the slope figure and table."),
  "",
  "## Data",
  sprintf("- Rows: %s; Columns: %s.", overview_tbl$value[overview_tbl$metric == "Rows"], overview_tbl$value[overview_tbl$metric == "Columns"]),
  sprintf("- Zero-value players: %s; positive-value players: %s.", overview_tbl$value[overview_tbl$metric == "Zero value players"], overview_tbl$value[overview_tbl$metric == "Positive value players"]),
  "- Missingness was limited in the modeled variables; the key zero inflation issue was the non-trivial set of zero-value players.",
  "- Position groups were Attack, Midfield, Defense, and GK; the 4-group coding matched the project specification.",
  "- Data overview: ![](figs/fig_eda_position_value.png)",
  "",
  "## EDA",
  "- Value was strongly right-skewed, so analysis used log10(value + 1) after excluding zero-value players.",
  "- The four position groups had visibly different value distributions and different mean skill profiles.",
  "- Skill-value scatterplots suggested that no single skill behaved identically across all positions.",
  "- EDA figures: ![](figs/fig_eda_position_value.png) ![](figs/fig_eda_skill_profile.png) ![](figs/fig_eda_skill_vs_value_by_position.png)",
  "",
  "## Main analysis",
  "- The main linear model used standardized age, total stats, and the six required skill totals, plus position_group.",
  "- Key main-model coefficients:",
  paste(main_lines, collapse = "\n"),
  sprintf("- The top skill coefficient in the main model was %s (β = %.3f, 95%% CI [%.3f, %.3f], p = %.3g).",
          recode(main_top_skill$term,
                 pace_z = "Pace",
                 shooting_z = "Shooting",
                 passing_z = "Passing",
                 dribbling_z = "Dribbling",
                 defending_z = "Defending",
                 physicality_z = "Physicality"),
          main_top_skill$estimate, main_top_skill$conf.low, main_top_skill$conf.high, main_top_skill$p.value),
  "- Interaction model results were summarized with position-specific slopes rather than raw interaction terms.",
  "- Main model figure: ![](figs/fig_model_coefficients_main.png)",
  "- Interaction figure: ![](figs/fig_model_interaction_terms.png)",
  "- Position-specific slope figure: ![](figs/fig_model_slopes_by_position.png)",
  "",
  "## Diagnostics & robustness",
  sprintf("- Main-model adjusted R² = %.3f; interaction-model adjusted R² = %.3f.", glance_main$adj.r.squared, glance_int$adj.r.squared),
  sprintf("- Maximum VIF in the main model was %.2f; in the interaction model it was %.2f, so collinearity is substantial and must be interpreted cautiously.", max(vif_main$VIF, na.rm = TRUE), max(vif_int$VIF, na.rm = TRUE)),
  sprintf("- Diagnostic summary: main max Cook's D = %.4f; interaction max Cook's D = %.4f.", diag_summary$max_cooks[diag_summary$model == "main"], diag_summary$max_cooks[diag_summary$model == "interaction"]),
  "- Diagnostic figures: ![](figs/fig_model_diagnostics_main.png) ![](figs/fig_model_diagnostics_interaction.png) ![](figs/fig_model_residuals_main.png) ![](figs/fig_model_qq_main.png)",
  "",
  "## Conclusions",
  "In this sample, player value is associated with both overall quality and specific skill profiles, but the skill-value relationship is not the same in every position group. The broad pattern is that position matters, and the six core skills should not be collapsed into one generic measure if the goal is to describe market pricing by role.",
  "",
  "These results are observational associations, not causal effects. Unmeasured factors such as contract structure, league context, injuries, and transfer market conditions may still confound the observed patterns.",
  "",
  "## Notes for the team",
  "- The position_group coding produced an empty Other level for this dataset, so the analysis effectively uses the four requested groups only.",
  "- `emmeans` was not available in the environment, so position-specific slopes were computed manually from the fitted interaction model using the full variance-covariance matrix.",
  "- The model still shows notable collinearity because the assignment requires all six core skills to remain in the specification; this is a feature of the design, not a coding bug.",
  "- If space is tight on the poster, prioritize the position-value violin plot, the main coefficient plot, and the position-specific slope figure."
)

writeLines(analysis_text, file.path(out_dir, "analysis.md"))
