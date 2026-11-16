# FME-22007 baseline report (issue 32 fills this in)

Spec: docs/specs/fme-22007-multi-factory-ready-from-cache.md, sections 4.1 R12 R13 R17 R19, 6.1 to 6.5, 8 step 1b, and the 2026-11-13 amendments.
Fill every field. Write `not recorded: <reason>` for a field you cannot fill; never delete a field and never leave one blank.
Simulator numbers are not acceptance evidence. Device numbers are relative only (compare builds with each other, never quote them as absolute figures for the customer's phone).

## 1. Identity of the run
| Field | Value |
|---|---|
| Report date | |
| Baseline build SHA (Release, logging-off) | |
| Baseline build SHA (Release, logging-on, stage marks) | |
| Candidate SHA (if any; baseline-only report: none) | |
| Device model (D7) | |
| iOS version | |
| Xcode version | |
| Battery level and charging state, start and end of the session | |
| Low Power Mode state (must be off) | |
| Install-state class of the session (first launch after install, or relaunch; amendments) | |
| Fixture seed | |
| Fixture hash | |
| Fixture parameters F (flags), S (sets, flags per set), B (bytes per flag) from D7 | |
| Driver invocation (exact `scripts/benchmark/run-benchmark.sh` command line) | |
| Analysis invocation (`scripts/benchmark/analyze.sh <csv> [minRuns]` or the issue-33 tool) | |
| Committed raw CSV path(s), one per build variant and scenario set | |

## 2. Protocol statements (amendments)
| Field | Value |
|---|---|
| Run mode (direct launch primary, or XCTest fallback) and the harness gap statement: what the fallback path adds or hides versus direct launch | |
| Fixed idle gap between runs (seconds) | |
| Ready-callback API pinned (listener or readyFromCache API) | |
| Order: randomised interleaved ABBA blocks, seed, block count | |
| Warm-up: one per installed build, discarded, never in the CSV | |
| Wall clock per run recorded (column wallClockStart): yes or no | |
| Minimum runs per scenario (50 required; 30 only if the amendments were relaxed by the owner, cite the ruling) | |
| Release configuration confirmed for every build | |
| Statement: device numbers are relative only | |
| Fast-phone caveat: a flat result on a fast phone does not clear the customer hypothesis; state the phone class and say so | |
| Statement: scenario D is not used to explain the customer's cold figure (R11 note, U7, N4) | |

## 3. Thermal
| Field | Value |
|---|---|
| Thermal state before the session | |
| Thermal state after the session | |
| Per run: thermalStateBefore and thermalStateAfter columns checked; count of runs with a state other than nominal before or after | |
| Runs excluded for thermal state (count and run indices) | |
| Drift slope per build and scenario (ms per hour, from the analysis) | |

## 4. Logging on versus logging off
| Scenario | median logging-off (ms) | median logging-on (ms) | gap on minus off (ms) |
|---|---|---|---|
| A | | | |
| B | | | |
| C | | | |
| C2 | | | |
| D | | | |
| E | | | |
| C-bg | | | |
| stress 2x | | | |
| stress 4x | | | |

R13 compares a logging-on stage sum with a logging-on total. R14 to R16 use logging-off totals.

## 5. Per-scenario totals (T11 minus T0, primary runs only: warm cache hit, thermal nominal, not first install)
One row per scenario and build variant. Scenarios: A, B (per factory), C (per factory and both-ready), C2, D (cold, reported separately), E, C-bg, stress 2x, stress 4x. Stress and C-bg results are required rows, not optional.
| Scenario | Variant | Factory | Runs total | Primary runs | Median (ms) | p90 (ms) | Min (ms) | Max (ms) | R17 distance from 50 ms (median minus 50, ms) |
|---|---|---|---|---|---|---|---|---|---|
| | | | | | | | | | |

R17 is reported for every row and is not a gate unless D6 sets one.
Insufficient-run flags from the analysis (fewer than the minimum primary runs): list scenario and count, or `none`.

## 6. R19 run classes
For every scenario and variant, the class of every run, plus the counts below. The full per-run listing is the analysis output pasted under section 12.
| Scenario | Variant | warm cache hit | flagSpec or filter change | first-run forceParsing | cache miss | more than one decode | first launch after install | class unknown |
|---|---|---|---|---|---|---|---|---|
| | | | | | | | | |

Non-warm classes are reported separately and are never dropped silently (D9(a)).

## 7. R13 stage attribution (per scenario and chain)
| Scenario | Chain (warm or cold) | Runs | Runs with all chain marks present | Failed runs (index and missing marks) | Median total (ms) | Sum of stage medians (ms) | Tolerance max(10% of median total, 1 ms per mark) (ms) | Pass |
|---|---|---|---|---|---|---|---|---|
| | | | | | | | | |

Stage medians and shares per scenario (mark pairs on the chain, ms and share of the median total; below 1 ms is unresolved):
| Scenario | Stage | Median (ms) | Share | Unresolved (<1 ms) |
|---|---|---|---|---|
| | | | | |

Decode share (R18, summed T6 intervals over T11 minus T0), median per scenario: ____ . Compare with the D6 trigger: ____ .

## 8. Decision values (D6, D5)
D6 values are set by the human owner after the baseline exists. The analysis has no default for the noisy-baseline limit; the value used is recorded here.
| Field | Value |
|---|---|
| D6 regression threshold (ms) | |
| D6 improvement threshold (ms) | |
| D6 millisecond floor (default 1.0 in the analysis) | |
| D6 maximum baseline CI half-width, percent of median (maxHalfWidthPercent; issue 33 fixes it) | |
| D6 lazy-decode trigger (decode share) | |
| D6 whether 50 ms becomes a gate | |
| Rule used to derive each value above (quote the ruling and where it is recorded) | |
| Noisy-baseline check result per scenario (half-width ms, percent, rejected or accepted) | |
| Bootstrap: paired block bootstrap, percentile, resamples, seed | |

## 9. D5 width sweep (scenarios A and C)
Width is a fraction of processorCount with a floor (amendments). Floor rule used: ____ .
Processor count of the device: ____ .
| Scenario | Width (fraction) | Width (concrete, after floor) | Runs | Median (ms) | p90 (ms) | Both-ready median (C only, ms) | Floor applied |
|---|---|---|---|---|---|---|---|
| A | | | | | | | |
| C | | | | | | | |

Chosen width and why: ____ .

## 10. Encryption statement (U6)
State whether the storage under test was encrypted or not during the runs, the setting used, and how it was confirmed: ____ .

## 11. Limits and caveats
List: scenarios not run, runs that failed, any harness gap (section 2), any deviation from the protocol, and a one-line reading of the result stated as relative only.

## 12. Attachments
- Raw CSV paths (committed): ____
- Analysis output verbatim (includes the label of every run): ____
- Driver plan output and run log: ____
