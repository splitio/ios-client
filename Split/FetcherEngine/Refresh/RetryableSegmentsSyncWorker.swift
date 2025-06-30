//
//  RetryableSegmentsSyncWorker.swift
//  Split
//
//  Created by Javier Avrudsky on 15-Sep-2020
//
//

import Foundation

///
/// Retrieves segments changes or a user key
/// Also triggers MY SEGMENTS READY event when first fetch is succesful
///
class RetryableMySegmentsSyncWorker: BaseRetryableSyncWorker {

    private let telemetryProducer: TelemetryRuntimeProducer?
    private let avoidCache: Bool
    private let syncHelper: SegmentsSyncHelper
    private let changeNumbers: SegmentsChangeNumber

    var changeChecker: MySegmentsChangesChecker

    init(telemetryProducer: TelemetryRuntimeProducer?,
         eventsManager: SplitEventsManager,
         reconnectBackoffCounter: ReconnectBackoffCounter,
         avoidCache: Bool,
         changeNumbers: SegmentsChangeNumber,
         syncHelper: SegmentsSyncHelper) {

        self.telemetryProducer = telemetryProducer
        self.changeChecker = DefaultMySegmentsChangesChecker()
        self.avoidCache = avoidCache
        self.changeNumbers = changeNumbers
        self.syncHelper = syncHelper

        super.init(eventsManager: eventsManager,
                   reconnectBackoffCounter: reconnectBackoffCounter)
    }

    override func fetchFromRemote() throws -> Bool {
        do {
            let result = try syncHelper.sync(msTill: changeNumbers.msChangeNumber,
                                             mlsTill: changeNumbers.mlsChangeNumber,
                                             headers: getHeaders())
            if result.success {
                if !isSdkReadyTriggered() {
                    // Notifying both to trigger SDK Ready
                    notifyUpdate(.mySegmentsUpdated, metadata: EventMetadata(type: .SEGMENTS_UPDATED, data: result.msUpdated))
                    notifyUpdate(.myLargeSegmentsUpdated, metadata: EventMetadata(type: .LARGE_SEGMENTS_UPDATED, data: result.mlsUpdated))
                } else if !result.msUpdated.isEmpty || !result.mlsUpdated.isEmpty {
                    // For now is not necessary specify which entity was updated
                    notifyUpdate(.mySegmentsUpdated, metadata: EventMetadata(type: .SEGMENTS_UPDATED, data: result.msUpdated + result.mlsUpdated))
                }
                return true
            }
        } catch {
            Logger.e("Error while fetching segments in method: \(error.localizedDescription)")
            errorHandler?(error)
        }
        return false

    }

    private func getHeaders() -> [String: String]? {
        return avoidCache ? ServiceConstants.controlNoCacheHeader : nil
    }
}

struct SegmentsSyncResult {
    let success: Bool
    let msChangeNumber: Int64
    let mlsChangeNumber: Int64
    let msUpdated: [String]
    let mlsUpdated: [String]
}

protocol SegmentsSyncHelper {
    func sync(msTill: Int64,
              mlsTill: Int64,
              headers: HttpHeaders?) throws -> SegmentsSyncResult

}

class DefaultSegmentsSyncHelper: SegmentsSyncHelper {
    struct FetchResult {
        let msTill: Int64
        let mlsTill: Int64
        let msUpdated: [String]
        let mlsUpdated: [String]
    }

    private let segmentsFetcher: HttpMySegmentsFetcher
    private let mySegmentsStorage: ByKeyMySegmentsStorage
    private let myLargeSegmentsStorage: ByKeyMySegmentsStorage
    private let splitConfig: SplitClientConfig
    private let userKey: String
    private let changeChecker: MySegmentsChangesChecker

    private var maxAttempts: Int {
        return splitConfig.cdnByPassMaxAttempts
    }

    private var backoffTimeBaseInSecs: Int {
        return splitConfig.cdnBackoffTimeBaseInSecs
    }

    private var backoffTimeMaxInSecs: Int {
        return splitConfig.cdnBackoffTimeMaxInSecs
    }

    init(userKey: String,
         segmentsFetcher: HttpMySegmentsFetcher,
         mySegmentsStorage: ByKeyMySegmentsStorage,
         myLargeSegmentsStorage: ByKeyMySegmentsStorage,
         changeChecker: MySegmentsChangesChecker,
         splitConfig: SplitClientConfig) {

        self.userKey = userKey
        self.segmentsFetcher = segmentsFetcher
        self.mySegmentsStorage = mySegmentsStorage
        self.myLargeSegmentsStorage = myLargeSegmentsStorage
        self.splitConfig = splitConfig
        self.changeChecker = changeChecker
    }

    func sync(msTill: Int64 = -1,
              mlsTill: Int64 = -1,
              headers: HttpHeaders? = nil) throws -> SegmentsSyncResult {
        do {
            let res = try tryToSync(msTill: msTill,
                                    mlsTill: mlsTill,
                                    headers: headers)

            if res.success {
                return res
            }

            return try tryToSync(msTill: res.msChangeNumber,
                                 mlsTill: res.mlsChangeNumber,
                                 headers: headers,
                                 useTillParam: true)
        } catch let error {
            Logger.e("Problem fetching segments %@", error.localizedDescription)
            throw error
        }
    }

    private func tryToSync(msTill: Int64,
                           mlsTill: Int64,
                           headers: HttpHeaders? = nil,
                           useTillParam: Bool = false) throws -> SegmentsSyncResult {

        let backoffCounter = DefaultReconnectBackoffCounter(backoffBase: backoffTimeBaseInSecs,
                                                            maxTimeLimit: backoffTimeMaxInSecs)
        var attemptCount = 0
        let goalTill = SegmentsChangeNumber(msChangeNumber: msTill, mlsChangeNumber: mlsTill)
        let till = useTillParam ? goalTill.max() : nil
        while attemptCount < maxAttempts {
            let result = try fetchUntil(till: till,
                                        headers: headers)

            if goalReached(goalTill: goalTill, result: result) {
                return SegmentsSyncResult(success: true,
                                          msChangeNumber: result.msTill,
                                          mlsChangeNumber: result.mlsTill,
                                          msUpdated: result.msUpdated,
                                          mlsUpdated: result.mlsUpdated)
            }
            attemptCount+=1
            if attemptCount < maxAttempts {
                Thread.sleep(forTimeInterval: backoffCounter.getNextRetryTime())
            }
        }
        return SegmentsSyncResult(success: false,
                                  msChangeNumber: -1,
                                  mlsChangeNumber: -1,
                                  msUpdated: [],
                                  mlsUpdated: [])
    }

    private func fetchUntil(till: Int64?,
                            headers: HttpHeaders? = nil) throws -> FetchResult {

        let oldChange = SegmentChange(segments: mySegmentsStorage.getAll().asArray(),
                                      changeNumber: mySegmentsStorage.changeNumber)

        let oldLargeChange = SegmentChange(segments: myLargeSegmentsStorage.getAll().asArray(),
                                           changeNumber: myLargeSegmentsStorage.changeNumber)

        var prevChange = AllSegmentsChange(mySegmentsChange: oldChange,
                                           myLargeSegmentsChange: oldLargeChange)
        while true {
            guard let change = try segmentsFetcher.execute(userKey: userKey,
                                                           till: till,
                                                           headers: headers) else {
                throw HttpError.unknown(code: -1, message: "Segment result is null")
            }

            let mySegmentsChange = change.mySegmentsChange
            let myLargeSegmentsChange = change.myLargeSegmentsChange

            if !isOutdated(change, prevChange) {
                let msChanged =  changeChecker.mySegmentsHaveChanged(old: oldChange,
                                                                     new: mySegmentsChange)
                let mlsChanged = changeChecker.mySegmentsHaveChanged(old: oldLargeChange,
                                                                     new: myLargeSegmentsChange)
                Logger.d("Checking my segments update")
                checkAndUpdate(isChanged: msChanged, change: mySegmentsChange, storage: mySegmentsStorage)
                Logger.d("Checking my large segments update")
                checkAndUpdate(isChanged: mlsChanged, change: myLargeSegmentsChange, storage: myLargeSegmentsStorage)

//                let segmentsDiff = changeChecker.getSegmentsDiff(oldSegments: oldChange.segments, newSegments: mySegmentsChange.segments)
//                let largeSegmentsDiff = changeChecker.getSegmentsDiff(oldSegments: oldLargeChange.segments, newSegments: myLargeSegmentsChange.segments)
                
                return FetchResult(msTill: mySegmentsChange.unwrappedChangeNumber,
                                   mlsTill: myLargeSegmentsChange.unwrappedChangeNumber,
                                   msUpdated: mySegmentsChange.segments.compactMap(\.name),
                                   mlsUpdated: myLargeSegmentsChange.segments.compactMap(\.name))
            }
            prevChange = change
        }
    }

    private func isOutdated(_ change: AllSegmentsChange,
                            _ prevChange: AllSegmentsChange?) -> Bool {

        guard let prevChange = prevChange else {
            return true
        }

        return change.changeNumbers.msChangeNumber < prevChange.changeNumbers.msChangeNumber ||
        change.changeNumbers.mlsChangeNumber < prevChange.changeNumbers.mlsChangeNumber
    }

    private func checkAndUpdate(isChanged: Bool, change: SegmentChange, storage: ByKeyMySegmentsStorage) {
        if isChanged {
            storage.set(change)
            Logger.i("Segments have been updated")
            Logger.v(change.segments.compactMap { $0.name }.joined(separator: ","))
        }
    }

    private func goalReached(goalTill: SegmentsChangeNumber, result: FetchResult) -> Bool {
        return (result.msTill >= goalTill.msChangeNumber && result.mlsTill >= goalTill.mlsChangeNumber)
    }
}
