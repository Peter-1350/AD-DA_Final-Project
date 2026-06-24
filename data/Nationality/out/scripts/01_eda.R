library(tidyverse)
library(scales)
library(viridis)
library(glue)
library(patchwork)

root_dir <- normalizePath(file.path(getwd()), winslash = "/", mustWork = TRUE)
data_path <- file.path(root_dir, "data", "FIFA 23 Players.csv")
out_dir <- file.path(root_dir, "data", "Nationality", "out")
fig_dir <- file.path(out_dir, "figs")
dir.create(fig_dir, recursive = TRUE, showWarnings = FALSE)

save_poster_fig <- function(plot, filename, width = 8, height = 6) {
  title <- plot$labels$title %||% ""
  subtitle <- plot$labels$subtitle %||% ""
  if (nchar(title) > 70) warning("Long title: ", title)
  if (nchar(subtitle) > 110) warning("Long subtitle: ", subtitle)
  ggsave(file.path(fig_dir, filename), plot, width = width, height = height, dpi = 300)
}

raw <- readr::read_csv(data_path, show_col_types = FALSE)

df <- raw %>%
  transmute(
    known_as = `Known As`,
    full_name = `Full Name`,
    overall = as.numeric(Overall),
    potential = as.numeric(Potential),
    value_eur = as.numeric(`Value(in Euro)`),
    wage_eur = as.numeric(`Wage(in Euro)`),
    positions_played = `Positions Played`,
    best_position = `Best Position`,
    nationality = Nationality,
    age = as.numeric(Age),
    height_cm = as.numeric(`Height(in cm)`),
    weight_kg = as.numeric(`Weight(in kg)`),
    total_stats = as.numeric(TotalStats),
    base_stats = as.numeric(BaseStats),
    club_name = `Club Name`,
    international_reputation = as.numeric(`International Reputation`),
    preferred_foot = `Preferred Foot`
  ) %>%
  mutate(
    position_group = case_when(
      best_position %in% c("ST", "CF", "LW", "RW") ~ "Forward",
      best_position %in% c("CAM", "CM", "CDM", "LM", "RM") ~ "Midfielder",
      best_position %in% c("CB", "LB", "RB", "LWB", "RWB") ~ "Defender",
      best_position == "GK" ~ "Goalkeeper",
      TRUE ~ "Other"
    ),
    ability_tier = case_when(
      overall >= 85 ~ "World-class (85+)",
      overall >= 78 ~ "Starter (78-84)",
      overall >= 70 ~ "Regular (70-77)",
      TRUE ~ "Development (<70)"
    ),
    ability_tier = factor(
      ability_tier,
      levels = c("Development (<70)", "Regular (70-77)", "Starter (78-84)", "World-class (85+)")
    ),
    position_group = factor(
      position_group,
      levels = c("Forward", "Midfielder", "Defender", "Goalkeeper", "Other")
    ),
    value_m = value_eur / 1e6,
    log_value = if_else(value_eur > 0, log(value_eur), NA_real_)
  )

analysis_df <- df %>%
  filter(value_eur > 0, !is.na(nationality), !is.na(position_group), position_group != "Other")

missing_summary <- tibble(
  variable = names(df),
  missing_n = map_int(df, ~ sum(is.na(.x))),
  missing_pct = missing_n / nrow(df)
) %>%
  arrange(desc(missing_n), variable)

quality_summary <- tibble(
  raw_n = nrow(raw),
  raw_cols = ncol(raw),
  analysis_n = nrow(analysis_df),
  zero_value_n = sum(df$value_eur <= 0, na.rm = TRUE),
  missing_value_n = sum(is.na(df$value_eur)),
  duplicate_full_name_n = sum(duplicated(df$full_name)),
  nationality_n = n_distinct(df$nationality),
  position_group_n = n_distinct(df$position_group)
)

strata_summary <- analysis_df %>%
  count(position_group, ability_tier, nationality, name = "nationality_n") %>%
  group_by(position_group, ability_tier) %>%
  summarise(
    n = sum(nationality_n),
    nationalities = n_distinct(nationality),
    nationalities_ge_25 = sum(nationality_n >= 25),
    nationalities_ge_30 = sum(nationality_n >= 30),
    .groups = "drop"
  ) %>%
  left_join(
    analysis_df %>%
      group_by(position_group, ability_tier) %>%
      summarise(
        median_value_m = median(value_m),
        q1_value_m = quantile(value_m, 0.25),
        q3_value_m = quantile(value_m, 0.75),
        .groups = "drop"
      ),
    by = c("position_group", "ability_tier")
  ) %>%
  arrange(desc(nationalities_ge_30), desc(n))

target_strata <- strata_summary %>%
  filter(n >= 450, nationalities_ge_30 >= 5, ability_tier != "World-class (85+)") %>%
  arrange(desc(nationalities_ge_30), desc(n)) %>%
  slice_head(n = 4)

top_nationalities_by_stratum <- analysis_df %>%
  semi_join(target_strata, by = c("position_group", "ability_tier")) %>%
  count(position_group, ability_tier, nationality, name = "n") %>%
  group_by(position_group, ability_tier) %>%
  arrange(desc(n), nationality, .by_group = TRUE) %>%
  mutate(rank = row_number()) %>%
  filter(rank <= 8, n >= 20) %>%
  ungroup()

readr::write_csv(missing_summary, file.path(out_dir, "missing_summary.csv"))
readr::write_csv(quality_summary, file.path(out_dir, "quality_summary.csv"))
readr::write_csv(strata_summary, file.path(out_dir, "strata_summary.csv"))
readr::write_csv(target_strata, file.path(out_dir, "target_strata.csv"))
readr::write_csv(top_nationalities_by_stratum, file.path(out_dir, "top_nationalities_by_stratum.csv"))
saveRDS(analysis_df, file.path(out_dir, "clean_fifa_nationality.rds"))

overview_counts <- analysis_df %>%
  count(position_group, ability_tier)

p_counts <- ggplot(overview_counts, aes(x = ability_tier, y = n, fill = position_group)) +
  geom_col(position = "dodge", width = 0.72) +
  geom_text(
    aes(label = comma(n)),
    position = position_dodge(width = 0.72),
    vjust = -0.25,
    size = 3.6
  ) +
  scale_fill_viridis_d(option = "D", end = 0.85) +
  scale_y_continuous(labels = comma, expand = expansion(mult = c(0, 0.12))) +
  labs(
    title = "Most FIFA 23 players sit below starter tier",
    subtitle = glue("Analysis sample n = {comma(nrow(analysis_df))}; zero-value players excluded n = {quality_summary$zero_value_n}"),
    x = "Overall rating tier",
    y = "Players",
    fill = "Position group"
  ) +
  theme_minimal(base_size = 16) +
  theme(
    plot.title = element_text(face = "bold", size = 18),
    plot.subtitle = element_text(color = "grey30", size = 12),
    panel.grid.minor = element_blank(),
    axis.text.x = element_text(angle = 20, hjust = 1)
  )

value_limits <- quantile(analysis_df$value_eur, probs = c(0.01, 0.99), na.rm = TRUE)
p_value <- ggplot(analysis_df, aes(x = value_eur)) +
  geom_histogram(bins = 45, fill = viridis(1, option = "D", begin = 0.25), color = "white") +
  scale_x_log10(labels = label_dollar(prefix = "EUR ", scale_cut = cut_short_scale())) +
  labs(
    title = "Market value is strongly right-skewed",
    subtitle = glue("Median = EUR {number(median(analysis_df$value_m), accuracy = 0.01)}M; IQR = EUR {number(quantile(analysis_df$value_m, .25), accuracy = 0.01)}M-{number(quantile(analysis_df$value_m, .75), accuracy = 0.01)}M"),
    x = "Market value (log scale)",
    y = "Players"
  ) +
  coord_cartesian(xlim = value_limits) +
  theme_minimal(base_size = 16) +
  theme(
    plot.title = element_text(face = "bold", size = 18),
    plot.subtitle = element_text(color = "grey30", size = 12),
    panel.grid.minor = element_blank()
  )

save_poster_fig(p_counts, "fig_data_overview_counts.png", width = 10, height = 6)
save_poster_fig(p_value, "fig_eda_value_distribution.png", width = 8, height = 6)

cat("EDA complete\n")
print(quality_summary)
print(target_strata)
