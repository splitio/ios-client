//
//  CoreDataHelperBuilder.swift
//  Split
//
//  Created by Javier L. Avrudsky on 27/01/2021.
//  Copyright © 2020 Split. All rights reserved.
//

import Foundation
import CoreData

/// Read-ahead of the cache file, on by default for every factory. Reads `<store>` and
/// `<store>-wal` sequentially on a background queue so their pages are in the OS file cache before the first
/// fetch. Read-only, at most once per existing file and process, skips files over the 64 MB cap (never partially
/// read), runs at user-initiated QoS because the first fetch waits on it, and ignores every failure. A file that
/// does not exist yet (first-ever run) is not claimed, so a later factory in the same process can still read it.
final class CacheReadAhead: @unchecked Sendable {
    static let shared = CacheReadAhead()
    static let defaultMaxBytes = 64 * 1024 * 1024
    private static let chunkBytes = 256 * 1024

    private let maxBytes: Int
    private let queue: DispatchQueue
    private let lock = NSLock()
    private var claimed = Set<String>()
    private var reads = [String: (bytes: Int, count: Int)]()

    init(maxBytes: Int = CacheReadAhead.defaultMaxBytes,
         queue: DispatchQueue = DispatchQueue(label: "io.split.cache-read-ahead", qos: .userInitiated)) {
        self.maxBytes = maxBytes
        self.queue = queue
    }

    /// Schedules the read of the store and its WAL; returns the paths not already claimed by an earlier call.
    @discardableResult
    func prefetch(store: URL) -> [String] {
        let fresh = [store.path, store.path + "-wal"].filter { path in
            guard FileManager.default.fileExists(atPath: path) else { return false }
            lock.lock()
            defer { lock.unlock() }
            return claimed.insert(path).inserted
        }
        for path in fresh {
            queue.async { [weak self] in self?.read(path) }
        }
        return fresh
    }

    /// Bytes read from `path`; 0 when skipped or unreadable, nil when never scheduled or still pending.
    func bytesRead(path: String) -> Int? {
        lock.lock()
        defer { lock.unlock() }
        return reads[path]?.bytes
    }

    func readCount(path: String) -> Int {
        lock.lock()
        defer { lock.unlock() }
        return reads[path]?.count ?? 0
    }

    func waitForIdle() {
        queue.sync {}
    }

    private func read(_ path: String) {
        var total = 0
        defer {
            lock.lock()
            reads[path] = (bytes: total, count: (reads[path]?.count ?? 0) + 1)
            lock.unlock()
        }
        let descriptor = open(path, O_RDONLY)
        guard descriptor >= 0 else { return }
        defer { close(descriptor) }
        var info = stat()
        guard fstat(descriptor, &info) == 0, Int(info.st_size) <= maxBytes else { return }
        var buffer = [UInt8](repeating: 0, count: Self.chunkBytes)
        while total < maxBytes {
            let count = buffer.withUnsafeMutableBytes { Darwin.read(descriptor, $0.baseAddress, $0.count) }
            if count <= 0 { break }
            total += count
        }
    }
}

class CoreDataHelperBuilder {

    private static let kDataModelName = "split_cache"
    private static let kDataModelExtentsion = "momd"

    static func build(databaseName: String, readAhead: CacheReadAhead? = nil) -> CoreDataHelper? {

        let bundle = Bundle.split
        guard let modelUrl = bundle.url(forResource: kDataModelName, withExtension: kDataModelExtentsion) else {
            Logger.e("Error loading model from bundle")
            return nil
        }

        guard let modelFile = NSManagedObjectModel(contentsOf: modelUrl) else {
            Logger.e("Error initializing mom from: \(modelUrl)")
            return nil
        }

        let persistenceCoordinator = NSPersistentStoreCoordinator(managedObjectModel: modelFile)

        let managedObjContext = NSManagedObjectContext(
            concurrencyType: NSManagedObjectContextConcurrencyType.privateQueueConcurrencyType)

        managedObjContext.mergePolicy = NSMergePolicy(merge: .mergeByPropertyObjectTrumpMergePolicyType)
        managedObjContext.persistentStoreCoordinator = persistenceCoordinator

        guard let docURL = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).last else {
            Logger.e("Unable to resolve document directory")
            return nil
        }

        let databaseUrl = docURL.appendingPathComponent("\(databaseName).\(ServiceConstants.databaseExtension)")
        Logger.v("Cache URL: \(databaseUrl.absoluteString)")
        readAhead?.prefetch(store: databaseUrl)
        do {
            let options = [NSMigratePersistentStoresAutomaticallyOption: true,
                           NSInferMappingModelAutomaticallyOption: true]
            try persistenceCoordinator.addPersistentStore(ofType: NSSQLiteStoreType,
                                                          configurationName: nil,
                                                          at: databaseUrl, options: options)

            return CoreDataHelper(managedObjectContext: managedObjContext,
                                  persistentCoordinator: persistenceCoordinator)

        } catch {
            return nil
        }
    }
}
