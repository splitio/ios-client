#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO_ROOT"
if [ -x /opt/swift/usr/bin/swift ]; then
  export PATH="/opt/swift/usr/bin:/usr/local/bin:${PATH}"
elif [ -x /usr/local/swift/bin/swift ]; then
  export PATH="/usr/local/swift/bin:/usr/local/bin:${PATH}"
else
  export PATH="/usr/local/bin:${PATH}"
fi

echo "== check_old_target_names =="
./scripts/check_old_target_names

echo "== SplitLogging SPM tests (compile) =="
swift build --target SplitLoggingTests

echo "== SplitLogging smoke (runtime) =="
swift run --package-path .cursor/linux-smoke --skip-build 2>/dev/null \
  || swift run --package-path .cursor/linux-smoke

echo "== SwiftLint (portable module sources, excluding Tests/) =="
mapfile -t PORTABLE_SWIFT < <(find Sources/Logging Sources/Concurrency Sources/BackoffCounter \
  Sources/PeriodicRecorderWorker Sources/Tracker -name '*.swift' ! -path '*/Tests/*')
swiftlint lint --quiet --config .cursor/swiftlint-portable.yml --lenient "${PORTABLE_SWIFT[@]}"

echo "cloud-agent-verify: OK"
