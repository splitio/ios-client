# Projects a merged driver CSV onto the issue-27 columns the analysis pins (BenchmarkAnalysis.columns), by header name.
# usage: python3 -I project-csv.py <merged-csv> <columns-file> > projected.csv
import csv, sys
src, colfile = sys.argv[1], sys.argv[2]
cols = [c for c in open(colfile).read().split("\n") if c]
with open(src, newline="") as f:
    rows = list(csv.reader(f))
head = rows[0]
missing = [c for c in cols if c not in head]
if missing:
    sys.exit("project-csv: merged CSV lacks columns: " + ",".join(missing))
idx = [head.index(c) for c in cols]
w = csv.writer(sys.stdout, lineterminator="\n")
w.writerow(cols)
for r in rows[1:]:
    if r:
        w.writerow([r[i] for i in idx])
