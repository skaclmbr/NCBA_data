
source("ncba_functions.R")

results <- get_records(
  common_name = c("American Crow"),
  start_end_date = c("2025-01-01", "2025-01-02"),
  checklists_only = FALSE,
  all_observations = TRUE,
  atlas_only = TRUE
)

