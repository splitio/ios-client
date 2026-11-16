#!/bin/bash
# Tests for run-benchmark.sh. No device, no xcodebuild: dry-run output and a stubbed tool. Run: scripts/benchmark/tests/test-run-benchmark.sh
HERE=$(cd "$(dirname "$0")" && pwd)
DRIVER="$HERE/../run-benchmark.sh"
EXPECTED="$HERE/../expected"
TMP=$(mktemp -d "${TMPDIR:-/tmp}/bench-test.XXXXXX")
trap 'rm -rf "$TMP"' EXIT
FAILS=0
pass() { echo "PASS $1"; }
fail() { echo "FAIL $1: $2"; FAILS=$((FAILS + 1)); }
check() { if [ "$2" = ok ]; then pass "$1"; else fail "$1" "$3"; fi; }

COMMON=(--baseline-sha base111 --baseline-app BASE.app --candidate-sha cand222 --candidate-app CAND.app --idle-gap 5 --workdir WORK)

# 1. Dry-run plan equals the checked-in ABBA sequence.
"$DRIVER" --dry-run --mode devicectl --device DEV123 --scenarios A,B --blocks 2 --seed 7 "${COMMON[@]}" > "$TMP/plan.txt" 2>"$TMP/err.txt"
if diff "$EXPECTED/plan-abba-seed7.txt" "$TMP/plan.txt" > "$TMP/diff.txt"; then check plan_matches_expected ok; else check plan_matches_expected bad "$(head -5 "$TMP/diff.txt")"; fi

# 2. First run of each scenario's builds is the discarded warm-up: marked, and precedes every measured run of its scenario.
bad=""
for s in A B; do
  first=$(grep -n "scenario=$s " "$TMP/plan.txt" | head -2 | grep -vc WARMUP)
  [ "$first" = 0 ] || bad="$bad $s"
done
[ "$(grep -c 'WARMUP discarded' "$TMP/plan.txt")" = 4 ] || bad="$bad count"
check warmup_marked_first_per_scenario "$([ -z "$bad" ] && echo ok)" "$bad"

# 3. Every measured block is ABBA: baseline, candidate, candidate, baseline.
roles=$(grep MEASURED "$TMP/plan.txt" | sed -E 's/.*build=([a-z]+) .*/\1/' | awk '{r=substr($1,1,1); printf "%s", (r=="b"?"B":"C"); if (NR%4==0) printf "\n"}')
[ "$(echo "$roles" | sort -u)" = "BCCB" ] && [ "$(echo "$roles" | wc -l | tr -d ' ')" = 4 ]
check abba_every_block "$([ $? = 0 ] && echo ok)" "$(echo "$roles" | sort | uniq -c)"

# 4. Seeded: same seed, same plan; a different seed, a different order.
"$DRIVER" --dry-run --mode devicectl --device DEV123 --scenarios A,B --blocks 2 --seed 7 "${COMMON[@]}" > "$TMP/plan2.txt" 2>/dev/null
"$DRIVER" --dry-run --mode devicectl --device DEV123 --scenarios A,B --blocks 2 --seed 8 "${COMMON[@]}" > "$TMP/plan3.txt" 2>/dev/null
cmp -s "$TMP/plan.txt" "$TMP/plan2.txt" && ! cmp -s <(grep MEASURED "$TMP/plan.txt" | sed 's/^[0-9]* //;s/runIndex=[0-9]*//') <(grep MEASURED "$TMP/plan3.txt" | sed 's/^[0-9]* //;s/runIndex=[0-9]*//')
check seeded_order "$([ $? = 0 ] && echo ok)" "seed 7 twice must match and seed 8 must differ"

# 5. Dry-run runs no tool at all, in every mode.
for mode in devicectl simctl xctest; do
  : > "$TMP/calls.log"
  STUB_LOG="$TMP/calls.log" STUB_CONTAINER="$TMP/c" BENCH_XCRUN="$HERE/stub-tool.sh xcrun" BENCH_XCODEBUILD="$HERE/stub-tool.sh xcodebuild" \
    "$DRIVER" --dry-run --show-commands --mode $mode --device DEV123 --scenarios A --blocks 1 --seed 3 "${COMMON[@]}" > "$TMP/cmds-$mode.txt" 2>&1
  check "dry_run_runs_nothing_$mode" "$([ ! -s "$TMP/calls.log" ] && echo ok)" "$(cat "$TMP/calls.log")"
done

# 6. Every launch carries the SHA of its plan line and its run index; mode-specific launch command is present.
for mode in devicectl simctl xctest; do
  n_run=$(grep -cE '^[0-9]{3} ' "$TMP/cmds-$mode.txt")
  case $mode in
    devicectl) pat='devicectl device process launch' ;;
    simctl) pat='simctl launch' ;;
    xctest) pat='test-without-building' ;;
  esac
  n_launch=$(grep -c -- "$pat" "$TMP/cmds-$mode.txt")
  n_sha=$(grep -- "$pat" "$TMP/cmds-$mode.txt" | grep -cE -- '-benchSHA (base111|cand222) ')
  bad=0
  while read -r seq _ rest; do :; done < /dev/null
  # the SHA on each launch must equal the sha on its plan line, in order
  want=$(grep -E '^[0-9]{3} ' "$TMP/cmds-$mode.txt" | sed -E 's/.* sha=([a-z0-9]+) .*/\1/')
  got=$(grep -- "$pat" "$TMP/cmds-$mode.txt" | sed -E 's/.*-benchSHA ([a-z0-9]+) .*/\1/')
  [ "$want" = "$got" ] && [ "$n_run" = 6 ] && [ "$n_launch" = 6 ] && [ "$n_sha" = 6 ]
  check "sha_in_every_launch_$mode" "$([ $? = 0 ] && echo ok)" "runs=$n_run launches=$n_launch sha=$n_sha"
done
diff "$EXPECTED/commands-devicectl.txt" "$TMP/cmds-devicectl.txt" > "$TMP/diff.txt"
check commands_devicectl_match_expected "$([ $? = 0 ] && echo ok)" "$(head -5 "$TMP/diff.txt")"
diff "$EXPECTED/commands-simctl.txt" "$TMP/cmds-simctl.txt" > "$TMP/diff.txt"
check commands_simctl_match_expected "$([ $? = 0 ] && echo ok)" "$(head -5 "$TMP/diff.txt")"
diff "$EXPECTED/commands-xctest.txt" "$TMP/cmds-xctest.txt" > "$TMP/diff.txt"
check commands_xctest_match_expected "$([ $? = 0 ] && echo ok)" "$(head -5 "$TMP/diff.txt")"

# 7. Scenario D without an endpoint is refused (a run that can never fire ready-from-cache).
"$DRIVER" --dry-run --mode devicectl --device DEV123 --scenarios D --blocks 1 "${COMMON[@]}" > /dev/null 2>&1
check scenario_D_requires_endpoint "$([ $? != 0 ] && echo ok)" "exit 0"

# 8. Stubbed real runs: merge, single header, run mode, warm-ups discarded, thermal flag, wall clock.
for mode in simctl devicectl xctest; do
  W="$TMP/w-$mode"; OUT="$TMP/results-$mode.csv"; : > "$TMP/log-$mode"; rm -rf "$TMP/c-$mode"
  extra=()
  [ $mode = xctest ] && extra=(--simulator)
  STUB_LOG="$TMP/log-$mode" STUB_CONTAINER="$TMP/c-$mode" STUB_THERMAL_AFTER_AT=4 \
    BENCH_XCRUN="$HERE/stub-tool.sh xcrun" BENCH_XCODEBUILD="$HERE/stub-tool.sh xcodebuild" \
    "$DRIVER" --mode $mode --device SIM-ID --scenarios A --blocks 1 --seed 3 --baseline-sha base111 --baseline-app BASE.app \
      --candidate-sha cand222 --candidate-app CAND.app --idle-gap 0 --workdir "$W" --out "$OUT" "${extra[@]}" > "$TMP/run-$mode.txt" 2>&1
  rc=$?
  want_mode=direct; [ $mode = xctest ] && want_mode=xctest
  hdr=$(grep -c '^scenario,' "$OUT" 2>/dev/null)
  rows=$(grep -vc '^scenario,' "$OUT" 2>/dev/null)
  modes=$(awk -F, 'NR==1{for(i=1;i<=NF;i++)if($i=="runMode")c=i;next}{print $c}' "$OUT" 2>/dev/null | sort -u | tr '\n' ' ')
  shas=$(awk -F, 'NR==1{for(i=1;i<=NF;i++)if($i=="sha")c=i;next}{print $c}' "$OUT" 2>/dev/null | tr '\n' ' ')
  flag=$(awk -F, 'NR==1{for(i=1;i<=NF;i++){if($i=="thermalFlag")c=i;if($i=="runIndex")r=i};next}$c!="ok"{print $r":"$c}' "$OUT" 2>/dev/null | tr '\n' ' ')
  wall=$(awk -F, 'NR==1{for(i=1;i<=NF;i++)if($i=="wallClockSeconds")c=i;next}$c!~/^[0-9]+(\.[0-9]+)?$/{bad=1}END{print bad+0}' "$OUT" 2>/dev/null)
  cols=$(head -1 "$OUT" 2>/dev/null)
  ok=ok
  [ $rc = 0 ] || ok="rc=$rc"
  [ "$hdr" = 1 ] || ok="$ok header-count=$hdr"
  [ "$rows" = 4 ] || ok="$ok rows=$rows(want 4: warm-ups discarded)"
  [ "$modes" = "$want_mode " ] || ok="$ok modes=[$modes]"
  [ "$shas" = "base111 cand222 cand222 base111 " ] || ok="$ok shas=[$shas]"
  [ "$flag" = "4:NOT_NOMINAL " ] || ok="$ok flags=[$flag]"
  [ "$wall" = 0 ] || ok="$ok wall"
  case "$cols" in scenario,sha,runIndex,thermalStateBefore,thermalStateAfter,runMode,planSeq,buildRole,wallClockSeconds,thermalFlag) ;; *) ok="$ok cols=$cols";; esac
  check "stubbed_run_$mode" "$([ "$ok" = ok ] && echo ok)" "$ok"
done

echo "failures: $FAILS"
[ $FAILS = 0 ]
