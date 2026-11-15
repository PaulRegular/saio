# Assessment discovery

The [candidate register](candidates.csv) records official inventory entries, identity matches, source evidence and screening decisions. `candidate_unit_id` links entries assessed as the same unit. `matched_stock_id` connects an entry to the published stock table.

Detailed stock searches and shared inventory evidence are in the [screening reviews](../source_reviews/screening/). Source interpretation for an imported assessment belongs in its [stock review](../source_reviews/).

Generate current summaries from the register using the [discovery commands](../scripts/README.md#discovery-reports). The earlier batch decisions and report snapshots are in Git at `b4145de`. For example, `git show b4145de:discovery/selections/selected_batch_01_2026.csv` displays the original first batch.
