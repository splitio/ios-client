# Cloud Agent environment (Linux)

This repository’s primary build and test flow uses **Xcode on macOS** (`xcodebuild`, simulators). Cloud Agents run on Linux, so this environment focuses on what is practical without Apple SDKs:

- Swift 6 toolchain and SwiftLint
- SPM builds for portable internal modules (`SplitLogging`, `SplitConcurrency`, etc.)
- `scripts/check_old_target_names`
- A small `SplitLogging` smoke binary (`.cursor/linux-smoke/`)

**On macOS with Xcode:** use Product → Build/Test in Xcode or the GitHub Actions / Harness CI pipelines as documented in `CONTRIBUTORS-GUIDE.md`.

**Verify locally (Linux):** `bash .cursor/cloud-agent-verify.sh`

**Note:** Full SDK builds, iOS simulators, and `xcodebuild test` require a macOS runner; they are not part of this Linux environment.
