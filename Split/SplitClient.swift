//
//  LocalSplitClient.swift
//  Pods
//
//  Created by Brian Sztamfater on 20/9/17.
//  Modified by Natalia Stele on 11/10/17.

//
//

import Foundation

public final class SplitClient: NSObject, SplitClientProtocol {

    internal var splitFetcher: SplitFetcher?
    internal var mySegmentsFetcher: MySegmentsFetcher?
    public var key: Key
    internal var initialized: Bool = false
    internal var config: SplitClientConfig?
    internal var dispatchGroup: DispatchGroup?
    var mySegmentStorage = FileAndMemoryStorage()
    let splitImpressionManager: ImpressionManager
    public var shouldSendBucketingKey: Bool = false

    private var eventsManager: SplitEventsManager

    private var trackEventsManager: TrackManager

    public init(config: SplitClientConfig, key: Key, splitCache: SplitCache) {

        self.config = config
        self.key = key
        HttpSessionConfig.default.connectionTimeOut = TimeInterval(config.connectionTimeout)

        
        eventsManager = SplitEventsManager(config: config)
        eventsManager.start()

        let refreshableSplitFetcher = RefreshableSplitFetcher(splitChangeFetcher: HttpSplitChangeFetcher(restClient: RestClient(), splitCache: splitCache), splitCache: splitCache, interval: self.config!.featuresRefreshRate, eventsManager: eventsManager)

        let refreshableMySegmentsFetcher = RefreshableMySegmentsFetcher(matchingKey: self.key.matchingKey, mySegmentsChangeFetcher: HttpMySegmentsFetcher(restClient: RestClient(), storage: mySegmentStorage), mySegmentsCache: MySegmentsCache(storage: mySegmentStorage), interval: self.config!.segmentsRefreshRate, eventsManager: eventsManager)


        var trackConfig = TrackManagerConfig()
        trackConfig.pushRate = config.eventsPushRate
        trackConfig.firstPushWindow = config.eventsFirstPushWindow
        trackConfig.eventsPerPush = config.eventsPerPush
        trackConfig.queueSize = config.eventsQueueSize
        trackEventsManager = TrackManager(config: trackConfig)
        
        var impressionsConfig = ImpressionManagerConfig()
        impressionsConfig.pushRate = config.impressionRefreshRate
        impressionsConfig.impressionsPerPush = config.impressionsChunkSize
        splitImpressionManager = ImpressionManager(config: impressionsConfig)

        self.initialized = false

        super.init()

        self.dispatchGroup = nil
        refreshableSplitFetcher.start()
        refreshableMySegmentsFetcher.start()
        self.splitFetcher = refreshableSplitFetcher
        self.mySegmentsFetcher = refreshableMySegmentsFetcher

        eventsManager.getExecutorResources().setClient(client: self)

        trackEventsManager.start()
        splitImpressionManager.start()

        Logger.i("iOS Split SDK initialized!")
    }
}

// MARK: Events
extension SplitClient {
    @available(iOS, deprecated, message: "This method is deprecated and it will be removed. Please use on(event:execute) instead")
    public func on(_ event:SplitEvent, _ task:SplitEventTask) -> Void {
        Logger.w("SplitClient.on(_:_) -> This method is deprecated and will be removed. Please use on(event:execute) method instead.")
        eventsManager.register(event: event, task: task)
    }

    public func on(event: SplitEvent, execute action: @escaping SplitAction){
        let task = SplitEventActionTask(action: action)
        eventsManager.register(event: event, task: task)
    }
}

// MARK: Treatment / Evaluation
extension SplitClient {
    public func getTreatment(_ split: String, attributes:[String:Any]? = nil) -> String {
        return getTreatment(splitName: split, verifyKey: true, attributes: attributes)
    }

    public func getTreatments(splits: [String], attributes:[String:Any]?) ->  [String:String] {

        var results = [String:String]()
        self.verifyKey()
        for splitName in splits {
            results[splitName] = getTreatment(splitName: splitName, verifyKey: false, attributes: attributes)
        }

        return results
    }

    private func getTreatment(splitName: String, verifyKey: Bool = true, attributes:[String:Any]? = nil) -> String {

        let evaluator: Evaluator = Evaluator.shared
        evaluator.splitClient = self
        do {
            if verifyKey {
                self.verifyKey()
            }

            let result = try Evaluator.shared.evalTreatment(key: self.key.matchingKey, bucketingKey: self.key.bucketingKey, split: splitName, attributes: attributes)
            let label = result![Engine.EVALUATION_RESULT_LABEL] as! String
            let treatment = result![Engine.EVALUATION_RESULT_TREATMENT] as! String

            if let val = result![Engine.EVALUATION_RESULT_SPLIT_VERSION] {
                let splitVersion = val as! Int64
                logImpression(label: label, changeNumber: splitVersion, treatment: treatment, splitName: splitName, attributes: attributes)
            } else {
                logImpression(label: label, treatment: treatment, splitName: splitName, attributes: attributes)
            }

            return treatment
        }
        catch {
            logImpression(label: ImpressionsConstants.EXCEPTION, treatment: SplitConstants.CONTROL, splitName: splitName, attributes: attributes)
            return SplitConstants.CONTROL
        }

    }

    func logImpression(label: String, changeNumber: Int64? = nil, treatment: String, splitName: String, attributes:[String:Any]? = nil) {
        var impression: Impression = Impression()
        impression.keyName = self.key.matchingKey

        impression.bucketingKey = (self.shouldSendBucketingKey) ? self.key.bucketingKey : nil
        impression.label = label
        impression.changeNumber = changeNumber
        impression.treatment = treatment
        impression.time = Date().unixTimestamp()
        splitImpressionManager.appendImpression(impression: impression, splitName: splitName)

        if let externalImpressionHandler = config?.impressionListener {
            impression.attributes = attributes
            externalImpressionHandler(impression)
        }
    }

    public func verifyKey() {

        var composeKey: Key?
        if let bucketKey = self.key.bucketingKey, bucketKey != "" {
            composeKey = Key(matchingKey: self.key.matchingKey , bucketingKey: bucketKey)
            self.shouldSendBucketingKey = true
        } else {
            composeKey = Key(matchingKey: self.key.matchingKey, bucketingKey: nil)
            self.shouldSendBucketingKey = false
        }

        if let finalKey = composeKey {
            self.key = finalKey
        }
    }
}

// MARK: Track Events
extension SplitClient {

    public func track(trafficType: String, eventType: String) -> Bool {
        return track(eventType: eventType, trafficType: trafficType)
    }

    public func track(trafficType: String, eventType: String, value: Double) -> Bool {
        return track(eventType: eventType, trafficType: trafficType, value: value)
    }

    public func track(eventType: String) -> Bool {
        return track(eventType: eventType, trafficType: nil)
    }

    public func track(eventType: String, value: Double) -> Bool {
        return track(eventType: eventType, trafficType: nil, value: value)
    }

    private func track(eventType: String, trafficType: String? = nil, value: Double? = nil) -> Bool {

        var finalTrafficType: String? = nil
        if let trafficType = trafficType {
            finalTrafficType = trafficType
        } else if let trafficType = self.config?.trafficType {
            finalTrafficType = trafficType
        } else {
            return false
        }

        let event: EventDTO = EventDTO(trafficType: finalTrafficType!, eventType: eventType)
        event.key = self.key.matchingKey
        event.value = value
        event.timestamp = Date().unixTimestamp()
        trackEventsManager.appendEvent(event: event)

        return true
    }
}
