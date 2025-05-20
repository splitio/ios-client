//
//  SplitsWorkerFactory.swift
//  Split
//
//  Created by Javier L. Avrudsky on 21/09/2020.
//  Copyright © 2020 Split. All rights reserved.
//

import Foundation

/// Helper to allow unit testing of some features by stubbing it
protocol MySegmentsSyncWorkerFactory {
    func createRetryableMySegmentsSyncWorker(forKey key: String,
                                             avoidCache: Bool,
                                             eventsManager: SplitEventsManager,
                                             changeNumbers: SegmentsChangeNumber?) -> RetryableSyncWorker

    func createPeriodicMySegmentsSyncWorker(forKey key: String,
                                            eventsManager: SplitEventsManager) -> PeriodicSyncWorker
}

protocol SyncWorkerFactory {

    func createRetryableSplitsSyncWorker() -> RetryableSyncWorker

    func createPeriodicSplitsSyncWorker() -> PeriodicSyncWorker

    func createRetryableSplitsUpdateWorker(changeNumber: SplitsUpdateChangeNumber,
                                           reconnectBackoffCounter: ReconnectBackoffCounter
    ) -> RetryableSyncWorker

    func createPeriodicImpressionsRecorderWorker(syncHelper: ImpressionsRecorderSyncHelper?) -> PeriodicRecorderWorker?

    func createImpressionsRecorderWorker(syncHelper: ImpressionsRecorderSyncHelper?) -> RecorderWorker?

    func createImpressionsCountRecorderWorker() -> RecorderWorker

    func createPeriodicImpressionsCountRecorderWorker() -> PeriodicRecorderWorker

    func createPeriodicEventsRecorderWorker(syncHelper: EventsRecorderSyncHelper?) -> PeriodicRecorderWorker

    func createEventsRecorderWorker(syncHelper: EventsRecorderSyncHelper?) -> RecorderWorker

    func createUniqueKeyRecorderWorker(flusherChecker: RecorderFlushChecker?) -> RecorderWorker

    func createPeriodicUniqueKeyRecorderWorker(flusherChecker: RecorderFlushChecker?) -> PeriodicRecorderWorker

    func createTelemetryConfigRecorderWorker() -> RecorderWorker?

    func createTelemetryStatsRecorderWorker() -> RecorderWorker?

    func createPeriodicTelemetryStatsRecorderWorker() -> PeriodicRecorderWorker?
}

struct SplitsUpdateChangeNumber: Hashable {
    let flags: Int64?
    let rbs: Int64?

    init(flags: Int64?, rbs: Int64?) {
        self.flags = flags
        self.rbs = rbs
    }
}

class DefaultSyncWorkerFactory: SyncWorkerFactory {

    private let storageContainer: SplitStorageContainer
    private let apiFacade: SplitApiFacade
    private let splitConfig: SplitClientConfig
    private let splitChangeProcessor: SplitChangeProcessor
    private let ruleBasedSegmentChangeProcessor: RuleBasedSegmentChangeProcessor
    private let userKey: String
    private let eventsManager: SplitEventsManager
    private let splitsFilterQueryString: String
    private let flagsSpec: String
    private let telemetryProducer: TelemetryProducer?

    init(userKey: String,
         splitConfig: SplitClientConfig,
         splitsFilterQueryString: String,
         flagsSpec: String,
         apiFacade: SplitApiFacade,
         storageContainer: SplitStorageContainer,
         splitChangeProcessor: SplitChangeProcessor,
         ruleBasedSegmentChangeProcessor: RuleBasedSegmentChangeProcessor,
         eventsManager: SplitEventsManager) {

        self.userKey = userKey
        self.splitConfig = splitConfig
        self.splitsFilterQueryString = splitsFilterQueryString
        self.flagsSpec = flagsSpec
        self.apiFacade = apiFacade
        self.storageContainer = storageContainer
        self.splitChangeProcessor = splitChangeProcessor
        self.ruleBasedSegmentChangeProcessor = ruleBasedSegmentChangeProcessor
        self.eventsManager = eventsManager
        self.telemetryProducer = storageContainer.telemetryStorage
    }

    func createRetryableSplitsSyncWorker() -> RetryableSyncWorker {
        let backoffCounter = DefaultReconnectBackoffCounter(backoffBase: splitConfig.generalRetryBackoffBase)
        return RetryableSplitsSyncWorker(splitFetcher: apiFacade.splitsFetcher,
                                         splitsStorage: storageContainer.splitsStorage,
                                         generalInfoStorage: storageContainer.generalInfoStorage,
                                         ruleBasedSegmentsStorage: storageContainer.ruleBasedSegmentsStorage,
                                         splitChangeProcessor: splitChangeProcessor,
                                         ruleBasedSegmentChangeProcessor: ruleBasedSegmentChangeProcessor,
                                         eventsManager: eventsManager,
                                         reconnectBackoffCounter: backoffCounter,
                                         splitConfig: splitConfig)
    }

    func createRetryableSplitsUpdateWorker(changeNumber: SplitsUpdateChangeNumber,
                                           reconnectBackoffCounter: ReconnectBackoffCounter) -> RetryableSyncWorker {
        return RetryableSplitsUpdateWorker(splitsFetcher: apiFacade.splitsFetcher,
                                           splitsStorage: storageContainer.splitsStorage,
                                           ruleBasedSegmentsStorage: storageContainer.ruleBasedSegmentsStorage,
                                           generalInfoStorage: storageContainer.generalInfoStorage,
                                           splitChangeProcessor: splitChangeProcessor,
                                           ruleBasedSegmentChangeProcessor: ruleBasedSegmentChangeProcessor,
                                           changeNumber: changeNumber,
                                           eventsManager: eventsManager,
                                           reconnectBackoffCounter: reconnectBackoffCounter,
                                           splitConfig: splitConfig)
    }

    func createPeriodicSplitsSyncWorker() -> PeriodicSyncWorker {
        
        return  PeriodicSplitsSyncWorker(
            splitFetcher: apiFacade.splitsFetcher, splitsStorage: storageContainer.splitsStorage,
            generalInfoStorage: storageContainer.generalInfoStorage,
            ruleBasedSegmentsStorage: storageContainer.ruleBasedSegmentsStorage,
            splitChangeProcessor: splitChangeProcessor,
            ruleBasedSegmentsChangeProcessor: ruleBasedSegmentChangeProcessor,
            timer: DefaultPeriodicTimer(interval: splitConfig.featuresRefreshRate),
            eventsManager: eventsManager, splitConfig: splitConfig)
    }

    func createPeriodicImpressionsRecorderWorker(
        syncHelper: ImpressionsRecorderSyncHelper?) -> PeriodicRecorderWorker? {

        guard let impressionsRecorder = apiFacade.impressionsRecorder else {
            return nil
        }

        let impressionWorker = ImpressionsRecorderWorker(persistentImpressionsStorage:
                                                            storageContainer.persistentImpressionsStorage,
                                                         impressionsRecorder: impressionsRecorder,
                                                         impressionsPerPush: Int(splitConfig.impressionsChunkSize),
                                                         impressionsSyncHelper: syncHelper)

        let timer = DefaultPeriodicTimer(deadline: 0, interval: splitConfig.impressionRefreshRate)
        return DefaultPeriodicRecorderWorker(timer: timer, recorderWorker: impressionWorker)
    }

    func createImpressionsRecorderWorker(syncHelper: ImpressionsRecorderSyncHelper?) -> RecorderWorker? {

        guard let impressionsRecorder = apiFacade.impressionsRecorder else {
            return nil
        }

        return ImpressionsRecorderWorker(persistentImpressionsStorage: storageContainer.persistentImpressionsStorage,
                                         impressionsRecorder: impressionsRecorder,
                                         impressionsPerPush: Int(splitConfig.impressionsChunkSize),
                                         impressionsSyncHelper: syncHelper)
    }

    func createImpressionsCountRecorderWorker() -> RecorderWorker {
        return ImpressionsCountRecorderWorker(countsStorage: storageContainer.impressionsCountStorage,
                                              countsRecorder: apiFacade.impressionsCountRecorder)
    }

    func createPeriodicImpressionsCountRecorderWorker() -> PeriodicRecorderWorker {
        let recorderWorker = ImpressionsCountRecorderWorker(countsStorage: storageContainer.impressionsCountStorage,
                                                            countsRecorder: apiFacade.impressionsCountRecorder)
        let timer = DefaultPeriodicTimer(deadline: 0, interval: splitConfig.impressionsCountsRefreshRate)
        return DefaultPeriodicRecorderWorker(timer: timer, recorderWorker: recorderWorker)
    }

    func createPeriodicEventsRecorderWorker(syncHelper: EventsRecorderSyncHelper?) -> PeriodicRecorderWorker {
        let eventsWorker = EventsRecorderWorker(persistentEventsStorage: storageContainer.persistentEventsStorage,
                                                eventsRecorder: apiFacade.eventsRecorder,
                                                eventsPerPush: Int(splitConfig.eventsPerPush),
                                                eventsSyncHelper: syncHelper)

        let timer = DefaultPeriodicTimer(deadline: splitConfig.eventsFirstPushWindow,
                                         interval: splitConfig.eventsPushRate)
        return DefaultPeriodicRecorderWorker(timer: timer, recorderWorker: eventsWorker)
    }

    func createEventsRecorderWorker(syncHelper: EventsRecorderSyncHelper?) -> RecorderWorker {
        return EventsRecorderWorker(persistentEventsStorage: storageContainer.persistentEventsStorage,
                                    eventsRecorder: apiFacade.eventsRecorder,
                                    eventsPerPush: Int(splitConfig.eventsPerPush),
                                    eventsSyncHelper: syncHelper)

    }

    func createTelemetryConfigRecorderWorker() -> RecorderWorker? {

        guard let telemetryStorage = storageContainer.telemetryStorage else {
            return nil
        }

        guard let telemetryConfigRecorder = apiFacade.telemetryConfigRecorder else {
            return nil
        }

        return TelemetryConfigRecorderWorker(telemetryConfigRecorder: telemetryConfigRecorder,
                                             splitClientConfig: splitConfig,
                                             telemetryConsumer: telemetryStorage)
    }

    func createTelemetryStatsRecorderWorker() -> RecorderWorker? {

        guard let telemetryStorage = storageContainer.telemetryStorage else {
            return nil
        }

        guard let telemetryStatsRecorder = apiFacade.telemetryStatsRecorder else {
            return nil
        }

        return TelemetryStatsRecorderWorker(telemetryStatsRecorder: telemetryStatsRecorder,
                                            telemetryConsumer: telemetryStorage,
                                            splitsStorage: storageContainer.splitsStorage,
                                            mySegmentsStorage: storageContainer.mySegmentsStorage,
                                            myLargeSegmentsStorage: storageContainer.myLargeSegmentsStorage)
    }

    func createPeriodicTelemetryStatsRecorderWorker() -> PeriodicRecorderWorker? {

        guard let telemetryStorage = storageContainer.telemetryStorage else {
            return nil
        }

        guard let telemetryStatsRecorder = apiFacade.telemetryStatsRecorder else {
            return nil
        }

        let telemetryStatsWorker = TelemetryStatsRecorderWorker(telemetryStatsRecorder: telemetryStatsRecorder,
                                                                telemetryConsumer: telemetryStorage,
                                                                splitsStorage: storageContainer.splitsStorage,
                                                                mySegmentsStorage: storageContainer.mySegmentsStorage,
                                                                myLargeSegmentsStorage: storageContainer.myLargeSegmentsStorage)

        let timer = DefaultPeriodicTimer(deadline: splitConfig.internalTelemetryRefreshRate,
                                         interval: splitConfig.internalTelemetryRefreshRate)

        return DefaultPeriodicRecorderWorker(timer: timer, recorderWorker: telemetryStatsWorker)
    }

    func createUniqueKeyRecorderWorker(flusherChecker: RecorderFlushChecker?) -> RecorderWorker {
        return UniqueKeysRecorderWorker(uniqueKeyStorage: storageContainer.uniqueKeyStorage,
                                            uniqueKeysRecorder: apiFacade.uniqueKeysRecorder,
                                            flushChecker: flusherChecker)
    }

    func createPeriodicUniqueKeyRecorderWorker(flusherChecker: RecorderFlushChecker?) -> PeriodicRecorderWorker {
        return DefaultPeriodicRecorderWorker(timer: DefaultPeriodicTimer(deadline: splitConfig.uniqueKeysRefreshRate,
                                                                         interval: splitConfig.uniqueKeysRefreshRate),
                                             recorderWorker: createUniqueKeyRecorderWorker(flusherChecker: flusherChecker))
    }
}

class DefaultMySegmentsSyncWorkerFactory: MySegmentsSyncWorkerFactory {
    let splitConfig: SplitClientConfig
    let mySegmentsStorage: MySegmentsStorage
    let myLargeSegmentsStorage: MySegmentsStorage
    let mySegmentsFetcher: HttpMySegmentsFetcher
    let telemetryProducer: TelemetryProducer?

    init(splitConfig: SplitClientConfig,
         mySegmentsStorage: MySegmentsStorage,
         myLargeSegmentsStorage: MySegmentsStorage,
         mySegmentsFetcher: HttpMySegmentsFetcher,
         telemetryProducer: TelemetryProducer?) {
        self.splitConfig = splitConfig
        self.mySegmentsStorage = mySegmentsStorage
        self.myLargeSegmentsStorage = myLargeSegmentsStorage
        self.mySegmentsFetcher = mySegmentsFetcher
        self.telemetryProducer = telemetryProducer
    }

    func createRetryableMySegmentsSyncWorker(forKey key: String,
                                             avoidCache: Bool,
                                             eventsManager: SplitEventsManager,
                                             changeNumbers: SegmentsChangeNumber?) -> RetryableSyncWorker {


        let backoffBase =  splitConfig.generalRetryBackoffBase
        let mySegmentsBackoffCounter = DefaultReconnectBackoffCounter(backoffBase: backoffBase)
        let msByKeyStorage = DefaultByKeyMySegmentsStorage(mySegmentsStorage: mySegmentsStorage, userKey: key)
        let mlsByKeyStorage = DefaultByKeyMySegmentsStorage(mySegmentsStorage: myLargeSegmentsStorage, userKey: key)
        let changeNumbers = changeNumbers ?? SegmentsChangeNumber(msChangeNumber: msByKeyStorage.changeNumber,
                                                                  mlsChangeNumber: mlsByKeyStorage.changeNumber)
        let syncHelper = DefaultSegmentsSyncHelper(userKey: key,
                                                   segmentsFetcher: mySegmentsFetcher,
                                                   mySegmentsStorage: msByKeyStorage,
                                                   myLargeSegmentsStorage: mlsByKeyStorage,
                                                   changeChecker: DefaultMySegmentsChangesChecker(),
                                                   splitConfig: splitConfig)

        return RetryableMySegmentsSyncWorker(telemetryProducer: telemetryProducer,
                                             eventsManager: eventsManager,
                                             reconnectBackoffCounter: mySegmentsBackoffCounter,
                                             avoidCache: avoidCache,
                                             changeNumbers: changeNumbers,
                                             syncHelper: syncHelper)
    }

    func createPeriodicMySegmentsSyncWorker(forKey key: String,
                                            eventsManager: SplitEventsManager) -> PeriodicSyncWorker {
        let byKeyStorage = DefaultByKeyMySegmentsStorage(mySegmentsStorage: mySegmentsStorage, userKey: key)
        let byKeyLargeStorage = DefaultByKeyMySegmentsStorage(mySegmentsStorage: myLargeSegmentsStorage, userKey: key)
        let syncHelper = DefaultSegmentsSyncHelper(userKey: key,
                                                   segmentsFetcher: mySegmentsFetcher,
                                                   mySegmentsStorage: byKeyStorage,
                                                   myLargeSegmentsStorage: byKeyLargeStorage,
                                                   changeChecker: DefaultMySegmentsChangesChecker(),
                                                   splitConfig: splitConfig)

        return PeriodicMySegmentsSyncWorker(
            mySegmentsStorage: byKeyStorage,
            myLargeSegmentsStorage: byKeyLargeStorage,
            telemetryProducer: telemetryProducer,
            timer: DefaultPeriodicTimer(interval: splitConfig.segmentsRefreshRate),
            eventsManager: eventsManager,
            syncHelper: syncHelper)
    }
}
