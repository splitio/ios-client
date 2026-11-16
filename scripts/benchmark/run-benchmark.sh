#!/bin/bash
# Benchmark driver: plans an ABBA run order, launches the benchmark host per run, collects the appended CSV rows.
# bash 3.2 compatible. See usage below. Tool commands: BENCH_XCRUN (default xcrun), BENCH_XCODEBUILD (default xcodebuild).

BID=com.split.framework.SplitBenchmarkHost
MODE=""; DEVICE=""; SCENARIOS=""; BLOCKS=1; SEED=1
BSHA=""; BAPP=""; CSHA=""; CAPP=""; GAP=30; WORK=""; OUT=""
DRY=0; SHOW=0; SIM=0; FSIZE=small; FPATH=""; WIDTH=""; LOGGING=off; READY=listener; INSTSTATE=relaunch
ENDPOINT=""; TIMEOUT=300; DEST=""

usage() {
  echo "usage: run-benchmark.sh --mode devicectl|simctl|xctest --device ID --scenarios A,B --blocks N --seed S" >&2
  echo "  --baseline-sha X --baseline-app P --candidate-sha Y --candidate-app P --idle-gap SEC --workdir DIR --out FILE" >&2
  echo "  [--dry-run] [--show-commands] [--simulator] [--fixture-size small] [--fixture-path P] [--width N]" >&2
  echo "  [--logging on|off] [--ready-api on|listener] [--install-state first|relaunch] [--endpoint URL] [--timeout SEC] [--destination D]" >&2
}
die() { echo "run-benchmark: $*" >&2; exit 1; }

while [ $# -gt 0 ]; do
  case "$1" in
    --dry-run) DRY=1; shift; continue;;
    --show-commands) SHOW=1; shift; continue;;
    --simulator) SIM=1; shift; continue;;
    -h|--help) usage; exit 0;;
  esac
  [ $# -ge 2 ] || { usage; die "missing value for $1"; }
  case "$1" in
    --mode) MODE=$2;; --device) DEVICE=$2;; --scenarios) SCENARIOS=$2;; --blocks) BLOCKS=$2;; --seed) SEED=$2;;
    --baseline-sha) BSHA=$2;; --baseline-app) BAPP=$2;; --candidate-sha) CSHA=$2;; --candidate-app) CAPP=$2;;
    --idle-gap) GAP=$2;; --workdir) WORK=$2;; --out) OUT=$2;; --fixture-size) FSIZE=$2;; --fixture-path) FPATH=$2;;
    --width) WIDTH=$2;; --logging) LOGGING=$2;; --ready-api) READY=$2;; --install-state) INSTSTATE=$2;;
    --endpoint) ENDPOINT=$2;; --timeout) TIMEOUT=$2;; --destination) DEST=$2;;
    *) usage; die "unknown option $1";;
  esac
  shift 2
done

case "$MODE" in devicectl|simctl|xctest) ;; *) usage; die "--mode must be devicectl, simctl or xctest";; esac
[ -n "$DEVICE" ] || die "--device is required"
[ -n "$SCENARIOS" ] || die "--scenarios is required"
[ -n "$BSHA" ] && [ -n "$BAPP" ] && [ -n "$CSHA" ] && [ -n "$CAPP" ] || die "baseline and candidate sha and app are required"
[ -n "$WORK" ] || die "--workdir is required"
case "$BLOCKS" in ''|*[!0-9]*) die "--blocks must be a positive integer";; esac
[ "$BLOCKS" -ge 1 ] || die "--blocks must be a positive integer"
case "$SEED" in ''|*[!0-9]*) die "--seed must be a non-negative integer";; esac
if [ $DRY = 0 ]; then
  [ -n "$OUT" ] || die "--out is required"
  [ ! -e "$OUT" ] || die "--out $OUT already exists"
fi

SCEN=()
OLDIFS=$IFS; IFS=,; for s in $SCENARIOS; do SCEN+=("$s"); done; IFS=$OLDIFS
for s in "${SCEN[@]}"; do
  if [ "$s" = D ] && [ -z "$ENDPOINT" ]; then die "scenario D requires --endpoint"; fi
done

# ---- plan ----
PLAN=()   # "W|scenario|role|0" or "M|scenario|role|block"
for s in "${SCEN[@]}"; do PLAN+=("W|$s|baseline|0" "W|$s|candidate|0"); done
BL=()
for s in "${SCEN[@]}"; do b=1; while [ $b -le "$BLOCKS" ]; do BL+=("$s|$b"); b=$((b + 1)); done; done
NB=${#BL[@]}
PERM=$(awk -v n="$NB" -v seed="$SEED" 'BEGIN {
  s = seed; if (s == 0) s = 1
  for (i = 0; i < n; i++) p[i] = i
  for (i = n - 1; i >= 1; i--) { s = (s * 16807) % 2147483647; j = s % (i + 1); t = p[i]; p[i] = p[j]; p[j] = t }
  for (i = 0; i < n; i++) printf "%d ", p[i]
}')
for k in $PERM; do
  sc=${BL[$k]%|*}; bk=${BL[$k]#*|}
  PLAN+=("M|$sc|baseline|$bk" "M|$sc|candidate|$bk" "M|$sc|candidate|$bk" "M|$sc|baseline|$bk")
done
NW=$(( ${#SCEN[@]} * 2 ))
NM=$(( NB * 4 ))

sha_of() { if [ "$1" = baseline ]; then echo "$BSHA"; else echo "$CSHA"; fi; }
app_of() { if [ "$1" = baseline ]; then echo "$BAPP"; else echo "$CAPP"; fi; }

# Sets ARGS (string) and LAUNCH (array of tool args, without the tool name) for one run.
build_launch() { # scenario role idx
  local sha; sha=$(sha_of "$2")
  ARGS="-benchScenario $1 -benchSHA $sha -benchRunIndex $3 -benchFixtureSize $FSIZE"
  [ -n "$FPATH" ] && ARGS="$ARGS -benchFixturePath $FPATH"
  [ -n "$WIDTH" ] && ARGS="$ARGS -benchWidth $WIDTH"
  ARGS="$ARGS -benchLogging $LOGGING -benchReadyAPI $READY -benchInstallState $INSTSTATE -benchIdleGapSeconds $GAP"
  [ -n "$ENDPOINT" ] && ARGS="$ARGS -benchEndpoint $ENDPOINT"
  local nn; nn=$(printf '%03d' "$3")
  case $MODE in
    simctl) LAUNCH=(simctl launch --console --terminate-running-process "$DEVICE" "$BID");;
    devicectl) LAUNCH=(devicectl device process launch --console --terminate-existing --json-output "$WORK/runs/$nn.launch.json" --device "$DEVICE" "$BID");;
    xctest)
      local d=$DEST
      if [ -z "$d" ]; then if [ $SIM = 1 ]; then d="platform=iOS Simulator,id=$DEVICE"; else d="platform=iOS,id=$DEVICE"; fi; fi
      LAUNCH=(test-without-building -xctestrun "$(app_of "$2")" -destination "$d" -only-testing:SplitBenchmark/BenchmarkRunTest/test_runScenarioFromLaunchArguments)
      return;;
  esac
  LAUNCH=("${LAUNCH[@]}" $ARGS)
}

build_install() { # role ; sets INSTALL (empty for xctest)
  local app; app=$(app_of "$1")
  case $MODE in
    simctl) INSTALL=(simctl install "$DEVICE" "$app");;
    devicectl) INSTALL=(devicectl device install app --device "$DEVICE" "$app");;
    xctest) INSTALL=();;
  esac
}

retrieve_display() { # dest
  if [ $MODE = simctl ] || { [ $MODE = xctest ] && [ $SIM = 1 ]; }; then
    echo "cp \"\$(xcrun simctl get_app_container $DEVICE $BID data)/Documents/benchmark.csv\" $1"
  else
    echo "xcrun devicectl device copy from --device $DEVICE --domain-type appDataContainer --domain-identifier $BID --source Documents/benchmark.csv --destination $1"
  fi
}

launch_display() {
  if [ $MODE = xctest ]; then echo "TEST_RUNNER_BENCH_ARGS=\"$ARGS\" xcodebuild ${LAUNCH[*]}"; else echo "xcrun ${LAUNCH[*]}"; fi
}

plan_line() { # idx entry
  local kind sc role blk sha
  IFS='|' read -r kind sc role blk <<EOF2
$2
EOF2
  sha=$(sha_of "$role")
  if [ "$kind" = W ]; then
    printf '%03d WARMUP discarded scenario=%s build=%s sha=%s runIndex=%d\n' "$1" "$sc" "$role" "$sha" "$1"
  else
    printf '%03d MEASURED scenario=%s build=%s sha=%s runIndex=%d block=%d\n' "$1" "$sc" "$role" "$sha" "$1" "$blk"
  fi
}

echo "# plan seed=$SEED mode=$MODE scenarios=$SCENARIOS blocks=$BLOCKS idleGapSeconds=$GAP warmups=$NW measured=$NM"

if [ $DRY = 1 ]; then
  [ $SHOW = 1 ] && echo "    $(retrieve_display "$WORK/runs/000.csv")"
  installed=""; i=1
  for e in "${PLAN[@]}"; do
    plan_line $i "$e"
    if [ $SHOW = 1 ]; then
      IFS='|' read -r kind sc role blk <<EOF2
$e
EOF2
      if [ "$role" != "$installed" ]; then build_install "$role"; [ ${#INSTALL[@]} -gt 0 ] && echo "    xcrun ${INSTALL[*]}"; installed=$role; fi
      build_launch "$sc" "$role" $i
      echo "    $(launch_display)"
      echo "    $(retrieve_display "$WORK/runs/$(printf '%03d' $i).csv")"
    fi
    i=$((i + 1))
  done
  exit 0
fi

# ---- real run ----
XCRUN=${BENCH_XCRUN:-xcrun}
XCODEBUILD=${BENCH_XCODEBUILD:-xcodebuild}
mkdir -p "$WORK/runs" || die "cannot create $WORK/runs"

retrieve() { # dest ; returns nonzero when no CSV exists yet
  local dest=$1 c
  rm -f "$dest"
  if [ $MODE = simctl ] || { [ $MODE = xctest ] && [ $SIM = 1 ]; }; then
    c=$($XCRUN simctl get_app_container "$DEVICE" "$BID" data 2>/dev/null) || return 1
    [ -f "$c/Documents/benchmark.csv" ] || return 1
    cp "$c/Documents/benchmark.csv" "$dest"
  else
    $XCRUN devicectl device copy from --device "$DEVICE" --domain-type appDataContainer --domain-identifier "$BID" \
      --source Documents/benchmark.csv --destination "$dest" >"$dest.log" 2>&1 || { rm -f "$dest"; return 1; }
    [ -f "$dest" ]
  fi
}
now() { perl -MTime::HiRes=time -e 'printf "%.3f\n", time'; }
datarows() { if [ -f "$1" ]; then awk 'NR>1 && NF' "$1" | wc -l | tr -d ' '; else echo 0; fi; }

SEEN=0
if retrieve "$WORK/runs/000.csv"; then SEEN=$(datarows "$WORK/runs/000.csv"); fi
HEADER=""
installed=""; i=1; total=${#PLAN[@]}
for e in "${PLAN[@]}"; do
  IFS='|' read -r kind sc role blk <<EOF2
$e
EOF2
  nn=$(printf '%03d' $i)
  plan_line $i "$e" >&2
  if [ "$role" != "$installed" ]; then
    build_install "$role"
    if [ ${#INSTALL[@]} -gt 0 ]; then
      $XCRUN "${INSTALL[@]}" >"$WORK/runs/$nn.install.log" 2>&1 || die "install failed (see $WORK/runs/$nn.install.log)"
    fi
    installed=$role
  fi
  build_launch "$sc" "$role" $i
  log="$WORK/runs/$nn.console.log"; : > "$log"
  t0=$(now)
  if [ $MODE = xctest ]; then
    TEST_RUNNER_BENCH_ARGS="$ARGS" $XCODEBUILD "${LAUNCH[@]}" >"$log" 2>&1 &
  else
    $XCRUN "${LAUNCH[@]}" >"$log" 2>&1 &
  fi
  LPID=$!
  deadline=$((SECONDS + TIMEOUT)); result=""; why=""
  while :; do
    if grep -q BENCH_ERROR "$log"; then result=error; why=$(grep BENCH_ERROR "$log" | head -1); break; fi
    if [ $MODE != xctest ] && grep -q BENCH_DONE "$log"; then result=done; break; fi
    if ! kill -0 $LPID 2>/dev/null; then
      wait $LPID; rc=$?
      if grep -q BENCH_ERROR "$log"; then result=error; why=$(grep BENCH_ERROR "$log" | head -1)
      elif [ $MODE = xctest ]; then if [ $rc = 0 ]; then result=done; else result=error; why="xcodebuild exited $rc"; fi
      elif grep -q BENCH_DONE "$log"; then result=done
      else result=error; why="launcher exited ($rc) without BENCH_DONE"; fi
      break
    fi
    if [ $SECONDS -ge $deadline ]; then result=timeout; break; fi
    sleep 0.5
  done
  t1=$(now)
  # terminate the app, then the background launcher (by PID only)
  case $MODE in
    simctl) $XCRUN simctl terminate "$DEVICE" "$BID" >/dev/null 2>&1;;
    devicectl)
      pid=$(sed -n 's/.*"processIdentifier"[^0-9]*\([0-9][0-9]*\).*/\1/p' "$WORK/runs/$nn.launch.json" 2>/dev/null | head -1)
      [ -n "$pid" ] && $XCRUN devicectl device process terminate --device "$DEVICE" --pid "$pid" >/dev/null 2>&1;;
  esac
  kill $LPID 2>/dev/null; wait $LPID 2>/dev/null
  [ "$result" = done ] || die "run $nn failed: $result $why (console: $log)"
  wall=$(awk -v a="$t0" -v b="$t1" 'BEGIN { printf "%.3f", b - a }')

  retrieve "$WORK/runs/$nn.csv" || die "run $nn: could not retrieve benchmark.csv"
  hdr=$(head -1 "$WORK/runs/$nn.csv" | tr -d '\r')
  if [ -z "$HEADER" ]; then
    HEADER=$hdr
    echo "$HEADER,runMode,planSeq,buildRole,wallClockSeconds,thermalFlag" > "$OUT"
  elif [ "$hdr" != "$HEADER" ]; then
    die "run $nn: CSV header differs from the first run's header"
  fi
  rm_mode=direct; [ $MODE = xctest ] && rm_mode=xctest
  sha=$(sha_of "$role")
  awk -F, -v skip="$SEEN" -v sha="$sha" -v idx="$i" -v mode="$rm_mode" -v seq="$i" -v role="$role" -v wall="$wall" '
    NR == 1 { for (k = 1; k <= NF; k++) col[$k] = k; cs = col["sha"]; ci = col["runIndex"]; tb = col["thermalStateBefore"]; ta = col["thermalStateAfter"]
              if (!cs || !ci) { print "CSV lacks sha or runIndex column" > "/dev/stderr"; exit 3 }; next }
    { sub(/\r$/, "") }
    NF == 0 { next }
    { n++; if (n <= skip) next; got++
      if ($cs != sha || $ci != idx) { printf "new row has sha=%s runIndex=%s, expected sha=%s runIndex=%s\n", $cs, $ci, sha, idx > "/dev/stderr"; bad = 1 }
      flag = "unknown"
      if (tb && ta) { flag = ($tb == "nominal" && $ta == "nominal") ? "ok" : "NOT_NOMINAL" }
      if (flag == "NOT_NOMINAL") printf "warning: runIndex %s thermal state not nominal (before=%s after=%s)\n", idx, $tb, $ta > "/dev/stderr"
      print $0 "," mode "," seq "," role "," wall "," flag }
    END { if (!got) { print "no new CSV rows for this run" > "/dev/stderr"; exit 4 } if (bad) exit 5 }
  ' "$WORK/runs/$nn.csv" > "$WORK/runs/$nn.rows.csv" || die "run $nn: row extraction or validation failed"
  SEEN=$(datarows "$WORK/runs/$nn.csv")
  [ "$kind" = M ] && cat "$WORK/runs/$nn.rows.csv" >> "$OUT"
  if [ $i -lt $total ] && [ "$GAP" != 0 ]; then sleep "$GAP"; fi
  i=$((i + 1))
done
echo "done: $OUT" >&2
exit 0
