//
//  CacheReadAheadTest.swift
//  SplitTests
//
//  Read-ahead of the Split cache file.
//

import XCTest
@testable import Split

class CacheReadAheadTest: XCTestCase {

    private var directory: URL!
    private let queue = DispatchQueue(label: "test.cache-readahead")

    override func setUpWithError() throws {
        directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("readahead_\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
    }

    override func tearDownWithError() throws {
        try? FileManager.default.setAttributes([.posixPermissions: 0o644],
                                               ofItemAtPath: directory.appendingPathComponent("a.sqlite").path)
        try? FileManager.default.removeItem(at: directory)
    }

    private var store: URL { directory.appendingPathComponent("a.sqlite") }
    private var wal: String { store.path + "-wal" }

    private func write(_ path: String, bytes: Int) throws {
        try Data(repeating: 7, count: bytes).write(to: URL(fileURLWithPath: path))
    }

    private func make(maxBytes: Int = 1_000_000) -> CacheReadAhead {
        return CacheReadAhead(maxBytes: maxBytes, queue: queue)
    }

    func test_readsStoreAndWal() throws {
        try write(store.path, bytes: 300_000)
        try write(wal, bytes: 5000)
        let readAhead = make()
        XCTAssertEqual(readAhead.prefetch(store: store), [store.path, wal])
        readAhead.waitForIdle()
        XCTAssertEqual(readAhead.bytesRead(path: store.path), 300_000)
        XCTAssertEqual(readAhead.bytesRead(path: wal), 5000)
    }

    func test_secondCallForSameFileIsDeduplicated() throws {
        try write(store.path, bytes: 1000)
        try write(wal, bytes: 10)
        let readAhead = make()
        XCTAssertEqual(readAhead.prefetch(store: store).count, 2)
        XCTAssertEqual(readAhead.prefetch(store: store), [])
        readAhead.waitForIdle()
        XCTAssertEqual(readAhead.readCount(path: store.path), 1)
    }

    func test_fileOverTheCapIsNotRead_fileAtTheCapIs() throws {
        try write(store.path, bytes: 1001)
        try write(wal, bytes: 1000)
        let readAhead = make(maxBytes: 1000)
        readAhead.prefetch(store: store)
        readAhead.waitForIdle()
        XCTAssertEqual(readAhead.bytesRead(path: store.path), 0)
        XCTAssertEqual(readAhead.bytesRead(path: wal), 1000)
    }

    func test_missingFilesDoNotRaise_andAreNotClaimed() throws {
        let readAhead = make()
        XCTAssertEqual(readAhead.prefetch(store: store), [])
        readAhead.waitForIdle()
        XCTAssertNil(readAhead.bytesRead(path: store.path))
        XCTAssertNil(readAhead.bytesRead(path: wal))
        // First-ever run: the file is created later in the same process and is read ahead then.
        try write(store.path, bytes: 2000)
        XCTAssertEqual(readAhead.prefetch(store: store), [store.path])
        readAhead.waitForIdle()
        XCTAssertEqual(readAhead.bytesRead(path: store.path), 2000)
    }

    func test_unreadableFileFailsSilently() throws {
        try write(store.path, bytes: 1000)
        try FileManager.default.setAttributes([.posixPermissions: 0], ofItemAtPath: store.path)
        let readAhead = make()
        readAhead.prefetch(store: store)
        readAhead.waitForIdle()
        XCTAssertEqual(readAhead.bytesRead(path: store.path), 0)
    }

    func test_neverModifiesTheFile() throws {
        try write(store.path, bytes: 4096)
        let before = try Data(contentsOf: store)
        let attributes = try FileManager.default.attributesOfItem(atPath: store.path)
        let readAhead = make()
        readAhead.prefetch(store: store)
        readAhead.waitForIdle()
        XCTAssertEqual(try Data(contentsOf: store), before)
        XCTAssertEqual(try FileManager.default.attributesOfItem(atPath: store.path)[.modificationDate] as? Date,
                       attributes[.modificationDate] as? Date)
    }

    func test_builderReadsAheadOnlyWhenGiven() throws {
        let name = "readahead_\(UUID().uuidString.prefix(8))"
        let caches = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).last!
        let url = caches.appendingPathComponent("\(name).\(ServiceConstants.databaseExtension)")
        defer {
            for suffix in ["", "-wal", "-shm"] { try? FileManager.default.removeItem(atPath: url.path + suffix) }
        }
        // Without a read-ahead the builder must not touch the shared instance either. The first build
        // creates the store file, so the second one would claim it if the shared instance were the default.
        XCTAssertNotNil(CoreDataHelperBuilder.build(databaseName: name))
        XCTAssertTrue(FileManager.default.fileExists(atPath: url.path))
        XCTAssertNotNil(CoreDataHelperBuilder.build(databaseName: name))
        CacheReadAhead.shared.waitForIdle()
        XCTAssertNil(CacheReadAhead.shared.bytesRead(path: url.path))
        XCTAssertEqual(CacheReadAhead.shared.readCount(path: url.path), 0)

        let on = make()
        XCTAssertNotNil(CoreDataHelperBuilder.build(databaseName: name, readAhead: on))
        on.waitForIdle()
        XCTAssertNotNil(on.bytesRead(path: url.path))
        // The "-wal" read is covered by test_readsStoreAndWal: the WAL may not exist yet on a fresh database.
    }

    // MARK: - Claims and wiring

    private func uniqueDatabase() -> (name: String, url: URL) {
        let name = "readahead_\(UUID().uuidString.prefix(8))"
        let caches = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).last!
        return (name, caches.appendingPathComponent("\(name).\(ServiceConstants.databaseExtension)"))
    }

    private func removeDatabase(_ url: URL) {
        for suffix in ["", "-wal", "-shm"] { try? FileManager.default.removeItem(atPath: url.path + suffix) }
    }

    private func buildContainer(databaseName: String, apiKey: String) throws {
        _ = try SplitDatabaseHelper.buildStorageContainer(
            splitClientConfig: SplitClientConfig(), apiKey: apiKey, userKey: "key",
            databaseName: databaseName, telemetryStorage: nil, testDatabase: nil,
            timeChecker: TimeChecker.forTesting())
    }

    func test_twoInstances_bothClaimTheSameFile() throws {
        try write(store.path, bytes: 100)
        let first = make()
        let second = make()
        XCTAssertEqual(first.prefetch(store: store), [store.path])
        XCTAssertEqual(second.prefetch(store: store), [store.path])
        first.waitForIdle()
        second.waitForIdle()
        XCTAssertEqual(first.readCount(path: store.path), 1)
        XCTAssertEqual(second.readCount(path: store.path), 1)
    }

    func test_builderDoesNotClaimAFileThatDoesNotExistYet() throws {
        let database = uniqueDatabase()
        defer { removeDatabase(database.url) }
        let readAhead = make()
        XCTAssertNotNil(CoreDataHelperBuilder.build(databaseName: database.name, readAhead: readAhead))
        readAhead.waitForIdle()
        XCTAssertEqual(readAhead.readCount(path: database.url.path), 0)
        XCTAssertNil(readAhead.bytesRead(path: database.url.path))
    }

    func test_repeatedStorageContainerBuilds_readTheStoreOnce() throws {
        let database = uniqueDatabase()
        defer { removeDatabase(database.url) }
        let apiKey = UUID().uuidString
        // The first build creates the file, the next ones find it and the shared instance reads it once.
        for _ in 0..<3 {
            try buildContainer(databaseName: database.name, apiKey: apiKey)
        }
        CacheReadAhead.shared.waitForIdle()
        XCTAssertEqual(CacheReadAhead.shared.readCount(path: database.url.path), 1)
    }

    func test_concurrentPrefetch_claimsEachPathOnce() throws {
        let files = 200
        let hitsPerFile = 8
        let stores = try (0..<files).map { index -> URL in
            let url = directory.appendingPathComponent("s\(index).sqlite")
            try write(url.path, bytes: 10)
            return url
        }
        let readAhead = make()
        let resultsLock = NSLock()
        var claimed = [String]()
        DispatchQueue.concurrentPerform(iterations: files * hitsPerFile) { iteration in
            let fresh = readAhead.prefetch(store: stores[iteration / hitsPerFile])
            resultsLock.lock()
            claimed.append(contentsOf: fresh)
            resultsLock.unlock()
        }
        readAhead.waitForIdle()
        XCTAssertEqual(claimed.count, files)
        XCTAssertEqual(Set(claimed), Set(stores.map { $0.path }))
        XCTAssertTrue(stores.allSatisfy { readAhead.readCount(path: $0.path) == 1 })
    }
}
