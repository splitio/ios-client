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
    private var syncKey: Key!

    let keyQueue = DispatchQueue(label: "com.splitio.com.key", attributes: .concurrent)
    public var key: Key {
        get {
            var key: Key!
            keyQueue.sync() {
                key = self.syncKey
            }
            return key
        }

        set {
            keyQueue.async(flags: .barrier) {
                self.syncKey = newValue
            }
        }
    }
    internal var initialized: Bool = false
    internal var config: SplitClientConfig?
    internal var dispatchGroup: DispatchGroup?
    let splitImpressionManager: ImpressionManager
    public var shouldSendBucketingKey: Bool = false

    private var eventsManager: SplitEventsManager
    private var trackEventsManager: TrackManager
    private var metricsManager: MetricsManager

    init(config: SplitClientConfig, key: Key, splitCache: SplitCache) {
        self.config = config

        let kValidatorTag = "client init"
        _ = KeyValidatable(key: key).isValid(validator: KeyValidator(tag: kValidatorTag))

        let mySegmentsCache = MySegmentsCache(matchingKey: key.matchingKey)
        eventsManager = SplitEventsManager(config: config)
        eventsManager.start()

        let refreshableSplitFetcher = RefreshableSplitFetcher(splitChangeFetcher: HttpSplitChangeFetcher(restClient: RestClient(), splitCache: splitCache), splitCache: splitCache, interval: self.config!.featuresRefreshRate, eventsManager: eventsManager)

        let refreshableMySegmentsFetcher = RefreshableMySegmentsFetcher(matchingKey: key.matchingKey, mySegmentsChangeFetcher: HttpMySegmentsFetcher(restClient: RestClient(), mySegmentsCache: mySegmentsCache), mySegmentsCache: mySegmentsCache, interval: self.config!.segmentsRefreshRate, eventsManager: eventsManager)


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

        metricsManager = MetricsManager.shared

        self.initialized = false
        super.init()
        self.key = key
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
        if eventsManager.eventAlreadyTriggered(event: event) {
            Logger.w("A handler was added for \(event.toString()) on the SDK, which has already fired and won’t be emitted again. The callback won’t be executed.")
            return
        }
        eventsManager.register(event: event, task: task)
    }

    public func on(event: SplitEvent, execute action: @escaping SplitAction){
        if eventsManager.eventAlreadyTriggered(event: event) {
            Logger.w("A handler was added for \(event.toString()) on the SDK, which has already fired and won’t be emitted again. The callback won’t be executed.")
            return
        }
        let task = SplitEventActionTask(action: action)
        eventsManager.register(event: event, task: task)
    }
}

// MARK: Treatment / Evaluation
extension SplitClient {
    public func getTreatment(_ split: String) -> String {
        return getTreatment(splitName: split, attributes: nil)
    }

    public func getTreatment(_ split: String, attributes: [String : Any]?) -> String {
        return getTreatment(splitName: split, verifyKey: true, attributes: attributes)

    }

    public func getTreatments(splits: [String], attributes:[String:Any]?) ->  [String:String] {

        var results = [String:String]()

        if splits.count > 0 {
            self.verifyKey()
            let splitsNoDuplicated = Set(splits.filter { !$0.isEmpty() }.map { $0 })
            for splitName in splitsNoDuplicated {
                results[splitName] = getTreatment(splitName: splitName, verifyKey: false, attributes: attributes)
            }
        } else {
            Logger.d("getTreatments: split_names is an empty array or has null values")
        }

        return results
    }

    private func getTreatment(splitName: String, verifyKey: Bool = true, attributes:[String:Any]? = nil) -> String {
        
        let validationTag = "getTreatment"

        if !eventsManager.eventAlreadyTriggered(event: SplitEvent.sdkReady) {
            Logger.w("No listeners for SDK Readiness detected. Incorrect control treatments could be logged if you call getTreatment while the SDK is not yet ready")
        }

        if !KeyValidatable(key:self.key).isValid(validator: KeyValidator(tag: validationTag)) {
            return SplitConstants.CONTROL;
        }

        let split = SplitValidatable(name: splitName)
        if !split.isValid(validator: SplitNameValidator(tag: validationTag)) {
            return SplitConstants.CONTROL;
        }
        
        let trimmedSplitName = splitName.trimmingCharacters(in: .whitespacesAndNewlines)
        let timeMetricStart = Date().unixTimestampInMicroseconds()
        let evaluator: Evaluator = Evaluator.shared
        evaluator.splitClient = self

        do {
            if verifyKey {
                self.verifyKey()
            }

            let result = try Evaluator.shared.evalTreatment(key: self.key.matchingKey, bucketingKey: self.key.bucketingKey, split: trimmedSplitName, attributes: attributes)
            let label = result![Engine.EVALUATION_RESULT_LABEL] as! String
            let treatment = result![Engine.EVALUATION_RESULT_TREATMENT] as! String

            if let val = result![Engine.EVALUATION_RESULT_SPLIT_VERSION] {
                let splitVersion = val as! Int64
                logImpression(label: label, changeNumber: splitVersion, treatment: treatment, splitName: trimmedSplitName, attributes: attributes)
            } else {
                logImpression(label: label, treatment: treatment, splitName: trimmedSplitName, attributes: attributes)
            }
            metricsManager.time(microseconds: Date().unixTimestampInMicroseconds() - timeMetricStart, for: Metrics.time.getTreatment)
            return treatment
        }
        catch {
            logImpression(label: ImpressionsConstants.EXCEPTION, treatment: SplitConstants.CONTROL, splitName: trimmedSplitName, attributes: attributes)
            return SplitConstants.CONTROL
        }
    }

    func logImpression(label: String, changeNumber: Int64? = nil, treatment: String, splitName: String, attributes:[String:Any]? = nil) {
        let impression: Impression = Impression()
        impression.keyName = self.key.matchingKey

        impression.bucketingKey = (self.shouldSendBucketingKey) ? self.key.bucketingKey : nil
        impression.label = label
        impression.changeNumber = changeNumber
        impression.treatment = treatment
        impression.time = Date().unixTimestampInMiliseconds()
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

        let eventBuilder = EventBuilder()
            .setTrafficType(trafficType ?? self.config?.trafficType)
            .setKey(self.key.matchingKey)
            .setType(eventType)
            .setValue(value)

        do {
            let event = try eventBuilder.build()
            trackEventsManager.appendEvent(event: event)
        } catch {
            return false
        }
        return true
    }
}
