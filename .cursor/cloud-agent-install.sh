#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO_ROOT"

chmod +x scripts/check_old_target_names scripts/check_package_resolution 2>/dev/null || true

if [ -x /opt/swift/usr/bin/swift ]; then
  export PATH="/opt/swift/usr/bin:/usr/local/bin:${PATH}"
elif [ -x /usr/local/swift/bin/swift ]; then
  export PATH="/usr/local/swift/bin:/usr/local/bin:${PATH}"
else
  export PATH="/usr/local/bin:${PATH}"
fi

swift --version
swiftlint version

swift package resolve

SMOKE_VENDOR="$REPO_ROOT/.cursor/linux-smoke/Vendor/SplitLogging"
mkdir -p "$(dirname "$SMOKE_VENDOR")"
ln -sfn "$REPO_ROOT/Sources/Logging" "$SMOKE_VENDOR"

PORTABLE_TARGETS=(
  SplitLogging
  SplitConcurrency
  SplitBackoffCounter
  SplitPeriodicRecorderWorker
  SplitTracker
)

for target in "${PORTABLE_TARGETS[@]}"; do
  swift build --target "$target"
done

swift build --package-path .cursor/linux-smoke
