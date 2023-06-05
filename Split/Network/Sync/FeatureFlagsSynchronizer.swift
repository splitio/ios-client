//
//  FeatureFlagsSynchronizer.swift
//  Split
//
//  Created by Javier Avrudsky on 02/06/2023.
//  Copyright © 2023 Split. All rights reserved.
//

import Foundation

protocol FeatureFlagsSynchronizer {
    func loadAndSynchronize()
    func synchronize()
    func synchronize(changeNumber: Int64)
    func startPeriodicSync()
    func stopPeriodicSync()
    func notifyKilled()
    func pause()
    func resume()
    func stop()
}


class DefaultFeatureFlagsSynchronizer: FeatureFlagsSynchronizer {

    private var storageContainer: SplitStorageContainer
    private let splitsSyncWorker: RetryableSyncWorker!
    private let splitsFilterQueryString: String
    private let syncTaskByChangeNumberCatalog: ConcurrentDictionary<Int64, RetryableSyncWorker>
    private let syncWorkerFactory: SyncWorkerFactory
    private let splitConfig: SplitClientConfig
    private let splitEventsManager: SplitEventsManager
    private var periodicSplitsSyncWorker: PeriodicSyncWorker?

    init(splitConfig: SplitClientConfig,
         storageContainer: SplitStorageContainer,
         syncWorkerFactory: SyncWorkerFactory,
         syncTaskByChangeNumberCatalog: ConcurrentDictionary<Int64, RetryableSyncWorker>
        = ConcurrentDictionary<Int64, RetryableSyncWorker>(),
         splitsFilterQueryString: String,
         splitEventsManager: SplitEventsManager) {

        self.splitConfig = splitConfig
        self.storageContainer = storageContainer
        self.syncWorkerFactory = syncWorkerFactory
        self.syncTaskByChangeNumberCatalog = syncTaskByChangeNumberCatalog

        self.splitsSyncWorker = syncWorkerFactory.createRetryableSplitsSyncWorker()
        self.splitsFilterQueryString = splitsFilterQueryString
        self.splitEventsManager = splitEventsManager

        if splitConfig.syncEnabled {
            self.periodicSplitsSyncWorker = syncWorkerFactory.createPeriodicSplitsSyncWorker()
        }
    }

    func loadAndSynchronize() {
        let splitsStorage = self.storageContainer.splitsStorage
        DispatchQueue.global().async {
            self.filterSplitsInCache()
            splitsStorage.loadLocal()
            if splitsStorage.getAll().count > 0 {
                self.splitEventsManager.notifyInternalEvent(.splitsLoadedFromCache)
            }
            self.synchronize()
        }
    }

    func synchronize() {
        splitsSyncWorker.start()
    }

    func synchronize(changeNumber: Int64) {
        if !splitConfig.syncEnabled {
            return
        }

        if changeNumber <= storageContainer.splitsStorage.changeNumber {
            return
        }

        if syncTaskByChangeNumberCatalog.value(forKey: changeNumber) == nil {
            let reconnectBackoff = DefaultReconnectBackoffCounter(backoffBase: splitConfig.generalRetryBackoffBase)
            var worker = syncWorkerFactory.createRetryableSplitsUpdateWorker(changeNumber: changeNumber,
                                                                             reconnectBackoffCounter: reconnectBackoff)
            syncTaskByChangeNumberCatalog.setValue(worker, forKey: changeNumber)
            worker.start()
            worker.completion = {[weak self] _ in
                if let self = self {
                    self.syncTaskByChangeNumberCatalog.removeValue(forKey: changeNumber)
                }
            }
        }
    }

    func startPeriodicSync() {
        periodicSplitsSyncWorker?.start()
    }

    func stopPeriodicSync() {
        periodicSplitsSyncWorker?.stop()
    }

    func notifyKilled() {
        splitEventsManager.notifyInternalEvent(.splitKilledNotification)
    }

    func pause() {
        periodicSplitsSyncWorker?.pause()
    }

    func resume() {
        periodicSplitsSyncWorker?.resume()
    }

    func stop() {
        splitsSyncWorker.stop()
        periodicSplitsSyncWorker?.stop()
        periodicSplitsSyncWorker?.destroy()
        let updateTasks = syncTaskByChangeNumberCatalog.takeAll()
        for task in updateTasks.values {
            task.stop()
        }
    }

    private func filterSplitsInCache() {
        let splitsStorage = storageContainer.persistentSplitsStorage
        let currentSplitsQueryString = splitsFilterQueryString
        if currentSplitsQueryString == splitsStorage.getFilterQueryString() {
            return
        }

        let filters = splitConfig.sync.filters
        let namesToKeep = Set(filters.filter { $0.type == .byName }.flatMap { $0.values })
        let prefixesToKeep = Set(filters.filter { $0.type == .byPrefix }.flatMap { $0.values })

        let splitsInCache = splitsStorage.getAll()
        var toDelete = [String]()

        for split in splitsInCache {
            guard let splitName = split.name else {
                continue
            }

            let prefix = getPrefix(for: splitName) ?? ""
            if !namesToKeep.contains(splitName), (prefix == "" || !prefixesToKeep.contains(prefix)) {
                toDelete.append(splitName)
            }

        }
        if toDelete.count > 0 {
            splitsStorage.delete(splitNames: toDelete)
            storageContainer.splitDatabase.generalInfoDao.update(info: .splitsChangeNumber, longValue: -1)
        }
    }

    private func getPrefix(for splitName: String) -> String? {
        let kPrefixSeparator = "__"
        if let range = splitName.range(of: kPrefixSeparator),
           range.lowerBound != splitName.startIndex, range.upperBound != splitName.endIndex {
            return String(splitName[range.upperBound...])
        }
        return nil
    }
}
