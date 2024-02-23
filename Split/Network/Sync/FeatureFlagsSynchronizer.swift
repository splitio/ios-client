//
//  FeatureFlagsSynchronizer.swift
//  Split
//
//  Created by Javier Avrudsky on 02/06/2023.
//  Copyright © 2023 Split. All rights reserved.
//

import Foundation

protocol FeatureFlagsSynchronizer {
    func load()
    func synchronize()
    func synchronize(changeNumber: Int64)
    func startPeriodicSync()
    func stopPeriodicSync()
    func notifyKilled()
    func notifyUpdated()
    func pause()
    func resume()
    func stop()
}

class DefaultFeatureFlagsSynchronizer: FeatureFlagsSynchronizer {

    private var storageContainer: SplitStorageContainer
    private var splitsSyncWorker: RetryableSyncWorker!
    private let splitsFilterQueryString: String
    private let syncTaskByChangeNumberCatalog: ConcurrentDictionary<Int64, RetryableSyncWorker>
    private let syncWorkerFactory: SyncWorkerFactory
    private let splitConfig: SplitClientConfig
    private let splitEventsManager: SplitEventsManager
    private var periodicSplitsSyncWorker: PeriodicSyncWorker?
    private var broadcasterChannel: SyncEventBroadcaster

    init(splitConfig: SplitClientConfig,
         storageContainer: SplitStorageContainer,
         syncWorkerFactory: SyncWorkerFactory,
         broadcasterChannel: SyncEventBroadcaster,
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
        self.broadcasterChannel = broadcasterChannel

        if splitConfig.syncEnabled {
            self.periodicSplitsSyncWorker = syncWorkerFactory.createPeriodicSplitsSyncWorker()
            self.splitsSyncWorker.completion = {[weak self] success in
                if let self = self, success {
                    self.broadcasterChannel.push(event: .syncExecuted)
                }
            }
            self.splitsSyncWorker.errorHandler = {[weak self] error in
                guard let self = self else { return }
                if let error = error as? HttpError, error == HttpError.uriTooLong {
                    self.broadcasterChannel.push(event: .uriTooLongOnSync)
                }
            }
        }
    }

    func load() {
        let splitsStorage = self.storageContainer.splitsStorage
        DispatchQueue.global().async {
            let start = Date.nowMillis()
            self.filterSplitsInCache()
            splitsStorage.loadLocal()
            if splitsStorage.getAll().count > 0 {
                self.splitEventsManager.notifyInternalEvent(.splitsLoadedFromCache)
            }
            self.broadcasterChannel.push(event: .splitLoadedFromCache)
            TimeChecker.logInterval("Time for ready from cache process", startTime: start)
            TimeChecker.logInterval("Time until feature flags process ended")
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
            worker.completion = {[weak self] success in
                if let self = self, success {
                    self.broadcasterChannel.push(event: .syncExecuted)
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

    func notifyUpdated() {
        splitEventsManager.notifyInternalEvent(.splitsUpdated)
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
        let setsToKeep = Set(filters.filter { $0.type == .bySet }.flatMap { $0.values })

        let splitsInCache = splitsStorage.getAll()
        var toDelete = [String]()

        for split in splitsInCache {
            guard let splitName = split.name else {
                continue
            }

            let prefix = getPrefix(for: splitName) ?? ""
            if setsToKeep.count > 0 && setsToKeep.isDisjoint(with: split.sets ?? Set()) {
                toDelete.append(splitName)
            } else if (prefix == "" && namesToKeep.count > 0 && !namesToKeep.contains(splitName)) ||
                (prefixesToKeep.count > 0 && prefix != "" && !prefixesToKeep.contains(prefix)) {
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
            return String(splitName.prefix(upTo: range.lowerBound))
        }
        return nil
    }
}
