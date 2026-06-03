source(file.path("data", "FIFA", "out", "scripts", "00_setup.R"))

cluster_df <- fifa_df %>%
  filter(value_eur > 0) %>%
  transmute(
    player = `Known As`,
    nationality = nationality,
    overall = overall,
    potential = potential,
    total_stats = total_stats,
    base_stats = base_stats,
    pace_total = pace_total,
    shooting_total = shooting_total,
    passing_total = passing_total,
    dribbling_total = dribbling_total,
    defending_total = defending_total,
    physicality_total = physicality_total,
    log_value = log10(value_eur)
  ) %>%
  drop_na()

cluster_vars <- cluster_df %>%
  select(-player, -nationality)

scaled_mat <- scale(cluster_vars)

set.seed(42)
k_grid <- tibble(k = 2:8) %>%
  mutate(
    km = map(k, ~ kmeans(scaled_mat, centers = .x, nstart = 50, iter.max = 100)),
    sil = map_dbl(km, ~ mean(cluster::silhouette(.x$cluster, dist(scaled_mat))[ , "sil_width"]))
  )

write_csv(k_grid %>% select(k, sil), file.path(out_dir, "cluster_silhouette_grid.csv"))

p_sil <- ggplot(k_grid, aes(x = k, y = sil)) +
  geom_line(color = "#3B5BA5", linewidth = 0.8) +
  geom_point(size = 2.5, color = "#3B5BA5") +
  scale_x_continuous(breaks = 2:8) +
  labs(
    title = "Silhouette suggests a small number of clusters",
    subtitle = "K-means run on standardized ability and value variables",
    x = "Number of clusters",
    y = "Average silhouette width"
  )

save_poster_fig(p_sil, file.path(fig_dir, "fig_cluster_silhouette.png"), width = 8, height = 5.5)

best_k <- k_grid$k[which.max(k_grid$sil)]
final_km <- kmeans(scaled_mat, centers = best_k, nstart = 30, iter.max = 100)
cluster_df$cluster <- factor(final_km$cluster)

center_tbl <- as_tibble(final_km$centers, rownames = "cluster") %>%
  mutate(cluster = factor(cluster, levels = sort(unique(cluster_df$cluster))))

write_csv(center_tbl, file.path(out_dir, "cluster_centers.csv"))

p_centers <- center_tbl %>%
  pivot_longer(-cluster, names_to = "feature", values_to = "z") %>%
  mutate(feature = fct_reorder(feature, z, .fun = median)) %>%
  ggplot(aes(x = feature, y = z, fill = cluster)) +
  geom_col(position = position_dodge(width = 0.75), width = 0.7) +
  coord_flip() +
  scale_fill_viridis_d(end = 0.9) +
  labs(
    title = "Cluster profiles separate value-heavy from balanced players",
    subtitle = sprintf("k = %d chosen by silhouette; features are standardized z-scores", best_k),
    x = NULL,
    y = "Cluster center (z-score)",
    fill = "Cluster"
  )

save_poster_fig(p_centers, file.path(fig_dir, "fig_cluster_profiles.png"), width = 10, height = 7.5)

cluster_nat <- cluster_df %>%
  mutate(nationality_band = group_by_nationality_band(nationality)) %>%
  count(cluster, nationality_band, sort = TRUE) %>%
  group_by(cluster) %>%
  mutate(prop = n / sum(n)) %>%
  ungroup() %>%
  filter(nationality_band != "Other")

p_nat <- ggplot(cluster_nat, aes(x = cluster, y = prop, fill = nationality_band)) +
  geom_col(position = "fill") +
  scale_y_continuous(labels = percent_format()) +
  scale_fill_viridis_d(end = 0.9) +
  labs(
    title = "Nationality mix differs across clusters",
    subtitle = "Top 12 nationalities shown; the rest are grouped as Other",
    x = "Cluster",
    y = "Share within cluster",
    fill = "Nationality"
  )

save_poster_fig(p_nat, file.path(fig_dir, "fig_cluster_nationality_mix.png"), width = 10, height = 6.5)
