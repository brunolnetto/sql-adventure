-- =====================================================
-- Master Script: Run All Recursive CTE Examples
-- =====================================================

-- This script runs all examples in the correct order
-- Each example is self-contained and idempotent

\echo 'Running Hierarchical & Graph Traversal Examples...'
\i 01-hierarchical-graph-traversal/01-employee-hierarchy.sql
\i 01-hierarchical-graph-traversal/02-bill-of-materials.sql
\i 01-hierarchical-graph-traversal/03-category-tree.sql
\i 01-hierarchical-graph-traversal/04-graph-reachability.sql
\i 01-hierarchical-graph-traversal/05-dependency-resolution.sql
\i 01-hierarchical-graph-traversal/06-filesystem-hierarchy.sql
\i 01-hierarchical-graph-traversal/07-family-tree.sql

\echo 'Running Iteration & Loop Examples...'
\i 02-iteration-loops/01-number-series.sql
\i 02-iteration-loops/02-date-series.sql
\i 02-iteration-loops/03-fibonacci-sequence.sql
\i 02-iteration-loops/04-collatz-sequence.sql
\i 02-iteration-loops/05-base-conversion.sql
\i 02-iteration-loops/06-factorial-calculation.sql
\i 02-iteration-loops/07-running-total.sql

\echo 'Running Path-Finding & Analysis Examples...'
\i 03-path-finding-analysis/01-shortest-path.sql
\i 03-path-finding-analysis/02-topological-sort.sql
\i 03-path-finding-analysis/03-cycle-detection.sql

\echo 'Running Data Transformation & Parsing Examples...'
\i 04-data-transformation-parsing/01-string-splitting.sql
\i 04-data-transformation-parsing/02-transitive-closure.sql
\i 04-data-transformation-parsing/03-json-parsing.sql

\echo 'Running Simulation & State Machines Examples...'
\i 05-simulation-state-machines/01-inventory-simulation.sql
\i 05-simulation-state-machines/02-game-simulation.sql

\echo 'Running Data Repair & Healing Examples...'
\i 06-data-repair-healing/01-sequence-gaps.sql
\i 06-data-repair-healing/02-forward-fill-nulls.sql
\i 06-data-repair-healing/03-interval-coalescing.sql

\echo 'Running Mathematical & Theoretical Examples...'
\i 07-mathematical-theoretical/01-fibonacci-sequence.sql
\i 07-mathematical-theoretical/02-prime-numbers.sql
\i 07-mathematical-theoretical/03-permutation-generation.sql

\echo 'Running Bonus Quirky Examples...'
\i 08-bonus-quirky-examples/01-work-streak.sql
\i 08-bonus-quirky-examples/02-password-generator.sql
\i 08-bonus-quirky-examples/03-spiral-matrix.sql

\echo 'All examples completed successfully!' 