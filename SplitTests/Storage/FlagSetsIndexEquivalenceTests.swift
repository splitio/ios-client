//
//  FlagSetsIndexEquivalenceTests.swift
//  SplitTests
//
//  Pins the observable behaviour of the flag-set index (DefaultFlagSetsCache fed
//  by DefaultSplitsStorage) so a later change of its internal structure can be
//  proven equivalent. Everything goes through the public API of the cache
//  (getFeatureFlagNamesBySet, getFeatureFlagNames(forFlagSets:)) and is compared
//  after EVERY step against `FlagSetsIndexOracle`, an independent plain-dictionary
//  model of the documented semantics:
//
//  - add: insert the name into each of flag.sets that passes the filter (nil
//    filter = all), then remove the name from every other set of the index
//    (nil sets = empty). The name is used as given (case preserved).
//  - remove(sets): remove from the given sets, or from ALL sets when empty.
//  - a set with no members does not exist in the index.
//  - storage: processUpdated looks the previous flag up by lowercased name in
//    memory; active -> add; archived and not in memory -> nothing; archived and
//    in memory -> remove(filter ?? []). loadLocal = active then archived.
//    clear() empties memory but not the index; updateWithoutChecks touches
//    memory only.
//

import XCTest
@testable import Split

// MARK: Oracle

struct FlagSetsIndexOracle {
    let filter: Set<String>?
    private(set) var index = [String: Set<String>]()
    // Storage model: lowercased name -> sets of the flag held in memory
    private(set) var memory = [String: Set<String>]()

    init(filter: Set<String>?) {
        self.filter = filter
    }

    // Cache level
    mutating func add(name: String, sets: Set<String>?) {
        for set in sets ?? [] where filter == nil || filter!.contains(set) {
            index[set, default: []].insert(name)
        }
        let own = sets ?? []
        for key in Array(index.keys) where !own.contains(key) {
            index[key]?.remove(name)
        }
        dropEmpty()
    }

    mutating func remove(name: String, sets: Set<String>) {
        let targets = sets.isEmpty ? Set(index.keys) : sets
        for key in targets {
            index[key]?.remove(name)
        }
        dropEmpty()
    }

    // Storage level
    mutating func process(_ splits: [Split], active: Bool) {
        var local = memory
        for split in splits {
            let name = split.name!
            let loaded = local[name.lowercased()]
            if loaded == nil, !active { continue }
            if active {
                local[name.lowercased()] = split.sets ?? []
                add(name: name, sets: split.sets)
            } else {
                local.removeValue(forKey: name.lowercased())
                remove(name: name, sets: filter ?? [])
            }
        }
        memory = local
    }

    mutating func loadLocal(_ splits: [Split]) {
        process(splits.filter { $0.status == .active }, active: true)
        process(splits.filter { $0.status == .archived }, active: false)
    }

    mutating func update(active: [Split], archived: [Split]) {
        process(active, active: true)
        process(archived, active: false)
    }

    mutating func clearStorage() {
        memory.removeAll()
    }

    mutating func updateWithoutChecks(_ split: Split) {
        memory[split.name!.lowercased()] = split.sets ?? []
    }

    private mutating func dropEmpty() {
        index = index.filter { !$0.value.isEmpty }
    }
}

// MARK: Deterministic pseudo random

struct SeededGenerator {
    private var state: UInt64
    init(seed: UInt64) { state = seed }
    mutating func next() -> UInt64 {
        state &+= 0x9E3779B97F4A7C15
        var z = state
        z = (z ^ (z >> 30)) &* 0xBF58476D1CE4E5B9
        z = (z ^ (z >> 27)) &* 0x94D049BB133111EB
        return z ^ (z >> 31)
    }
    mutating func next(below n: Int) -> Int { Int(next() % UInt64(n)) }
}

// MARK: Harness

final class IndexHarness {
    let cache: DefaultFlagSetsCache
    let persistent = PersistentSplitsStorageStub()
    let storage: DefaultSplitsStorage
    var oracle: FlagSetsIndexOracle
    private(set) var universe = Set<String>()

    init(filter: Set<String>?) {
        cache = FlagSetsIndexEquivalenceTests.makeCache(filter: filter)
        oracle = FlagSetsIndexOracle(filter: filter)
        storage = DefaultSplitsStorage(persistentSplitsStorage: persistent,
                                       flagSetsCache: cache,
                                       generalInfoStorage: GeneralInfoStorageMock(),
                                       persistenceBreaker: DefaultPersistenceBreaker())
    }

    private func track(_ splits: [Split]) {
        splits.forEach { universe.formUnion($0.sets ?? []) }
    }

    func cacheAdd(_ split: Split, step: String = "", file: StaticString = #filePath, line: UInt = #line) {
        track([split])
        cache.addToFlagSets(split)
        oracle.add(name: split.name!, sets: split.sets)
        assertMatches(step, file: file, line: line)
    }

    func cacheRemove(_ name: String, sets: Set<String>, step: String = "",
                     file: StaticString = #filePath, line: UInt = #line) {
        universe.formUnion(sets)
        cache.removeFromFlagSets(featureFlagName: name, sets: sets)
        oracle.remove(name: name, sets: sets)
        assertMatches(step, file: file, line: line)
    }

    typealias BatchItem = (flag: Split, previousSets: Set<String>?)

    /// Drives the batch API of the cache directly. The oracle applies the same flags as sequential
    /// single `add` calls, which is the behaviour a batch must be equivalent to.
    func cacheBatch(_ items: [BatchItem], usePreviousSets: Bool, step: String = "",
                    file: StaticString = #filePath, line: UInt = #line) {
        items.forEach {
            track([$0.flag])
            universe.formUnion($0.previousSets ?? [])
        }
        cache.addToFlagSets(items, usePreviousSets: usePreviousSets)
        items.forEach { oracle.add(name: $0.flag.name!, sets: $0.flag.sets) }
        assertMatches(step, file: file, line: line)
    }

    func destroyStorage(step: String = "", file: StaticString = #filePath, line: UInt = #line) {
        storage.destroy()
        oracle.clearStorage()
        assertMatches(step, file: file, line: line)
    }

    func load(_ splits: [Split], step: String = "", file: StaticString = #filePath, line: UInt = #line) {
        track(splits)
        persistent.snapshot = SplitsSnapshot(changeNumber: 1, splits: splits, updateTimestamp: 1)
        storage.loadLocal()
        oracle.loadLocal(splits)
        assertMatches(step, file: file, line: line)
    }

    func update(active: [Split] = [], archived: [Split] = [], step: String = "",
                file: StaticString = #filePath, line: UInt = #line) {
        track(active)
        track(archived)
        _ = storage.update(splitChange: ProcessedSplitChange(activeSplits: active, archivedSplits: archived,
                                                             changeNumber: 2, updateTimestamp: 2))
        oracle.update(active: active, archived: archived)
        assertMatches(step, file: file, line: line)
    }

    func clearStorage(step: String = "", file: StaticString = #filePath, line: UInt = #line) {
        storage.clear()
        oracle.clearStorage()
        assertMatches(step, file: file, line: line)
    }

    func updateWithoutChecks(_ split: Split, step: String = "", file: StaticString = #filePath, line: UInt = #line) {
        track([split])
        storage.updateWithoutChecks(split: split)
        oracle.updateWithoutChecks(split)
        assertMatches(step, file: file, line: line)
    }

    func assertMatches(_ step: String, file: StaticString = #filePath, line: UInt = #line) {
        let observed = cache.getFeatureFlagNamesBySet(byFlagSets: Array(universe))
        XCTAssertEqual(oracle.index, observed, "full index differs at step \(step)", file: file, line: line)
        for set in universe {
            XCTAssertEqual(oracle.index[set] ?? [], Set(cache.getFeatureFlagNames(forFlagSets: [set])),
                           "names of set \(set) differ at step \(step)", file: file, line: line)
        }
        let union = oracle.index.values.reduce(Set<String>()) { $0.union($1) }
        let observedUnion = cache.getFeatureFlagNames(forFlagSets: Array(universe))
        XCTAssertEqual(union, Set(observedUnion), "union differs at step \(step)", file: file, line: line)
        XCTAssertEqual(observedUnion.count, Set(observedUnion).count, "duplicates at step \(step)",
                       file: file, line: line)
        XCTAssertTrue(cache.getFeatureFlagNames(forFlagSets: ["never_used_set"]).isEmpty,
                      file: file, line: line)
    }
}

// MARK: Tests

class FlagSetsIndexEquivalenceTests: XCTestCase {

    static func makeCache(filter: Set<String>?) -> DefaultFlagSetsCache {
        return DefaultFlagSetsCache(setsInFilter: filter)
    }

    private func sp(_ name: String, _ sets: [String]?, archived: Bool = false) -> Split {
        return TestingHelper.createSplit(name: name, status: archived ? .archived : .active,
                                         sets: sets.map { Set($0) })
    }

    private func names(_ prefix: String, _ range: Range<Int>, _ sets: [String]?, archived: Bool = false) -> [Split] {
        return range.map { sp("\(prefix)\($0)", sets, archived: archived) }
    }

    // 1. cold load

    func testColdLoadCacheDirect() {
        let h = IndexHarness(filter: nil)
        for i in 0..<30 {
            h.cacheAdd(sp("f\(i)", ["s\(i % 4)", "s\((i + 1) % 5)", "s\((i % 3) + 6)"]), step: "f\(i)")
        }
        XCTAssertGreaterThan(h.oracle.index.count, 5)
    }

    func testColdLoadStorage() {
        let h = IndexHarness(filter: nil)
        var splits = [Split]()
        for i in 0..<40 {
            splits.append(sp("f\(i)", ["s\(i % 4)", "s\((i + 1) % 5)", "s\((i % 3) + 6)"]))
        }
        h.load(splits, step: "load")
        XCTAssertGreaterThan(h.oracle.index.count, 5)
        XCTAssertEqual(40, h.storage.getCount())
    }

    // 2. sets change

    func testUpdateChangesSetsCacheDirect() {
        let h = IndexHarness(filter: nil)
        h.cacheAdd(sp("f", ["a", "b"]), step: "initial")
        h.cacheAdd(sp("g", ["a"]), step: "other")
        h.cacheAdd(sp("f", ["b", "c"]), step: "move a->c")
        h.cacheAdd(sp("f", ["b", "c", "d"]), step: "add d")
        h.cacheAdd(sp("f", ["d"]), step: "drop b c")
        XCTAssertEqual(["d": ["f"], "a": ["g"]], h.oracle.index)
    }

    func testUpdateChangesSetsStorage() {
        let h = IndexHarness(filter: nil)
        h.load([sp("f", ["a", "b"]), sp("g", ["a"])], step: "load")
        h.update(active: [sp("f", ["b", "c"])], step: "move")
        h.update(active: [sp("f", ["b", "c", "d"]), sp("g", ["a", "d"])], step: "add")
        h.update(active: [sp("f", ["d"])], step: "drop")
        XCTAssertEqual(["d": ["f", "g"], "a": ["g"]], h.oracle.index)
    }

    // 3. clears sets

    func testUpdateClearsSetsNilAndEmpty() {
        let h = IndexHarness(filter: nil)
        h.load([sp("f", ["a", "b"]), sp("g", ["a", "b"]), sp("k", ["a"])], step: "load")
        h.update(active: [sp("f", nil)], step: "nil sets")
        XCTAssertEqual(["a": ["g", "k"], "b": ["g"]], h.oracle.index)
        h.update(active: [sp("g", [])], step: "empty sets")
        XCTAssertEqual(["a": ["k"]], h.oracle.index)
        h.cacheAdd(sp("k", nil), step: "cache nil")
        XCTAssertTrue(h.oracle.index.isEmpty)
    }

    // 4. archived

    func testArchivedRemovedFromEverySetViaUpdate() {
        let h = IndexHarness(filter: nil)
        h.load(names("f", 0..<10, ["a", "b", "c"]) + [sp("keep", ["a"])], step: "load")
        h.update(archived: [sp("f1", ["a"], archived: true)], step: "archive f1")
        h.update(archived: [sp("f2", nil, archived: true), sp("f3", [], archived: true)], step: "archive f2 f3")
        h.update(active: [sp("f4", ["b"])], archived: [sp("f5", ["zzz"], archived: true)], step: "mixed")
        XCTAssertFalse(h.oracle.index["a"]!.contains("f1"))
        XCTAssertFalse(h.oracle.index["b"]!.contains("f2"))
        XCTAssertEqual(5, h.oracle.index["c"]!.count)
    }

    func testArchivedInSnapshotOnLoadLocal() {
        let h = IndexHarness(filter: nil)
        h.load([sp("f", ["a"]), sp("f", ["b"], archived: true), sp("g", ["a"]),
                sp("never", ["a"], archived: true)], step: "snapshot with archived")
        XCTAssertEqual(["a": ["g"]], h.oracle.index)
    }

    func testArchivedNotInMemoryLeavesIndexUntouched() {
        let h = IndexHarness(filter: nil)
        h.cacheAdd(sp("ghost", ["a"]), step: "cache only")
        h.update(archived: [sp("ghost", ["a"], archived: true)], step: "archive not in memory")
        XCTAssertEqual(["a": ["ghost"]], h.oracle.index)
    }

    // 5. filter

    func testFilterCacheDirect() {
        let h = IndexHarness(filter: ["a", "b"])
        h.cacheAdd(sp("in", ["a", "b"]), step: "inside")
        h.cacheAdd(sp("out", ["x", "y"]), step: "outside")
        h.cacheAdd(sp("part", ["a", "x"]), step: "partly")
        h.cacheAdd(sp("part", ["x", "b"]), step: "partly moved")
        h.cacheRemove("in", sets: ["a"], step: "remove from a")
        h.cacheRemove("part", sets: [], step: "remove from all")
        XCTAssertEqual(["b": ["in"]], h.oracle.index)
    }

    func testFilterStorageWithArchivedRemovalPath() {
        let h = IndexHarness(filter: ["a", "b"])
        h.load([sp("in", ["a", "b"]), sp("out", ["x"]), sp("part", ["a", "x"])], step: "load")
        XCTAssertEqual(["a": ["in", "part"], "b": ["in"]], h.oracle.index)
        h.update(active: [sp("part", ["b", "x"]), sp("out", ["a", "x"])], step: "update")
        h.update(archived: [sp("in", ["a"], archived: true)], step: "archive in (filter sets only)")
        h.update(archived: [sp("out", ["x"], archived: true), sp("part", nil, archived: true)], step: "archive rest")
        XCTAssertTrue(h.oracle.index.isEmpty)
    }

    func testFilterLoadLocalWithArchived() {
        let h = IndexHarness(filter: ["a"])
        h.load([sp("f", ["a", "q"]), sp("f", ["a"], archived: true), sp("g", ["a", "q"])], step: "load")
        XCTAssertEqual(["a": ["g"]], h.oracle.index)
    }

    // 6. no sets

    func testFlagsWithNoSetsColdLoadAndUpdate() {
        for filter in [nil, Set(["a"])] as [Set<String>?] {
            let h = IndexHarness(filter: filter)
            h.load([sp("n1", nil), sp("n2", []), sp("w", ["a"])], step: "load")
            XCTAssertEqual(["a": ["w"]], h.oracle.index)
            h.update(active: [sp("n1", nil), sp("n2", []), sp("n3", nil)], step: "update no sets")
            h.update(active: [sp("n1", ["a"])], step: "n1 gains a set")
            h.update(active: [sp("n1", [])], step: "n1 loses it")
            XCTAssertEqual(["a": ["w"]], h.oracle.index)
        }
    }

    // 7. public path

    private func makeTreatmentManager(storage: SplitsStorage, cache: FlagSetsCache) -> DefaultTreatmentManager {
        let impressions = ImpressionsLoggerStub()
        let telemetry = TelemetryStorageStub()
        let segments = MySegmentsStorageStub()
        let container = SplitStorageContainer(splitDatabase: TestingHelper.createTestDatabase(name: "idx_equiv"),
                                              splitsStorage: storage,
                                              persistentSplitsStorage: PersistentSplitsStorageStub(),
                                              impressionsStorage: ImpressionsStorageStub(),
                                              persistentImpressionsStorage: PersistentImpressionsStorageStub(),
                                              impressionsCountStorage: PersistentImpressionsCountStorageStub(),
                                              eventsStorage: EventsStorageStub(),
                                              persistentEventsStorage: PersistentEventsStorageStub(),
                                              telemetryStorage: telemetry,
                                              mySegmentsStorage: segments,
                                              myLargeSegmentsStorage: segments,
                                              attributesStorage: DefaultAttributesStorage(timeChecker: TimeChecker.forTesting()),
                                              uniqueKeyStorage: PersistentUniqueKeyStorageStub(),
                                              flagSetsCache: cache,
                                              persistentHashedImpressionsStorage: PersistentHashedImpressionStorageMock(),
                                              hashedImpressionsStorage: HashedImpressionsStorageMock(),
                                              generalInfoStorage: GeneralInfoStorageMock(),
                                              ruleBasedSegmentsStorage: RuleBasedSegmentsStorageStub(),
                                              persistentRuleBasedSegmentsStorage: PersistentRuleBasedSegmentsStorageStub(),
                                              targetingRulesPersistenceBreaker: DefaultPersistenceBreaker())
        let evaluator = DefaultEvaluator(splitsStorage: storage,
                                         mySegmentsStorage: segments,
                                         myLargeSegmentsStorage: segments,
                                         fallbackTreatmentsCalculator: DefaultFallbackTreatmentsCalculatorStub())
        let eventsManager = SplitEventsManagerMock()
        eventsManager.isSegmentsReadyFired = true
        eventsManager.isSplitsReadyFired = true
        eventsManager.isSegmentsReadyFromCacheFired = true
        eventsManager.isSplitsReadyFromCacheFired = true
        return DefaultTreatmentManager(evaluator: evaluator,
                                       key: Key(matchingKey: "k", bucketingKey: nil),
                                       splitConfig: SplitClientConfig(),
                                       eventsManager: eventsManager,
                                       impressionLogger: impressions,
                                       telemetryProducer: telemetry,
                                       storageContainer: container,
                                       flagSetsValidator: DefaultFlagSetsValidator(telemetryProducer: nil),
                                       keyValidator: DefaultKeyValidator(),
                                       splitValidator: DefaultSplitValidator(splitsStorage: storage),
                                       validationLogger: ValidationMessageLoggerStub(),
                                       propertyValidator: PropertyValidatorStub(),
                                       fallbackTreatmentsCalculator: DefaultFallbackTreatmentsCalculatorStub())
    }

    private func publicPathMatchesOracle(filter: Set<String>?) {
        let h = IndexHarness(filter: filter)
        let tm = makeTreatmentManager(storage: h.storage, cache: h.cache)
        h.load([sp("f1", ["a", "b"]), sp("f2", ["b"]), sp("f3", ["c", "a"]), sp("f4", nil), sp("f5", ["d"])],
               step: "load")
        h.update(active: [sp("f2", ["c"]), sp("f6", ["a", "d"])], archived: [sp("f5", ["d"], archived: true)],
                 step: "update")

        for sets in [["a"], ["b"], ["c"], ["d"], ["a", "c"], ["a", "b", "c", "d"], ["zz"]] {
            let expected = sets.reduce(Set<String>()) { $0.union(h.oracle.index[$1] ?? []) }
            XCTAssertEqual(expected, Set(tm.getTreatmentsWithConfigByFlagSets(flagSets: sets, attributes: nil).keys),
                           "by flag sets \(sets) filter \(String(describing: filter))")
            XCTAssertEqual(expected, Set(tm.getTreatmentsByFlagSets(flagSets: sets, attributes: nil).keys))
            if sets.count == 1 {
                XCTAssertEqual(expected, Set(tm.getTreatmentsByFlagSet(flagSet: sets[0], attributes: nil).keys))
                XCTAssertEqual(expected,
                               Set(tm.getTreatmentsWithConfigByFlagSet(flagSet: sets[0], attributes: nil).keys))
            }
        }
        XCTAssertFalse(h.oracle.index.isEmpty)
        XCTAssertFalse(Set(tm.getTreatmentsByFlagSets(flagSets: ["a", "b", "c", "d"], attributes: nil).keys).isEmpty)
    }

    func testByFlagSetPublicPathNoFilter() {
        publicPathMatchesOracle(filter: nil)
    }

    func testByFlagSetPublicPathWithFilter() {
        publicPathMatchesOracle(filter: ["a", "c"])
    }

    // 8. concurrent read during a batch

    private final class ReaderBox: @unchecked Sendable {
        private let lock = NSLock()
        private var stop = false
        private(set) var reads = 0
        private(set) var violations = [String]()
        var shouldStop: Bool { lock.lock(); defer { lock.unlock() }; return stop }
        func finish() { lock.lock(); stop = true; lock.unlock() }
        func record(reads n: Int, violations v: [String]) {
            lock.lock(); reads += n; violations.append(contentsOf: v); lock.unlock()
        }
    }

    // Visibility HEAD gives: a storage update applies flags one at a time and, per flag, inserts into the
    // new sets and then scans-and-removes from the others. There is no batch atomicity, so a reader may see a
    // flag in both sets transiently, and may see part of the batch moved. Nothing stricter is asserted: only
    // that no read crashes and every observed name belongs to the old or the new membership.
    func testConcurrentReadDuringBatchUpdate() {
        let h = IndexHarness(filter: nil)
        let moved = names("m", 0..<1500, ["old"])
        h.load(moved, step: "load")
        let movedNames = Set(moved.map { $0.name! })
        let added = names("g", 0..<100, ["new"])
        let addedNames = Set(added.map { $0.name! })
        let newMembership = movedNames.union(addedNames)

        let box = ReaderBox()
        let cache = h.cache
        let group = DispatchGroup()
        for _ in 0..<3 {
            group.enter()
            DispatchQueue.global().async {
                var reads = 0
                var bad = [String]()
                while !box.shouldStop {
                    let old = cache.getFeatureFlagNames(forFlagSets: ["old"])
                    let new = cache.getFeatureFlagNames(forFlagSets: ["new"])
                    let both = cache.getFeatureFlagNames(forFlagSets: ["old", "new"])
                    let bySet = cache.getFeatureFlagNamesBySet(byFlagSets: ["old", "new"])
                    for n in old where !movedNames.contains(n) { bad.append("old:\(n)") }
                    for n in new where !newMembership.contains(n) { bad.append("new:\(n)") }
                    for n in both where !newMembership.contains(n) { bad.append("both:\(n)") }
                    for (_, v) in bySet { for n in v where !newMembership.contains(n) { bad.append("bySet:\(n)") } }
                    reads += 1
                }
                box.record(reads: reads, violations: bad)
                group.leave()
            }
        }

        h.update(active: names("m", 0..<1500, ["new"]) + added, step: "batch move")
        box.finish()
        group.wait()

        XCTAssertEqual([], box.violations)
        XCTAssertGreaterThan(box.reads, 0)
        XCTAssertEqual(["new": newMembership], h.oracle.index)
    }

    // 9. stale entries: today the full scan cleans every one of them

    func testStaleCacheAddedTwiceWithDisjointSets() {
        let h = IndexHarness(filter: nil)
        h.cacheAdd(sp("f", ["a", "b"]), step: "a b")
        // a lookup keyed on "previous sets = [a]" would leave f in b; HEAD cleans it
        h.cacheAdd(sp("f", ["c"]), step: "c only")
        XCTAssertEqual(["c": ["f"]], h.oracle.index)
        XCTAssertEqual(["f"], h.cache.getFeatureFlagNames(forFlagSets: ["a", "b", "c"]))
        XCTAssertTrue(h.cache.getFeatureFlagNames(forFlagSets: ["a", "b"]).isEmpty)
    }

    func testStaleStorageClearThenReloadWithFewerSets() {
        let h = IndexHarness(filter: nil)
        h.load([sp("f", ["a", "b", "c"]), sp("g", ["a"])], step: "load")
        h.clearStorage(step: "clear: memory empty, index keeps entries")
        XCTAssertEqual(["a": ["f", "g"], "b": ["f"], "c": ["f"]], h.oracle.index)
        // previous flag is nil here but the index still holds f in a,b,c: HEAD's scan removes b and c
        h.update(active: [sp("f", ["a"])], step: "update after clear")
        XCTAssertEqual(["a": ["f", "g"]], h.oracle.index)

        let h2 = IndexHarness(filter: nil)
        h2.load([sp("f", ["a", "b", "c"])], step: "load2")
        h2.clearStorage(step: "clear2")
        h2.load([sp("f", ["c"])], step: "loadLocal after clear")
        XCTAssertEqual(["c": ["f"]], h2.oracle.index)
    }

    func testStaleUpdateWithoutChecksThenSetsChange() {
        let h = IndexHarness(filter: nil)
        h.load([sp("f", ["a", "b"])], step: "load")
        // kill path: memory only, index keeps f in a and b although memory says [c]
        h.updateWithoutChecks(sp("f", ["c"]), step: "updateWithoutChecks")
        XCTAssertEqual(["a": ["f"], "b": ["f"]], h.oracle.index)
        // a previous-sets lookup from memory ([c]) would not clean a or b
        h.update(active: [sp("f", ["d"])], step: "update")
        XCTAssertEqual(["d": ["f"]], h.oracle.index)
    }

    func testStaleNameCaseDiffers() {
        let h = IndexHarness(filter: nil)
        h.load([sp("Foo", ["a", "b"])], step: "Foo")
        XCTAssertEqual(["a": ["Foo"], "b": ["Foo"]], h.oracle.index)
        // memory lookup is lowercased (finds previous Foo) but the index scan uses the name as given:
        // "foo" is a different entry from "Foo" in the index
        h.update(active: [sp("foo", ["a"])], step: "foo")
        XCTAssertEqual(["a": ["Foo", "foo"], "b": ["Foo"]], h.oracle.index)
        h.update(active: [sp("Foo", ["c"])], step: "Foo again")
        XCTAssertEqual(["a": ["foo"], "c": ["Foo"]], h.oracle.index)
        h.update(archived: [sp("FOO", ["a"], archived: true)], step: "archive FOO")
        XCTAssertEqual(["a": ["foo"], "c": ["Foo"]], h.oracle.index)
    }

    func testStalePreviousVersionHadSetOutsideFilter() {
        let h = IndexHarness(filter: ["a", "b"])
        h.load([sp("f", ["a", "x"])], step: "load")
        XCTAssertEqual(["a": ["f"]], h.oracle.index)
        h.update(active: [sp("f", ["b", "x"])], step: "to b x")
        XCTAssertEqual(["b": ["f"]], h.oracle.index)
        h.update(active: [sp("f", ["x"])], step: "only outside")
        XCTAssertTrue(h.oracle.index.isEmpty)
        h.update(active: [sp("f", ["a", "x"])], step: "back")
        h.update(archived: [sp("f", ["x"], archived: true)], step: "archive")
        XCTAssertTrue(h.oracle.index.isEmpty)
    }


    // MARK: Batch API (stage 2)

    private func item(_ name: String, _ sets: [String]?, prev: [String]?) -> IndexHarness.BatchItem {
        return (flag: sp(name, sets), previousSets: prev.map { Set($0) })
    }

    func testBatchColdIndexEmptyPreviousNilMatchesOracle() {
        let h = IndexHarness(filter: nil)
        let items = (0..<40).map { i in
            item("f\(i)", ["s\(i % 4)", "s\((i + 1) % 5)", "s\((i % 3) + 6)"], prev: nil)
        }
        h.cacheBatch(items, usePreviousSets: true, step: "cold")
        XCTAssertGreaterThan(h.oracle.index.count, 5)
        XCTAssertEqual(40, Set(h.cache.getFeatureFlagNames(forFlagSets: Array(h.universe))).count)
    }

    func testBatchUpdateWithCorrectPreviousSets() {
        let h = IndexHarness(filter: nil)
        h.cacheBatch([item("f", ["a", "b"], prev: nil), item("g", ["a"], prev: nil),
                      item("k", ["b", "c"], prev: nil)], usePreviousSets: true, step: "cold")
        h.cacheBatch([item("f", ["b", "d"], prev: ["a", "b"]),      // drops a, keeps b, adds d
                      item("g", ["z"], prev: ["a"]),                // moves
                      item("k", ["b", "c"], prev: ["b", "c"]),      // unchanged
                      item("n", ["a"], prev: nil)],                 // new flag on a non-empty index
                     usePreviousSets: true, step: "update")
        XCTAssertEqual(["b": ["f", "k"], "c": ["k"], "d": ["f"], "z": ["g"], "a": ["n"]], h.oracle.index)
    }

    func testBatchUpdateKeepsSetsTheFlagStillHas() {
        let h = IndexHarness(filter: nil)
        h.cacheBatch([item("f", ["a", "b", "c"], prev: nil), item("g", ["a", "b", "c"], prev: nil)],
                     usePreviousSets: true, step: "cold")
        h.cacheBatch([item("f", ["a", "b"], prev: ["a", "b", "c"])], usePreviousSets: true, step: "drop c")
        XCTAssertEqual(["a": ["f", "g"], "b": ["f", "g"], "c": ["g"]], h.oracle.index)
    }

    func testBatchPreviousNilOnNonEmptyIndexFallsBackToScanAndCleansStale() {
        let h = IndexHarness(filter: nil)
        h.cacheAdd(sp("f", ["a", "b"]), step: "seed")
        h.cacheAdd(sp("g", ["a"]), step: "seed g")
        // previous unknown but the index is not empty: stale entry of f in a and b must be cleaned
        h.cacheBatch([item("f", ["c"], prev: nil)], usePreviousSets: true, step: "stale scan")
        XCTAssertEqual(["a": ["g"], "c": ["f"]], h.oracle.index)
        XCTAssertTrue(h.cache.getFeatureFlagNames(forFlagSets: ["b"]).isEmpty)
    }

    func testBatchUsePreviousSetsFalseScansEvenWhenPreviousSetsAreWrong() {
        let h = IndexHarness(filter: nil)
        h.cacheAdd(sp("f", ["a", "b"]), step: "seed")
        h.cacheBatch([item("f", ["c"], prev: ["a"])], usePreviousSets: false, step: "untrusted")
        XCTAssertEqual(["c": ["f"]], h.oracle.index)
    }

    func testBatchUsePreviousSetsFalseColdAlsoMatchesOracle() {
        let h = IndexHarness(filter: nil)
        h.cacheBatch([item("f", ["a", "b"], prev: nil), item("f", ["c"], prev: nil),
                      item("g", ["a"], prev: nil)], usePreviousSets: false, step: "cold untrusted")
        XCTAssertEqual(["c": ["f"], "a": ["g"]], h.oracle.index)
    }

    func testBatchDuplicateNamesBehaveAsSequentialCalls() {
        let h = IndexHarness(filter: nil)
        // cold, previous nil on every occurrence: later duplicates must still clean the earlier insert
        h.cacheBatch([item("f", ["a", "b"], prev: nil), item("f", ["c"], prev: nil),
                      item("g", ["a"], prev: nil), item("f", ["a"], prev: nil)],
                     usePreviousSets: true, step: "cold duplicates previous nil")
        XCTAssertEqual(["a": ["f", "g"]], h.oracle.index)

        let h2 = IndexHarness(filter: nil)
        // previous sets as the storage reports them: the earlier occurrence of the batch
        h2.cacheBatch([item("f", ["a", "b"], prev: nil), item("f", ["c"], prev: ["a", "b"]),
                       item("f", ["a"], prev: ["c"])], usePreviousSets: true, step: "duplicates chained")
        XCTAssertEqual(["a": ["f"]], h2.oracle.index)

        let h3 = IndexHarness(filter: nil)
        h3.cacheAdd(sp("f", ["a", "b"]), step: "seed")
        h3.cacheBatch([item("f", ["b", "c"], prev: ["a", "b"]), item("f", ["d"], prev: ["b", "c"])],
                      usePreviousSets: true, step: "duplicates on non empty")
        XCTAssertEqual(["d": ["f"]], h3.oracle.index)
    }

    func testBatchFilterPreviousVersionHadSetOutsideFilter() {
        let h = IndexHarness(filter: ["a", "b"])
        h.cacheBatch([item("f", ["a", "x"], prev: nil)], usePreviousSets: true, step: "cold")
        XCTAssertEqual(["a": ["f"]], h.oracle.index)
        h.cacheBatch([item("f", ["b", "x"], prev: ["a", "x"])], usePreviousSets: true, step: "move inside filter")
        XCTAssertEqual(["b": ["f"]], h.oracle.index)
        h.cacheBatch([item("f", ["x"], prev: ["b", "x"]), item("g", ["a", "b"], prev: nil)],
                     usePreviousSets: true, step: "only outside")
        XCTAssertEqual(["a": ["g"], "b": ["g"]], h.oracle.index)
    }

    func testBatchFlagsWithNilAndEmptySets() {
        for filter in [nil, Set(["a"])] as [Set<String>?] {
            let h = IndexHarness(filter: filter)
            h.cacheBatch([item("n", nil, prev: nil), item("e", [], prev: nil), item("w", ["a"], prev: nil)],
                         usePreviousSets: true, step: "cold")
            XCTAssertEqual(["a": ["w"]], h.oracle.index)
            h.cacheBatch([item("n", nil, prev: nil), item("e", [], prev: []), item("w", ["a"], prev: ["a"])],
                         usePreviousSets: true, step: "update")
            XCTAssertEqual(["a": ["w"]], h.oracle.index)
        }
    }

    func testBatchClearsFlagSets() {
        let h = IndexHarness(filter: nil)
        h.cacheBatch([item("f", ["a", "b"], prev: nil), item("g", ["a"], prev: nil), item("k", ["b"], prev: nil)],
                     usePreviousSets: true, step: "cold")
        h.cacheBatch([item("f", nil, prev: ["a", "b"]), item("g", [], prev: ["a"])],
                     usePreviousSets: true, step: "clear sets")
        XCTAssertEqual(["b": ["k"]], h.oracle.index)
    }

    func testBatchEmptyIsNoOp() {
        let h = IndexHarness(filter: nil)
        h.cacheBatch([], usePreviousSets: true, step: "empty cold")
        h.cacheAdd(sp("f", ["a"]), step: "seed")
        h.cacheBatch([], usePreviousSets: false, step: "empty")
        XCTAssertEqual(["a": ["f"]], h.oracle.index)
    }

    func testBatchRandomizedWithCallerTrackedPreviousSetsMatchesOracleEveryRound() {
        for filter in [nil, Set((0..<10).map { "set\($0)" })] as [Set<String>?] {
            var rng = SeededGenerator(seed: 4545)
            let h = IndexHarness(filter: filter)
            var known = [String: Set<String>]()

            func randomSets() -> [String]? {
                let r = rng.next(below: 10)
                if r == 0 { return nil }
                if r == 1 { return [] }
                return (0..<(1 + rng.next(below: 5))).map { _ in "set\(rng.next(below: 20))" }
            }

            func round(_ count: Int, _ range: Int, _ step: String) {
                var items = [IndexHarness.BatchItem]()
                for _ in 0..<count {
                    let name = "flag\(rng.next(below: range))"
                    let sets = randomSets()
                    items.append((flag: sp(name, sets), previousSets: known[name]))
                    known[name] = sets.map { Set($0) } ?? []
                }
                h.cacheBatch(items, usePreviousSets: true, step: step)
                XCTAssertFalse(h.oracle.index.isEmpty)
            }
            round(500, 520, "cold")
            for r in 0..<6 { round(150, 520, "round \(r)") }
        }
    }

    // Storage level: the stage 1 stale cases re-asserted through the batch path, mixed with flags
    // whose previous sets can be trusted so that the untrusted fallback is pinned.

    func testStaleStorageClearThenUpdateBatchMixed() {
        let h = IndexHarness(filter: nil)
        h.load([sp("f", ["a", "b", "c"]), sp("g", ["a", "b"]), sp("k", ["c"])], step: "load")
        h.clearStorage(step: "clear")
        h.update(active: [sp("f", ["a"]), sp("g", ["a", "b"]), sp("k", ["d"]), sp("new", ["a"])], step: "update")
        XCTAssertEqual(["a": ["f", "g", "new"], "b": ["g"], "d": ["k"]], h.oracle.index)
        // after the clear the previous sets stay untrusted for the rest of the session
        h.update(active: [sp("g", ["z"])], step: "second update")
        XCTAssertEqual(["a": ["f", "new"], "d": ["k"], "z": ["g"]], h.oracle.index)
    }

    func testStaleStorageUpdateWithoutChecksThenUpdateBatchMixed() {
        let h = IndexHarness(filter: nil)
        h.load([sp("f", ["a", "b"]), sp("g", ["a"])], step: "load")
        h.updateWithoutChecks(sp("f", ["c"]), step: "kill path")
        h.update(active: [sp("f", ["d"]), sp("g", ["a", "b"])], step: "update")
        XCTAssertEqual(["d": ["f"], "a": ["g"], "b": ["g"]], h.oracle.index)
    }

    func testStaleStorageDestroyThenReload() {
        let h = IndexHarness(filter: nil)
        h.load([sp("f", ["a", "b"])], step: "load")
        h.destroyStorage(step: "destroy")
        h.load([sp("f", ["c"])], step: "reload")
        XCTAssertEqual(["c": ["f"]], h.oracle.index)
    }

    func testStorageUpdateWithDuplicatesAndMixedCaseInOneBatch() {
        let h = IndexHarness(filter: nil)
        h.load([sp("Foo", ["a", "b"]), sp("g", ["a"])], step: "load")
        h.update(active: [sp("foo", ["a"]), sp("Foo", ["c"]), sp("g", ["b"]), sp("g", ["a", "c"])],
                 step: "mixed case and duplicates")
        XCTAssertEqual(["a": ["foo", "g"], "c": ["Foo", "g"]], h.oracle.index)
    }

    func testStorageColdLoadWithDuplicatesInSnapshot() {
        let h = IndexHarness(filter: nil)
        h.load([sp("f", ["a", "b"]), sp("f", ["c"]), sp("g", ["a"]), sp("f", ["a"])], step: "dups")
        XCTAssertEqual(["a": ["f", "g"]], h.oracle.index)
    }

    func testStorageSameFlagUpdatedOverManyRoundsKeepsOracle() {
        let h = IndexHarness(filter: ["a", "b", "c"])
        h.load([sp("f", ["a", "x"]), sp("g", ["b", "c"])], step: "load")
        h.update(active: [sp("f", ["b", "x"])], step: "r1")
        h.update(active: [sp("f", ["c"]), sp("g", ["b"])], step: "r2")
        h.update(archived: [sp("f", nil, archived: true)], step: "archive f")
        h.update(active: [sp("f", ["a", "b"])], step: "back")
        XCTAssertEqual(["a": ["f"], "b": ["f", "g"]], h.oracle.index)
    }

    // The batch must be applied under one lock: a reader never sees a flag missing from both its old and
    // new sets, and never a partially applied batch. This is a STRONGER guarantee than the one of the
    // per flag implementation pinned by testConcurrentReadDuringBatchUpdate.
    func testConcurrentReadDuringBatchUpdateSeesWholeBatchOrNone() {
        let h = IndexHarness(filter: nil)
        let moved = names("m", 0..<1500, ["old"])
        h.load(moved, step: "load")
        let movedNames = Set(moved.map { $0.name! })

        let box = ReaderBox()
        let cache = h.cache
        let group = DispatchGroup()
        let started = DispatchSemaphore(value: 0)
        let readers = 3
        for _ in 0..<readers {
            group.enter()
            DispatchQueue.global().async {
                var reads = 0
                var bad = [String]()
                while !box.shouldStop {
                    let snap = cache.getFeatureFlagNamesBySet(byFlagSets: ["old", "new"])
                    let old = snap["old"] ?? []
                    let new = snap["new"] ?? []
                    if old.union(new) != movedNames { bad.append("missing from both: \(movedNames.subtracting(old.union(new)).count)") }
                    if !(old == movedNames && new.isEmpty) && !(new == movedNames && old.isEmpty) {
                        bad.append("partial batch old=\(old.count) new=\(new.count)")
                    }
                    reads += 1
                    if reads == 1 { started.signal() }
                }
                box.record(reads: reads, violations: bad)
                group.leave()
            }
        }
        for _ in 0..<readers { started.wait() }

        h.update(active: names("m", 0..<1500, ["new"]), step: "batch move")
        box.finish()
        group.wait()

        XCTAssertEqual([], box.violations)
        XCTAssertGreaterThanOrEqual(box.reads, readers)
        XCTAssertEqual(["new": movedNames], h.oracle.index)
    }

    // Large deterministic sequence

    func testLargeRandomizedSequenceMatchesOracleEveryRound() {
        for filter in [nil, Set((0..<10).map { "set\($0)" })] as [Set<String>?] {
            var rng = SeededGenerator(seed: 45)
            let h = IndexHarness(filter: filter)

            func randomSets() -> [String]? {
                let r = rng.next(below: 10)
                if r == 0 { return nil }
                if r == 1 { return [] }
                return (0..<(1 + rng.next(below: 5))).map { _ in "set\(rng.next(below: 20))" }
            }

            h.load((0..<500).map { sp("flag\($0)", randomSets()) }, step: "cold")
            for round in 0..<6 {
                var active = [Split]()
                var archived = [Split]()
                for _ in 0..<150 {
                    let name = "flag\(rng.next(below: 520))"
                    if rng.next(below: 6) == 0 {
                        archived.append(sp(name, nil, archived: true))
                    } else {
                        active.append(sp(name, randomSets()))
                    }
                }
                h.update(active: active, archived: archived, step: "round \(round)")
                XCTAssertFalse(h.oracle.index.isEmpty)
            }
        }
    }

    // INFORMATIONAL ONLY: in-process, unprofiled timing of DefaultSplitsStorage.loadLocal
    // with a synthetic 4,585 flag snapshot (30 distinct sets, 3 sets per flag, fixed seed). Not asserted: the test only asserts the resulting index.
    func testInformationalLoadLocalTiming4585Flags() {
        var rng = SeededGenerator(seed: 4585)
        let splits: [Split] = (0..<4585).map { i in
            var sets = Set<String>()
            while sets.count < 3 { sets.insert("set\(rng.next(below: 30))") }
            return sp("flag\(i)", Array(sets))
        }
        var expected = FlagSetsIndexOracle(filter: nil)
        expected.loadLocal(splits)
        XCTAssertEqual(30, expected.index.count)

        var timings = [Double]()
        for _ in 0..<10 {
            let h = IndexHarness(filter: nil)
            h.persistent.snapshot = SplitsSnapshot(changeNumber: 1, splits: splits, updateTimestamp: 1)
            let start = DispatchTime.now().uptimeNanoseconds
            h.storage.loadLocal()
            timings.append(Double(DispatchTime.now().uptimeNanoseconds - start) / 1_000_000)
            XCTAssertEqual(expected.index, h.cache.getFeatureFlagNamesBySet(byFlagSets: (0..<30).map { "set\($0)" }))
        }
        timings.sort()
        print("loadLocal timing 4585 flags median_ms=\(timings[4] + (timings[5] - timings[4]) / 2) min_ms=\(timings[0]) max_ms=\(timings[9])")
    }
}
