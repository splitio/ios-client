#!/usr/bin/env python3
"""Rebalance Xcode .xctestplan files into a disjoint, evenly-sized partition.

Discovers all XCTestCase methods under SplitTests/, keeps flaky tests in
SplitFlakyTests, and greedily packs the remainder into the 14 matrix shards.
Only mutates skippedTests on the 15 matrix plans; both Swift5 and Swift6
targets receive identical skip lists.
"""

from __future__ import annotations

import json
import re
import sys
from collections import defaultdict
from pathlib import Path
from typing import Dict, Iterable, List, Optional, Set, Tuple

REPO_ROOT = Path(__file__).resolve().parent.parent
SPLIT_TESTS = REPO_ROOT / "SplitTests"

MATRIX_PLANS: List[str] = [
    "SplitiOSIntegration",
    "SplitiOSIntegration_1",
    "SplitiOSStreaming",
    "SplitiOSStreaming_1",
    "SplitiOSStreaming_2",
    "SplitiOSUnit",
    "SplitiOSUnit_1",
    "SplitiOSUnit_2",
    "SplitiOSUnit_3",
    "SplitiOSUnit_4",
    "SplitiOSUnit_5",
    "SemVer",
    "SplitPushManagerUT",
    "SplitStreamingUT",
    "SplitFlakyTests",
]

NON_FLAKY_PLANS: List[str] = [p for p in MATRIX_PLANS if p != "SplitFlakyTests"]
FLAKY_PLAN = "SplitFlakyTests"
FULL_PLAN = "SplitiOSFull"
SWIFT5_TARGET = "SplitTestsSwift5"
FLAKY_FORCE_CLASS = "ImpressionsPropertiesE2ETest"

# Classes deliberately excluded from EVERY matrix plan. These are not silent
# drops: they are listed here, reported on every run, and excluded from the
# exact-cover invariant on purpose. They still run in SplitiOSFull.
# ImpressionsPropertiesE2ETest drives two clients against one SQLite file and
# is not CI friendly (CoreData I/O errors, flaky under concurrency debug).
EXCLUDED_CLASSES = {
    "ImpressionsPropertiesE2ETest",
}

# class Foo: XCTestCase  /  final class Foo: Bar, XCTestCase  etc.
CLASS_RE = re.compile(
    r"(?m)^[ \t]*(?:(?:open|final|public|internal|private|fileprivate)\s+)*"
    r"class\s+(\w+)\s*:[^{]*\bXCTestCase\b"
)
# func testSomething(  — allow attributes / access modifiers on prior tokens of the line
FUNC_RE = re.compile(
    r"(?m)^[ \t]*(?:(?:override|public|internal|private|fileprivate|open)\s+)*"
    r"func\s+(test\w*)\s*\("
)


def method_key(class_name: str, method_name: str) -> str:
    if method_name.endswith("()"):
        return f"{class_name}/{method_name}"
    return f"{class_name}/{method_name}()"


def discover_universe(root: Path) -> Tuple[Set[str], Dict[str, Set[str]]]:
    """Walk SplitTests/**/*.swift and collect Class/testMethod() keys.

    A file may contain multiple XCTestCase subclasses. Methods are attributed
    to the class they are lexically inside by tracking brace depth.
    """
    universe: Set[str] = set()
    by_class: Dict[str, Set[str]] = defaultdict(set)

    for path in sorted(root.rglob("*.swift")):
        text = path.read_text(encoding="utf-8", errors="ignore")
        class_starts = [(m.start(), m.group(1)) for m in CLASS_RE.finditer(text)]
        if not class_starts:
            continue

        for idx, (start, class_name) in enumerate(class_starts):
            # Restrict search window to this class's declaration until the next
            # XCTestCase class (helps nested / multi-class files).
            end = class_starts[idx + 1][0] if idx + 1 < len(class_starts) else len(text)
            region = text[start:end]

            brace_start = region.find("{")
            if brace_start < 0:
                continue

            # Extract class body via brace matching within the region.
            depth = 0
            body_start = brace_start + 1
            body_end: Optional[int] = None
            j = brace_start
            while j < len(region):
                ch = region[j]
                if ch == "{":
                    depth += 1
                elif ch == "}":
                    depth -= 1
                    if depth == 0:
                        body_end = j
                        break
                j += 1
            if body_end is None:
                body = region[body_start:]
            else:
                body = region[body_start:body_end]

            # Attribute top-level methods (brace depth 0 relative to class body).
            bd = 0
            k = 0
            while k < len(body):
                ch = body[k]
                if ch == "{":
                    bd += 1
                    k += 1
                    continue
                if ch == "}":
                    bd -= 1
                    k += 1
                    continue
                if bd == 0:
                    m = FUNC_RE.match(body, k)
                    if m:
                        key = method_key(class_name, m.group(1))
                        universe.add(key)
                        by_class[class_name].add(key)
                        k = m.end()
                        continue
                k += 1

    return universe, dict(by_class)


def plan_path(name: str) -> Path:
    return REPO_ROOT / f"{name}.xctestplan"


def load_plan(name: str) -> dict:
    with plan_path(name).open(encoding="utf-8") as f:
        return json.load(f)


def get_target(plan: dict, target_name: str) -> dict:
    for t in plan["testTargets"]:
        if t.get("target", {}).get("name") == target_name:
            return t
    raise KeyError(f"target {target_name!r} not found")


def get_skipped(plan: dict, target_name: str = SWIFT5_TARGET) -> List[str]:
    return list(get_target(plan, target_name).get("skippedTests", []))


def class_of(method: str) -> str:
    return method.split("/", 1)[0]


def enabled_from_skips(universe: Set[str], skipped: Iterable[str]) -> Set[str]:
    """Evaluate enabled set: everything in U not covered by the skip list."""
    skipped_classes: Set[str] = set()
    skipped_methods: Set[str] = set()
    for entry in skipped:
        if "/" in entry:
            # Normalize trailing ()
            if not entry.endswith("()"):
                entry = entry + "()"
            skipped_methods.add(entry)
        else:
            skipped_classes.add(entry)

    enabled: Set[str] = set()
    for method in universe:
        cls = class_of(method)
        if cls in skipped_classes:
            continue
        if method in skipped_methods:
            continue
        enabled.add(method)
    return enabled


def collect_skip_references(plan_names: Iterable[str]) -> Tuple[Set[str], Set[str]]:
    """Return (referenced_classes, referenced_Class/method() entries)."""
    classes: Set[str] = set()
    methods: Set[str] = set()
    for name in plan_names:
        plan = load_plan(name)
        # Union refs from both targets (should be identical, but be thorough).
        for t in plan["testTargets"]:
            for entry in t.get("skippedTests", []):
                if "/" in entry:
                    cls = entry.split("/", 1)[0]
                    classes.add(cls)
                    if not entry.endswith("()"):
                        entry = entry + "()"
                    methods.add(entry)
                else:
                    classes.add(entry)
    return classes, methods


def sanity_cross_check(
    universe: Set[str],
    by_class: Dict[str, Set[str]],
    plan_names: List[str],
) -> Tuple[Set[str], Set[str]]:
    ref_classes, ref_methods = collect_skip_references(plan_names)
    known_classes = set(by_class.keys())

    unknown_classes = sorted(ref_classes - known_classes)
    unknown_methods = sorted(
        m for m in ref_methods if class_of(m) in known_classes and m not in universe
    )

    if unknown_classes:
        print("WARNING: unknown classes referenced in skippedTests:")
        for c in unknown_classes:
            print(f"  - {c}")
    if unknown_methods:
        print("WARNING: unknown methods referenced in skippedTests:")
        for m in unknown_methods:
            print(f"  - {m}")

    if ref_classes:
        ratio = len(unknown_classes) / len(ref_classes)
        if ratio > 0.25:
            print(
                f"ERROR: unknown classes are {ratio:.1%} of referenced classes "
                f"({len(unknown_classes)}/{len(ref_classes)}); discovery likely broken.",
                file=sys.stderr,
            )
            sys.exit(1)

    return set(unknown_classes), set(unknown_methods)


def compute_excluded(by_class: Dict[str, Set[str]]) -> Set[str]:
    """Methods of EXCLUDED_CLASSES: run in no matrix plan, by explicit choice."""
    excluded: Set[str] = set()
    for class_name in sorted(EXCLUDED_CLASSES):
        methods = by_class.get(class_name)
        if not methods:
            print(
                f"ERROR: EXCLUDED_CLASSES lists {class_name!r} but no such test "
                f"class was discovered; remove it or fix the name.",
                file=sys.stderr,
            )
            sys.exit(1)
        excluded |= methods
    return excluded


def compute_flaky_set(
    universe: Set[str],
    by_class: Dict[str, Set[str]],
    excluded: Set[str],
) -> Set[str]:
    plan = load_plan(FLAKY_PLAN)
    skipped = get_skipped(plan, SWIFT5_TARGET)
    currently_enabled = enabled_from_skips(universe, skipped)
    flaky = (currently_enabled | set(by_class.get(FLAKY_FORCE_CLASS, set()))) - excluded
    if not flaky.issubset(universe):
        extra = flaky - universe
        print(f"ERROR: flaky set not subset of U: {sorted(extra)}", file=sys.stderr)
        sys.exit(1)
    return flaky


def pack_classes(
    remainder: Set[str],
    by_class: Dict[str, Set[str]],
    bin_names: List[str],
) -> Dict[str, Set[str]]:
    """Largest-first greedy bin packing of whole classes into bins."""
    # Only classes that contribute methods to remainder.
    class_to_methods: Dict[str, Set[str]] = {}
    for method in remainder:
        class_to_methods.setdefault(class_of(method), set()).add(method)

    # Sanity: every remainder method must belong to a known class group.
    assigned_check = set().union(*class_to_methods.values()) if class_to_methods else set()
    if assigned_check != remainder:
        missing = remainder - assigned_check
        print(f"ERROR: methods not grouped by class: {sorted(missing)}", file=sys.stderr)
        sys.exit(1)

    bins: Dict[str, Set[str]] = {name: set() for name in bin_names}
    bin_sizes: Dict[str, int] = {name: 0 for name in bin_names}

    classes_sorted = sorted(
        class_to_methods.items(),
        key=lambda kv: (-len(kv[1]), kv[0]),
    )

    for class_name, methods in classes_sorted:
        # Place into the bin with fewest methods; tie-break by plan order.
        target = min(bin_names, key=lambda n: (bin_sizes[n], bin_names.index(n)))
        bins[target].update(methods)
        bin_sizes[target] += len(methods)

    all_assigned = set().union(*bins.values()) if bins else set()
    if all_assigned != remainder:
        missing = remainder - all_assigned
        extra = all_assigned - remainder
        print("ERROR: packing left methods unassigned or over-assigned.", file=sys.stderr)
        if missing:
            print(f"  missing: {sorted(missing)}", file=sys.stderr)
        if extra:
            print(f"  extra: {sorted(extra)}", file=sys.stderr)
        sys.exit(1)

    return bins


def derive_skip_list(
    owned: Set[str],
    universe: Set[str],
    by_class: Dict[str, Set[str]],
    stale_entries: Iterable[str],
) -> List[str]:
    """Build skippedTests for a plan that owns `owned` methods from U."""
    skips: Set[str] = set()
    owned_by_class: Dict[str, Set[str]] = defaultdict(set)
    for m in owned:
        owned_by_class[class_of(m)].add(m)

    for class_name, methods in by_class.items():
        # Excluded classes are skipped in every plan, as a bare class entry.
        if class_name in EXCLUDED_CLASSES:
            skips.add(class_name)
            continue
        owned_methods = owned_by_class.get(class_name, set())
        if not owned_methods:
            skips.add(class_name)
        else:
            for m in methods:
                if m not in owned_methods:
                    skips.add(m)

    # Preserve stale references verbatim.
    for entry in stale_entries:
        skips.add(entry)

    return sorted(skips)


def collect_stale_entries_for_plan(
    plan_name: str,
    universe: Set[str],
    by_class: Dict[str, Set[str]],
) -> List[str]:
    """Pre-existing skip entries that reference classes/methods unknown to U."""
    plan = load_plan(plan_name)
    known_classes = set(by_class.keys())
    stale: Set[str] = set()
    for t in plan["testTargets"]:
        for entry in t.get("skippedTests", []):
            if "/" in entry:
                cls = entry.split("/", 1)[0]
                normalized = entry if entry.endswith("()") else entry + "()"
                if cls not in known_classes or normalized not in universe:
                    stale.add(entry)  # keep original spelling
            else:
                if entry not in known_classes:
                    stale.add(entry)
    return sorted(stale)


def assert_partition(
    ownership: Dict[str, Set[str]],
    universe: Set[str],
    check_balance: bool,
) -> None:
    """Assert coverage, disjointness, ownership==1, and optional balance."""
    all_enabled: Set[str] = set()
    ownership_count: Dict[str, int] = defaultdict(int)
    duplicates: Dict[str, List[str]] = defaultdict(list)

    for plan_name, enabled in ownership.items():
        for m in enabled:
            ownership_count[m] += 1
            duplicates[m].append(plan_name)
        all_enabled |= enabled

    missing = sorted(universe - all_enabled)
    extras = sorted(all_enabled - universe)
    duplicated = sorted(m for m, c in ownership_count.items() if c != 1)

    # Pairwise intersections
    names = list(ownership.keys())
    pairwise: List[str] = []
    for i in range(len(names)):
        for j in range(i + 1, len(names)):
            inter = ownership[names[i]] & ownership[names[j]]
            if inter:
                pairwise.append(
                    f"{names[i]} ∩ {names[j]} = {len(inter)} "
                    f"(e.g. {sorted(inter)[:3]})"
                )

    failed = False
    if missing:
        failed = True
        print(f"ASSERT FAIL: {len(missing)} methods missing from union:", file=sys.stderr)
        for m in missing[:50]:
            print(f"  - {m}", file=sys.stderr)
        if len(missing) > 50:
            print(f"  ... and {len(missing) - 50} more", file=sys.stderr)
    if extras:
        failed = True
        print(f"ASSERT FAIL: {len(extras)} methods outside U:", file=sys.stderr)
        for m in extras[:50]:
            print(f"  - {m}", file=sys.stderr)
    if duplicated or pairwise:
        failed = True
        print(
            f"ASSERT FAIL: {len(duplicated)} methods with ownership != 1:",
            file=sys.stderr,
        )
        for m in duplicated[:50]:
            print(f"  - {m} owned by {duplicates[m]}", file=sys.stderr)
        for line in pairwise[:20]:
            print(f"  pairwise: {line}", file=sys.stderr)

    if check_balance:
        shard_sizes = [len(ownership[n]) for n in NON_FLAKY_PLANS]
        if shard_sizes:
            mean = sum(shard_sizes) / len(shard_sizes)
            lo = mean * 0.85
            hi = mean * 1.15
            outliers = [
                (n, len(ownership[n]))
                for n in NON_FLAKY_PLANS
                if not (lo <= len(ownership[n]) <= hi)
            ]
            if outliers:
                failed = True
                print(
                    f"ASSERT FAIL: shard sizes outside ±15% of mean {mean:.2f} "
                    f"[{lo:.2f}, {hi:.2f}]:",
                    file=sys.stderr,
                )
                for n, sz in outliers:
                    print(f"  - {n}: {sz}", file=sys.stderr)

    # Exact ownership count check over U
    bad = [m for m in universe if ownership_count[m] != 1]
    if bad and not duplicated:
        # already reported via duplicated if they appear in enabled sets
        failed = True
        print(
            f"ASSERT FAIL: {len(bad)} U methods without ownership count 1",
            file=sys.stderr,
        )

    if failed:
        sys.exit(1)


def write_plan(name: str, plan: dict, skip_list: List[str]) -> None:
    for t in plan["testTargets"]:
        t["skippedTests"] = list(skip_list)
    path = plan_path(name)
    text = json.dumps(plan, indent=2, separators=(",", " : "), sort_keys=False)
    path.write_text(text + "\n", encoding="utf-8")


def report(
    universe: Set[str],
    by_class: Dict[str, Set[str]],
    flaky: Set[str],
    ownership: Dict[str, Set[str]],
    excluded: Set[str],
) -> None:
    print(f"|U| = {len(universe)}")
    print(f"classes = {len(by_class)}")
    if excluded:
        print()
        print(
            f"EXCLUDED from all matrix plans on purpose: {len(excluded)} methods "
            f"in {sorted(EXCLUDED_CLASSES)}"
        )
        for m in sorted(excluded):
            print(f"  (not run) {m}")
        print(f"covered by matrix = {len(universe) - len(excluded)}")
        print()
    print(f"|F| = {len(flaky)}")
    print("Flaky methods:")
    for m in sorted(flaky):
        print(f"  {m}")
    print()
    print(f"{'plan':<28} {'enabled':>8}")
    print("-" * 38)
    for name in MATRIX_PLANS:
        print(f"{name:<28} {len(ownership[name]):>8}")
    shard_sizes = [len(ownership[n]) for n in NON_FLAKY_PLANS]
    mean = sum(shard_sizes) / len(shard_sizes)
    print()
    print(
        f"shard sizes (14 non-flaky): min={min(shard_sizes)} "
        f"max={max(shard_sizes)} mean={mean:.2f}"
    )
    print("OK")


def main() -> int:
    # 1. Discover universe
    universe, by_class = discover_universe(SPLIT_TESTS)
    if not universe:
        print("ERROR: discovered universe U is empty", file=sys.stderr)
        return 1

    # 2. Sanity cross-check
    sanity_cross_check(universe, by_class, MATRIX_PLANS + [FULL_PLAN])

    # 3. Explicit exclusions, then flaky set
    excluded = compute_excluded(by_class)
    # Coverage is asserted against everything except the explicit exclusions.
    universe_covered = universe - excluded
    flaky = compute_flaky_set(universe, by_class, excluded)

    # 4. Remainder + pack
    remainder = universe_covered - flaky
    bins = pack_classes(remainder, by_class, NON_FLAKY_PLANS)
    ownership: Dict[str, Set[str]] = {name: set(methods) for name, methods in bins.items()}
    ownership[FLAKY_PLAN] = set(flaky)

    # 5. Derive skip lists (including stale preservation)
    derived_skips: Dict[str, List[str]] = {}
    for name in MATRIX_PLANS:
        stale = collect_stale_entries_for_plan(name, universe, by_class)
        derived_skips[name] = derive_skip_list(
            ownership[name], universe, by_class, stale
        )

    # Pre-write: evaluate enabled from derived skips and assert
    pre_enabled = {
        name: enabled_from_skips(universe, derived_skips[name]) for name in MATRIX_PLANS
    }
    # Ensure derived enabled matches intended ownership
    for name in MATRIX_PLANS:
        if pre_enabled[name] != ownership[name]:
            only_derived = sorted(pre_enabled[name] - ownership[name])
            only_owned = sorted(ownership[name] - pre_enabled[name])
            print(
                f"ERROR: derived enabled != ownership for {name}",
                file=sys.stderr,
            )
            if only_derived:
                print(f"  only in derived: {only_derived[:20]}", file=sys.stderr)
            if only_owned:
                print(f"  only in ownership: {only_owned[:20]}", file=sys.stderr)
            return 1

    assert_partition(pre_enabled, universe_covered, check_balance=True)

    # 7. Write
    for name in MATRIX_PLANS:
        plan = load_plan(name)
        write_plan(name, plan, derived_skips[name])

    # 8. Post-write verification
    post_enabled: Dict[str, Set[str]] = {}
    for name in MATRIX_PLANS:
        plan = load_plan(name)
        skips5 = get_skipped(plan, SWIFT5_TARGET)
        # Both targets must be identical
        for t in plan["testTargets"]:
            if t.get("skippedTests") != skips5:
                print(
                    f"ERROR: skippedTests mismatch between targets in {name}",
                    file=sys.stderr,
                )
                return 1
        post_enabled[name] = enabled_from_skips(universe, skips5)

    assert_partition(post_enabled, universe_covered, check_balance=True)

    # 9. Report
    report(universe, by_class, flaky, post_enabled, excluded)
    return 0


if __name__ == "__main__":
    sys.exit(main())
