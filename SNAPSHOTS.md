# Source snapshots

The canonical working tables on main are the expanded source database extracted from tinyAM comp-assessments 34470212e1102f3f31bf3f08c26a8a72a985c948.

The historical commit 849a4a559835dc6117575dbf5a5e32f77a39de02 preserves the five reviewed-example source tables from tinyAM main 78f3d347331b0e770d55a855de4c5b90307fd400 byte for byte. It is a frozen historical view for reproducing that working set, not another actively maintained database. Both snapshots retain the original assessment identifiers and units.

tinyAM pins curated and preliminary data independently in analysis/comp_assessments/saio_revisions.csv. Updating either pin requires deliberate review; editing SAIO's current working tables does not alter previous snapshots. Raw source caches remain local and ignored.
