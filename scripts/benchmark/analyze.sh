#!/bin/bash
# Runs the issue-29 analysis on a merged benchmark CSV without editing SplitTests.
# usage: scripts/benchmark/analyze.sh <merged-csv> [minRuns]
# Compiles SplitTests/Benchmark/BenchmarkAnalysis.swift with scripts/benchmark/analyze-main.swift into a temp dir.
set -e
[ $# -ge 1 ] || { echo "usage: analyze.sh <merged-csv> [minRuns]" >&2; exit 2; }
HERE=$(cd "$(dirname "$0")" && pwd)
ROOT=$(cd "$HERE/../.." && pwd)
TMP=$(mktemp -d "${TMPDIR:-/tmp}/bench-analyze.XXXXXX")
trap 'rm -rf "$TMP"' EXIT
cp "$ROOT/SplitTests/Benchmark/BenchmarkAnalysis.swift" "$TMP/BenchmarkAnalysis.swift"
cp "$HERE/analyze-main.swift" "$TMP/main.swift"
(cd "$TMP" && xcrun swiftc -O -module-name BenchAnalyze BenchmarkAnalysis.swift main.swift -o analyze)
# The analysis pins the issue-27 header; the driver's merged CSV carries more columns, so project onto the pinned ones.
sed -n '/static let columns: \[String\] = \[/,/^    \]/p' "$ROOT/SplitTests/Benchmark/BenchmarkAnalysis.swift" \
  | grep -o '"[A-Za-z0-9_]*"' | tr -d '"' > "$TMP/columns.txt"
python3 -I "$HERE/project-csv.py" "$1" "$TMP/columns.txt" > "$TMP/projected.csv"
shift
"$TMP/analyze" "$TMP/projected.csv" "$@"
