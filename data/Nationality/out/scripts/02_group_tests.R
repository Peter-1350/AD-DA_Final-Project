library(tidyverse)
library(broom)
library(car)
library(rstatix)
library(scales)
library(viridis)
library(glue)

root_dir <- normalizePath(file.path(getwd()), winslash = "/", mustWork = TRUE)
out_dir <- file.path(root_dir, "data", "Nationality", "out")
fig_dir <- file.path(out_dir, "figs")
dir.create(fig_dir, recursive = TRUE, showWarnings = FALSE)

save_poster_fig <- function(plot, filename, width = 8, height = 6) {
  title <- plot$labels$title %||% ""
  subtitle <- plot$labels$subtitle %||% ""
  if (nchar(title) > 70) warning("Long title: ", title)
  if (nchar(subtitle) > 120) warning("Long subtitle: ", subtitle)
  ggsave(file.path(fig_dir, filename), plot, width = width, height = height, dpi = 300)
}

fmt_p <- function(p) {
  case_when(
    is.na(p) ~ "NA",
    p < 0.001 ~ "< .001",
    TRUE ~ paste0("= ", number(p, accuracy = 0.001))
  )
}

clean_df <- readRDS(file.path(out_dir, "clean_fifa_nationality.rds"))

selected_strata <- tribble(
  ~position_group, ~ability_tier, ~stratum_label, ~role,
  "Midfielder", "Regular (70-77)", "Regular midfielders", "main",
  "Defender", "Regular (70-77)", "Regular defenders", "main",
  "Midfielder", "Development (<70)", "Development midfielders", "robustness"
)

analysis_groups <- pmap_dfr(selected_strata, function(position_group, ability_tier, stratum_label, role) {
    pos <- position_group
    tier <- ability_tier
    clean_df %>%
      filter(.data$position_group == pos, .data$ability_tier == tier) %>%
      count(nationality, name = "n") %>%
      filter(n >= 30) %>%
      arrange(desc(n), nationality) %>%
      slice_head(n = 8) %>%
      mutate(
        position_group = pos,
        ability_tier = tier,
        stratum_label = stratum_label,
        role = role
      )
  })

test_df <- clean_df %>%
  inner_join(
    analysis_groups %>%
      select(position_group, ability_tier, nationality, stratum_label, role),
    by = c("position_group", "ability_tier", "nationality")
  ) %>%
  mutate(stratum_label = factor(stratum_label, levels = selected_strata$stratum_label))

group_summary <- test_df %>%
  group_by(stratum_label, role, position_group, ability_tier, nationality) %>%
  summarise(
    n = n(),
    median_value_m = median(value_m),
    mean_value_m = mean(value_m),
    q1_value_m = quantile(value_m, 0.25),
    q3_value_m = quantile(value_m, 0.75),
    median_age = median(age),
    median_potential = median(potential),
    .groups = "drop"
  ) %>%
  arrange(stratum_label, desc(median_value_m))

assumption_checks <- test_df %>%
  group_by(stratum_label, nationality) %>%
  summarise(
    n = n(),
    shapiro_p_log_value = {
      x <- log_value[is.finite(log_value)]
      if (length(x) >= 3 && length(x) <= 5000 && n_distinct(x) >= 3) {
        shapiro.test(x)$p.value
      } else {
        NA_real_
      }
    },
    .groups = "drop"
  )

levene_checks <- test_df %>%
  group_by(stratum_label) %>%
  group_modify(~ {
    lev <- car::leveneTest(log_value ~ nationality, data = .x)
    broom::tidy(lev) %>% slice(1)
  }) %>%
  ungroup() %>%
  select(stratum_label, statistic, p.value)

kruskal_results <- test_df %>%
  group_by(stratum_label) %>%
  group_modify(~ {
    kt <- kruskal.test(log_value ~ nationality, data = .x)
    eff <- rstatix::kruskal_effsize(.x, log_value ~ nationality, ci = TRUE)
    tibble(
      statistic = unname(kt$statistic),
      df = unname(kt$parameter),
      p.value = kt$p.value,
      epsilon2 = eff$effsize,
      epsilon2_ci_low = eff$conf.low,
      epsilon2_ci_high = eff$conf.high
    )
  }) %>%
  ungroup()

pairwise_results <- test_df %>%
  group_by(stratum_label) %>%
  group_modify(~ {
    pairwise.wilcox.test(.x$log_value, .x$nationality, p.adjust.method = "BH") %>%
      broom::tidy()
  }) %>%
  ungroup() %>%
  arrange(stratum_label, p.value)

boot_ci <- function(x, reps = 1000) {
  med <- replicate(reps, median(sample(x, replace = TRUE)))
  quantile(med, probs = c(0.025, 0.975), na.rm = TRUE)
}

median_ci <- test_df %>%
  group_by(stratum_label, role, nationality) %>%
  summarise(
    n = n(),
    median_value_m = median(value_m),
    ci = list(boot_ci(value_m)),
    .groups = "drop"
  ) %>%
  mutate(
    ci_low = map_dbl(ci, 1),
    ci_high = map_dbl(ci, 2)
  ) %>%
  select(-ci)

readr::write_csv(analysis_groups, file.path(out_dir, "analysis_groups.csv"))
readr::write_csv(group_summary, file.path(out_dir, "nationality_group_summary.csv"))
readr::write_csv(assumption_checks, file.path(out_dir, "test_assumption_shapiro.csv"))
readr::write_csv(levene_checks, file.path(out_dir, "test_assumption_levene.csv"))
readr::write_csv(kruskal_results, file.path(out_dir, "kruskal_results.csv"))
readr::write_csv(pairwise_results, file.path(out_dir, "pairwise_wilcox_results.csv"))
readr::write_csv(median_ci, file.path(out_dir, "median_bootstrap_ci.csv"))
saveRDS(test_df, file.path(out_dir, "nationality_test_df.rds"))

plot_stratum <- function(stratum, filename, title) {
  df <- test_df %>% filter(stratum_label == stratum)
  stat <- kruskal_results %>% filter(stratum_label == stratum)
  order_tbl <- df %>%
    group_by(nationality) %>%
    summarise(median_value_m = median(value_m), .groups = "drop") %>%
    arrange(median_value_m)
  plot_df <- df %>%
    mutate(nationality = factor(nationality, levels = order_tbl$nationality))
  subtitle <- glue(
    "Kruskal-Wallis H({stat$df}) = {number(stat$statistic, accuracy = 0.1)}, p {fmt_p(stat$p.value)}, epsilon2 = {number(stat$epsilon2, accuracy = 0.001)}"
  )

  p <- ggplot(plot_df, aes(x = nationality, y = value_eur, fill = nationality)) +
    geom_violin(alpha = 0.55, trim = FALSE, color = NA) +
    geom_boxplot(width = 0.16, outlier.alpha = 0.25, fill = "white", color = "grey25") +
    stat_summary(fun = median, geom = "point", size = 2.6, color = "black") +
    scale_fill_viridis_d(option = "D", end = 0.9) +
    scale_y_log10(labels = label_dollar(prefix = "EUR ", scale_cut = cut_short_scale())) +
    labs(
      title = title,
      subtitle = subtitle,
      x = "Nationality",
      y = "Market value (log scale)",
      caption = "Specific nationalities with n >= 30 in this stratum; observational comparison."
    ) +
    theme_minimal(base_size = 16) +
    theme(
      legend.position = "none",
      plot.title = element_text(face = "bold", size = 18),
      plot.subtitle = element_text(color = "grey30", size = 12),
      plot.caption = element_text(color = "grey45", size = 10, hjust = 0),
      axis.text.x = element_text(angle = 35, hjust = 1),
      panel.grid.minor = element_blank()
    )
  save_poster_fig(p, filename, width = 9.5, height = 6.5)
}

plot_median_ci <- median_ci %>%
  filter(stratum_label %in% c("Regular midfielders", "Regular defenders")) %>%
  group_by(stratum_label) %>%
  mutate(nationality = fct_reorder(nationality, median_value_m)) %>%
  ungroup()

p_median <- ggplot(plot_median_ci, aes(x = median_value_m, y = nationality, color = stratum_label)) +
  geom_errorbarh(aes(xmin = ci_low, xmax = ci_high), height = 0.18, linewidth = 0.8) +
  geom_point(size = 3) +
  facet_wrap(~ stratum_label, scales = "free_y") +
  scale_x_continuous(labels = label_dollar(prefix = "EUR ", suffix = "M")) +
  scale_color_viridis_d(option = "D", end = 0.75) +
  labs(
    title = "Regular-tier nationality gaps are position-specific",
    subtitle = "Bootstrapped 95% CIs for median market value; top specific nationalities by sample size",
    x = "Median market value (million EUR)",
    y = NULL,
    color = NULL
  ) +
  theme_minimal(base_size = 16) +
  theme(
    legend.position = "none",
    plot.title = element_text(face = "bold", size = 18),
    plot.subtitle = element_text(color = "grey30", size = 12),
    panel.grid.minor = element_blank()
  )

plot_stratum(
  "Regular midfielders",
  "fig_regular_midfielder_value_by_nationality.png",
  "Regular midfielders vary by nationality"
)
plot_stratum(
  "Regular defenders",
  "fig_regular_defender_value_by_nationality.png",
  "Regular defenders show smaller nationality gaps"
)
save_poster_fig(p_median, "fig_regular_median_value_ci.png", width = 10, height = 6.5)

cat("Group tests complete\n")
print(kruskal_results)
