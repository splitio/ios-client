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
    func synchronize(changeNumber: Int64?, rbsChangeNumber: Int64?)
    func startPeriodicSync()
    func stopPeriodicSync()
    func notifyKilled()
    func notifyUpdated()
    func pause()
    func resume()
    func destroy()
}

class DefaultFeatureFlagsSynchronizer: FeatureFlagsSynchronizer {

    private var storageContainer: SplitStorageContainer
    private var splitsSyncWorker: RetryableSyncWorker!
    private let splitsFilterQueryString: String
    private let flagsSpec: String
    private let syncTaskByChangeNumberCatalog: ConcurrentDictionary<SplitsUpdateChangeNumber, RetryableSyncWorker>
    private let syncWorkerFactory: SyncWorkerFactory
    private let splitConfig: SplitClientConfig
    private let splitEventsManager: SplitEventsManager
    private var periodicSplitsSyncWorker: PeriodicSyncWorker?
    private var broadcasterChannel: SyncEventBroadcaster
    private var isDestroyed = Atomic(false)

    init(splitConfig: SplitClientConfig,
         storageContainer: SplitStorageContainer,
         syncWorkerFactory: SyncWorkerFactory,
         broadcasterChannel: SyncEventBroadcaster,
         syncTaskByChangeNumberCatalog: ConcurrentDictionary<SplitsUpdateChangeNumber, RetryableSyncWorker>
        = ConcurrentDictionary<SplitsUpdateChangeNumber, RetryableSyncWorker>(),
         splitsFilterQueryString: String,
         flagsSpec: String,
         splitEventsManager: SplitEventsManager) {

        self.splitConfig = splitConfig
        self.storageContainer = storageContainer
        self.syncWorkerFactory = syncWorkerFactory
        self.syncTaskByChangeNumberCatalog = syncTaskByChangeNumberCatalog

        self.splitsSyncWorker = syncWorkerFactory.createRetryableSplitsSyncWorker()
        self.splitsFilterQueryString = splitsFilterQueryString
        self.flagsSpec = flagsSpec
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

        if isDestroyed.value {
            return
        }

        let splitsStorage = storageContainer.splitsStorage
        let ruleBasedSegmentsStorage = storageContainer.ruleBasedSegmentsStorage
        let shouldReParse = (storageContainer.generalInfoStorage.getSegmentsInUse() == nil) // Part of /memberships hits optimization
        
        DispatchQueue.general.async {
            let start = Date.nowMillis()
            self.filterSplitsInCache()
            splitsStorage.loadLocal(forceReparse: shouldReParse)
            ruleBasedSegmentsStorage.loadLocal(forceReparse: shouldReParse)
            if splitsStorage.getAll().count > 0 {
                self.splitEventsManager.notifyInternalEvent(.splitsLoadedFromCache)
            }
            self.broadcasterChannel.push(event: .splitLoadedFromCache)
            Logger.v("Notifying Splits loaded from cache")
            TimeChecker.logInterval("Time for ready from cache process", startTime: start)
            TimeChecker.logInterval("Time until feature flags process ended")
        }
    }

    func synchronize() {
        if isDestroyed.value {
            return
        }
        splitsSyncWorker.start()
    }

    func synchronize(changeNumber: Int64? = nil, rbsChangeNumber: Int64? = nil) {
        if isDestroyed.value || !splitConfig.syncEnabled {
            return
        }

        if let changeNumber, changeNumber <= storageContainer.splitsStorage.changeNumber {
            return
        }

        if let rbsChangeNumber, rbsChangeNumber <= storageContainer.ruleBasedSegmentsStorage.changeNumber {
            return
        }

        let changeNumberConfig = SplitsUpdateChangeNumber(flags: changeNumber, rbs: rbsChangeNumber)

        if syncTaskByChangeNumberCatalog.value(forKey: changeNumberConfig) == nil {
            let reconnectBackoff = DefaultReconnectBackoffCounter(backoffBase: splitConfig.generalRetryBackoffBase)
            var worker = syncWorkerFactory.createRetryableSplitsUpdateWorker(changeNumber: changeNumberConfig,
                                                                             reconnectBackoffCounter: reconnectBackoff)
            syncTaskByChangeNumberCatalog.setValue(worker, forKey: changeNumberConfig)
            worker.start()
            worker.completion = {[weak self] success in
                if let self = self, success {
                    self.broadcasterChannel.push(event: .syncExecuted)
                    self.syncTaskByChangeNumberCatalog.removeValue(forKey: changeNumberConfig)
                }
            }
        }
    }

    func startPeriodicSync() {
        if isDestroyed.value {
            return
        }
        periodicSplitsSyncWorker?.start()
    }

    func stopPeriodicSync() {
        if isDestroyed.value {
            return
        }
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
        if isDestroyed.value {
            return
        }
        periodicSplitsSyncWorker?.resume()
    }

    func destroy() {
        isDestroyed.set(true)
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
        let generalInfoStorage = storageContainer.generalInfoStorage
        let currentSplitsQueryString = splitsFilterQueryString

        let filterHasChanged = currentSplitsQueryString != generalInfoStorage.getSplitsFilterQueryString()
        let flagsSpecHasChanged = flagsSpec != generalInfoStorage.getFlagSpec()

        // if neither the filter nor the flags spec have changed, we don't need to do anything
        if filterHasChanged || flagsSpecHasChanged {
            let splitsInCache = splitsStorage.getAll()

            if flagsSpecHasChanged {
                // when flagsSpec has changed, we delete everything
                splitsStorage.clear()
                storageContainer.generalInfoStorage.setFlagSpec(flagsSpec: flagsSpec)
            } else if filterHasChanged {

                // if the filter has changed, we need to delete according to it
                var toDelete = [String]()
                let filters = splitConfig.sync.filters
                let namesToKeep = Set(filters.filter { $0.type == .byName }.flatMap { $0.values })
                let prefixesToKeep = Set(filters.filter { $0.type == .byPrefix }.flatMap { $0.values })
                let setsToKeep = Set(filters.filter { $0.type == .bySet }.flatMap { $0.values })

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
                generalInfoStorage.setSplitsFilterQueryString(filterQueryString: currentSplitsQueryString)
            }
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
