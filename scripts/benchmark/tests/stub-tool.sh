#!/bin/bash
# Test double for `xcrun` (simctl, devicectl) and `xcodebuild`. Usage: stub-tool.sh xcrun|xcodebuild <args...>
# Env: STUB_LOG (invocation log), STUB_CONTAINER (fake app data container), STUB_THERMAL_AFTER_AT (runIndex whose
# thermalStateAfter is "fair"; others nominal).
tool=$1; shift
echo "$tool $*" >> "${STUB_LOG:?}"
HEADER="scenario,sha,runIndex,thermalStateBefore,thermalStateAfter"
append_row() { # args: scenario sha runIndex
  mkdir -p "$STUB_CONTAINER/Documents"
  local f="$STUB_CONTAINER/Documents/benchmark.csv" after=nominal
  [ -e "$f" ] || echo "$HEADER" > "$f"
  [ "$3" = "${STUB_THERMAL_AFTER_AT:-}" ] && after=fair
  echo "$1,$2,$3,nominal,$after" >> "$f"
}
parse_and_run() { # args from the command line or BENCH_ARGS
  local sc="" sha="" idx="" a
  set -- $*
  while [ $# -gt 0 ]; do
    case "$1" in -benchScenario) sc=$2;; -benchSHA) sha=$2;; -benchRunIndex) idx=$2;; esac; shift
  done
  [ -n "$sc" ] && append_row "$sc" "$sha" "$idx"
}
if [ "$tool" = xcodebuild ]; then
  parse_and_run "${TEST_RUNNER_BENCH_ARGS:-}"
  echo "** TEST EXECUTE SUCCEEDED **"; exit 0
fi
case "$1 $2" in
  "simctl install"|"simctl terminate") exit 0;;
  "simctl get_app_container") echo "$STUB_CONTAINER"; exit 0;;
  "simctl launch")
    echo "BENCH_CSV_PATH=$STUB_CONTAINER/Documents/benchmark.csv"
    parse_and_run "$*"; echo BENCH_DONE; exit 0;;
esac
case "$1 $2 $3" in
  "devicectl device install") exit 0;;
  "devicectl device process")
    if [ "$4" = launch ]; then
      for a in "$@"; do [ "$prev" = --json-output ] && echo '{"result":{"process":{"processIdentifier":4242}}}' > "$a"; prev=$a; done
      echo "BENCH_CSV_PATH=/private/var/mobile/Documents/benchmark.csv"
      parse_and_run "$*"; echo BENCH_DONE
    fi
    exit 0;;
  "devicectl device copy")
    for a in "$@"; do [ "$prev" = --destination ] && dest=$a; prev=$a; done
    [ -e "$STUB_CONTAINER/Documents/benchmark.csv" ] || exit 1
    cp "$STUB_CONTAINER/Documents/benchmark.csv" "$dest"; exit 0;;
esac
echo "stub-tool: unhandled: $tool $*" >&2; exit 2
