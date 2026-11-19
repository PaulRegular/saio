# Assessment source reviews

Start with `stock_id` in `stocks.csv` and the run’s `assessment_id` in
`assessments.csv`. Reviews describe material source choices, transformations,
verification and gaps. The assessment table has routine source links. Each stock review brings together the source search and checks for that unit. The [candidate register](../../database/candidates.csv) records the screening decisions.

Find a review by stock ID or, for a unit still under review, its organization-prefixed candidate key. Identify each assessment run within a review. Programme inventories and other evidence covering multiple stocks are in [shared reviews](shared/). For a published release, use the source paths at its tagged revision.

Keep official run identity, source definitions, units, transformations, verification and unresolved source gaps here. Describe the official assessment's equations, likelihoods, parameter sharing, biological definitions and uncertainty where they explain the source records. Native assessment diagnostics and run-reproduction checks belong here when they establish run identity or qualify the reported estimates.

Keep secondary model recipes, observation pooling or omissions chosen for an analysis, starting-value attempts, secondary fit diagnostics and model-agreement results with the analysis that uses them. Source gaps remain documented here even when they also prevent a secondary analysis. Canonical derived outputs retain their source definitions, calculation rules and uncertainty limitations here.

Retain distinct historical runs under explicit assessment identifiers. New recoveries take precedence over superseded row counts or missing-data claims; do not mix observations or outputs from different runs.
