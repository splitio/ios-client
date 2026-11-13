//
//  BenchmarkRealDriver.swift
//  SplitBenchmark
//
//  FME-22007: the real `BenchmarkDriver`. Does not import XCTest.
//
//  One `DefaultSplitFactoryBuilder` per factory, never reused, with a per-factory `StageMarkBuffer` as its
//  mark recorder, so stage marks (and the database decode timing inside them) are attributed per factory.
//
//  Cache: the SDK reads <caches>/<first 4 + last 4 chars of the API key>.sqlite. `prepareCache` fills that
//  store from the fixture file through the SDK's own persistence layer (decoded flags, change number, update
//  timestamp, cache integrity version and flag spec, so no validation clears it). A sidecar file
//  `<name>.benchhash` holds the payload hash the store was populated from; a store without it, or with a
//  different hash (for example after a stress run), is deleted and populated again. Endpoints default to
//  offline (127.0.0.1:1): the measured interval is the cache path only. `-benchEndpoint` overrides both; scenario
//  D needs one that answers, because an empty cache only reaches ready-from-cache after a successful fetch.
//

import Foundation
@testable import Split

final class RealBenchmarkDriver: BenchmarkDriver, @unchecked Sendable {

    private final class ReadyListener: NSObject, SplitEventListener, @unchecked Sendable {
        private let fire: @Sendable () -> Void
        init(fire: @escaping @Sendable () -> Void) { self.fire = fire }
        func onReadyFromCache(_ metadata: SdkReadyFromCacheMetadata) { fire() }
    }

    private let arguments: BenchmarkArguments
    private let payload: BenchmarkPayload
    private let lock = NSLock()
    private var buffers = [Int: StageMarkBuffer]()
    private var clients = [SplitClient]()
    private var listeners = [ReadyListener]()
    private var builderList = [DefaultSplitFactoryBuilder]()
    private var factories = [SplitFactory]()

    /// Every builder this driver created, in build order. Held strongly so identity checks cannot alias.
    var builders: [DefaultSplitFactoryBuilder] { lock.lock(); defer { lock.unlock() }; return builderList }

    init(arguments: BenchmarkArguments, payload: BenchmarkPayload) {
        self.arguments = arguments
        self.payload = payload
    }

    func now() -> UInt64 { return DispatchTime.now().uptimeNanoseconds }
    func thermalState() -> ProcessInfo.ThermalState { return ProcessInfo.processInfo.thermalState }
    func wallClock() -> Date { return Date() }

    private func makeConfig() -> SplitClientConfig {
        let config = SplitClientConfig()
        let endpoint = arguments.endpoint ?? "http://127.0.0.1:1"
        config.serviceEndpoints = ServiceEndpoints.builder().set(sdkEndpoint: endpoint)
            .set(eventsEndpoint: endpoint).build()
        config.streamingEnabled = false
        config.sdkReadyTimeOut = 20000
        config.logLevel = arguments.logging.configLogLevel
        return config
    }

    func build(_ spec: BenchmarkFactorySpec, readyAPI: ReadyAPI,
               onReadyFromCache: @escaping @Sendable () -> Void) -> Bool {
        let buffer = StageMarkBuffer()
        let builder = DefaultSplitFactoryBuilder()
        lock.lock()
        builderList.append(builder)
        buffers[spec.position] = buffer
        lock.unlock()

        _ = builder.setInternalSeam(arguments.makeSeam(markRecorder: buffer.sink))
        guard let factory = builder.setApiKey(spec.apiKey).setKey(Key(matchingKey: spec.matchingKey))
            .setConfig(makeConfig()).build() else { return false }
        let client = factory.client
        lock.lock()
        factories.append(factory)
        clients.append(client)
        lock.unlock()

        switch readyAPI {
        case .on:
            client.on(event: .sdkReadyFromCache) { onReadyFromCache() }
        case .listener:
            let listener = ReadyListener(fire: onReadyFromCache)
            lock.lock()
            listeners.append(listener)
            lock.unlock()
            client.addEventListener(listener: listener)
        }
        return true
    }

    func marks(position: Int) -> [BenchmarkCSVRow.Mark] {
        lock.lock()
        defer { lock.unlock() }
        return buffers[position]?.marks ?? []
    }

    func waitUntil(timeout: TimeInterval, _ condition: () -> Bool) -> Bool {
        let deadline = Date().addingTimeInterval(timeout)
        while !condition() {
            if Date() >= deadline { return false }
            if !RunLoop.current.run(mode: .default, before: Date().addingTimeInterval(0.005)) {
                Thread.sleep(forTimeInterval: 0.002)
            }
        }
        return true
    }

    func shutdown() {
        lock.lock()
        let toDestroy = clients
        clients = []
        lock.unlock()
        toDestroy.forEach { $0.destroy() }
    }

    // MARK: Cache

    private func databaseName(_ apiKey: String) -> String {
        return SplitDatabaseHelper.databaseName(prefix: makeConfig().prefix, apiKey: apiKey) ?? apiKey
    }

    private var cachesDirectory: URL {
        return FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
    }

    private func storeURL(_ name: String) -> URL {
        return cachesDirectory.appendingPathComponent("\(name).\(ServiceConstants.databaseExtension)")
    }

    private func sidecarURL(_ name: String) -> URL {
        return cachesDirectory.appendingPathComponent("\(name).benchhash")
    }

    func deleteCache(apiKey: String) {
        let name = databaseName(apiKey)
        let store = storeURL(name).path
        for path in [store, store + "-shm", store + "-wal", sidecarURL(name).path] {
            try? FileManager.default.removeItem(atPath: path)
        }
    }

    func prepareCache(apiKey: String) throws -> Bool {
        let name = databaseName(apiKey)
        let populatedHash = try? String(contentsOf: sidecarURL(name), encoding: .utf8)
        if FileManager.default.fileExists(atPath: storeURL(name).path) && populatedHash == payload.hash {
            return false
        }
        deleteCache(apiKey: apiKey)
        try populate(databaseName: name)
        try payload.hash.write(to: sidecarURL(name), atomically: true, encoding: .utf8)
        return true
    }

    private func populate(databaseName name: String) throws {
        let data = try Data(contentsOf: payload.fileURL)
        guard let object = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let flags = object["splits"] as? [[String: Any]] else {
            throw CocoaError(.fileReadCorruptFile)
        }
        let till = (object["till"] as? NSNumber)?.int64Value ?? 0
        let splits = try flags.map { flag -> Split in
            try Json.decodeFrom(json: try JSONSerialization.data(withJSONObject: flag), to: Split.self)
        }

        guard let helper = CoreDataHelperBuilder.build(databaseName: name) else {
            throw GenericError.couldNotCreateCache
        }
        let database = CoreDataSplitDatabase(coreDataHelper: helper,
                                             timeChecker: TimeChecker(factoryId: 0, startTime: Date.nowMillis()))
        let persistent = DefaultPersistentSplitsStorage(database: database)
        persistent.update(splitChange: ProcessedSplitChange(activeSplits: splits, archivedSplits: [],
                                                            changeNumber: till, updateTimestamp: Date.now()),
                          onFailure: nil)
        helper.performAndWait {}
        let info = DefaultGeneralInfoStorage(database: database)
        info.setFlagSpec(flagsSpec: Spec.flagsSpec)
        info.setCacheIntegrityVersion(DefaultRolloutCacheManager.cacheIntegrityVersion)
        helper.performAndWait {}
        helper.save()
    }
}
