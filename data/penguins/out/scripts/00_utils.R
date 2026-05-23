`%||%` <- function(x, y) {
  if (is.null(x) || length(x) == 0) y else x
}

get_script_path <- function() {
  args <- commandArgs(trailingOnly = FALSE)
  file_arg <- grep("^--file=", args, value = TRUE)
  if (length(file_arg) > 0) {
    return(normalizePath(sub("^--file=", "", file_arg[1]), winslash = "\\", mustWork = FALSE))
  }
  if (!is.null(sys.frames()[[1]]$ofile)) {
    return(normalizePath(sys.frames()[[1]]$ofile, winslash = "\\", mustWork = FALSE))
  }
  stop("Cannot determine script path.")
}

get_project_root <- function() {
  normalizePath(getwd(), winslash = "\\", mustWork = FALSE)
}

load_fifa23 <- function() {
  root <- get_project_root()
  path <- file.path(root, "data", "FIFA 23 Players.csv")
  if (!file.exists(path)) {
    stop("Data file not found: ", path)
  }

  df <- read.csv(path, check.names = FALSE, stringsAsFactors = FALSE)

  dplyr::as_tibble(df) |>
    dplyr::rename(
      known_as = `Known As`,
      full_name = `Full Name`,
      overall = Overall,
      potential = Potential,
      value_eur = `Value(in Euro)`,
      positions_played = `Positions Played`,
      best_position = `Best Position`,
      nationality = Nationality,
      age = Age,
      height_cm = `Height(in cm)`,
      weight_kg = `Weight(in kg)`,
      total_stats = TotalStats,
      base_stats = BaseStats,
      club_name = `Club Name`,
      wage_eur = `Wage(in Euro)`,
      release_clause_eur = `Release Clause`,
      club_position = `Club Position`,
      contract_until = `Contract Until`,
      club_jersey_number = `Club Jersey Number`,
      joined_on = `Joined On`,
      on_loan = `On Loan`,
      preferred_foot = `Preferred Foot`,
      weak_foot_rating = `Weak Foot Rating`,
      skill_moves = `Skill Moves`,
      international_reputation = `International Reputation`,
      national_team_name = `National Team Name`,
      national_team_position = `National Team Position`,
      attacking_work_rate = `Attacking Work Rate`,
      defensive_work_rate = `Defensive Work Rate`
    ) |>
    dplyr::mutate(
      log_value = ifelse(value_eur > 0, log10(value_eur), NA_real_),
      log_wage = ifelse(wage_eur > 0, log10(wage_eur), NA_real_),
      log_release_clause = ifelse(release_clause_eur > 0, log10(release_clause_eur), NA_real_),
      best_position = factor(best_position),
      preferred_foot = factor(preferred_foot),
      nationality = factor(nationality),
      club_name = factor(club_name),
      on_loan = factor(on_loan),
      attacking_work_rate = factor(attacking_work_rate),
      defensive_work_rate = factor(defensive_work_rate)
    )
}

save_poster_fig <- function(plot, filename, width = 8, height = 6) {
  title <- plot$labels$title %||% ""
  subtitle <- plot$labels$subtitle %||% ""
  if (nchar(title) > 60) {
    warning("Title too long (", nchar(title), " chars): ", title)
  }
  if (nchar(subtitle) > 80) {
    warning("Subtitle too long (", nchar(subtitle), " chars): ", subtitle)
  }

  root <- get_project_root()
  fig_dir <- file.path(root, "data", "penguins", "out", "figs")
  dir.create(fig_dir, recursive = TRUE, showWarnings = FALSE)
  ggplot2::ggsave(
    filename = file.path(fig_dir, filename),
    plot = plot,
    width = width,
    height = height,
    dpi = 300,
    limitsize = FALSE
  )
}
