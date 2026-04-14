from ncba_functions import get_records

results = get_records(
    common_name = ["American Crow"],
    start_end_date = ["2025-01-01", "2025-01-02"],
    checklists_only = False,
    all_observations = True,
    atlas_only = True
)



