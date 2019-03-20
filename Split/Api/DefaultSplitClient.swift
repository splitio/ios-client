//
//  LocalSplitClient.swift
//  Pods
//
//  Created by Brian Sztamfater on 20/9/17.
//  Modified by Natalia Stele on 11/10/17.

//
//

import Foundation

public final class DefaultSplitClient: NSObject, SplitClient {
    
    internal var splitFetcher: SplitFetcher?
    internal var mySegmentsFetcher: MySegmentsFetcher?
    
    private let keyQueue = DispatchQueue(label: "com.splitio.com.key", attributes: .concurrent)
    private var key: Key
    internal var initialized: Bool = false
    internal var config: SplitClientConfig?
    internal var dispatchGroup: DispatchGroup?
    let splitImpressionManager: ImpressionManager
    public var shouldSendBucketingKey: Bool = false
    
    private var eventsManager: SplitEventsManager
    private var trackEventsManager: TrackManager
    private var metricsManager: MetricsManager
    
    private let keyValidator: KeyValidator
    private let splitValidator: SplitValidator
    private let eventValidator: EventValidator
    private let validationLogger: ValidationMessageLogger
    
    init(config: SplitClientConfig, key: Key, splitCache: SplitCache, fileStorage: FileStorageProtocol) {
        self.config = config
        
        let trafficTypesCache = InMemoryTrafficTypesCache(splits: splitCache.getAllSplits())
        
        let mySegmentsCache = MySegmentsCache(matchingKey: key.matchingKey, fileStorage: fileStorage)
        
        self.keyValidator = DefaultKeyValidator()
        self.eventValidator = DefaultEventValidator(trafficTypesCache: trafficTypesCache)
        self.splitValidator = DefaultSplitValidator()
        self.validationLogger = DefaultValidationMessageLogger()
        
        
        eventsManager = SplitEventsManager(config: config)
        eventsManager.start()
        
        let httpSplitFetcher = HttpSplitChangeFetcher(restClient: RestClient(), splitCache: splitCache, trafficTypesCache: trafficTypesCache)
        
        let refreshableSplitFetcher = RefreshableSplitFetcher(splitChangeFetcher: httpSplitFetcher, splitCache: splitCache, interval: self.config!.featuresRefreshRate, eventsManager: eventsManager)
        
        let refreshableMySegmentsFetcher = RefreshableMySegmentsFetcher(matchingKey: key.matchingKey, mySegmentsChangeFetcher: HttpMySegmentsFetcher(restClient: RestClient(), mySegmentsCache: mySegmentsCache), mySegmentsCache: mySegmentsCache, interval: self.config!.segmentsRefreshRate, eventsManager: eventsManager)
        
        
        var trackConfig = TrackManagerConfig()
        trackConfig.pushRate = config.eventsPushRate
        trackConfig.firstPushWindow = config.eventsFirstPushWindow
        trackConfig.eventsPerPush = config.eventsPerPush
        trackConfig.queueSize = config.eventsQueueSize
        trackEventsManager = TrackManager(config: trackConfig, fileStorage: fileStorage)
        
        var impressionsConfig = ImpressionManagerConfig()
        impressionsConfig.pushRate = config.impressionRefreshRate
        impressionsConfig.impressionsPerPush = config.impressionsChunkSize
        splitImpressionManager = ImpressionManager(config: impressionsConfig, fileStorage: fileStorage)
        
        metricsManager = MetricsManager.shared
        
        self.initialized = false
        if let bucketingKey = key.bucketingKey, !bucketingKey.isEmpty() {
            self.key = Key(matchingKey: key.matchingKey , bucketingKey: bucketingKey)
            self.shouldSendBucketingKey = true
        } else {
            self.key = Key(matchingKey: key.matchingKey, bucketingKey: key.matchingKey)
        }
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
extension DefaultSplitClient {
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
extension DefaultSplitClient {
    public func getTreatment(_ split: String) -> String {
        return getTreatment(splitName: split, attributes: nil)
    }
    
    public func getTreatment(_ split: String, attributes: [String : Any]?) -> String {
        return getTreatment(splitName: split, shouldValidate: true, attributes: attributes)
    }
    
    public func getTreatments(splits: [String], attributes:[String:Any]?) ->  [String:String] {
        
        var results = [String:String]()
        
        if splits.count > 0 {
            let splitsNoDuplicated = Set(splits.filter { !$0.isEmpty() }.map { $0 })
            for splitName in splitsNoDuplicated {
                results[splitName] = getTreatment(splitName: splitName, shouldValidate: false, attributes: attributes)
            }
        } else {
            Logger.d("getTreatments: split_names is an empty array or has null values")
        }
        
        return results
    }
    
    private func getTreatment(splitName: String, shouldValidate: Bool = true, attributes:[String:Any]? = nil) -> String {
        
        let validationTag = "getTreatment"
        
        if shouldValidate {
            if !eventsManager.eventAlreadyTriggered(event: SplitEvent.sdkReady) {
                Logger.w("No listeners for SDK Readiness detected. Incorrect control treatments could be logged if you call getTreatment while the SDK is not yet ready")
            }
            
            if let errorInfo = keyValidator.validate(matchingKey: key.matchingKey, bucketingKey: key.bucketingKey) {
                validationLogger.log(errorInfo: errorInfo, tag: validationTag)
                return SplitConstants.CONTROL
            }
        }
        
        if let errorInfo = splitValidator.validate(name: splitName) {
            validationLogger.log(errorInfo: errorInfo, tag: validationTag)
            if errorInfo.isError {
                return SplitConstants.CONTROL
            }
        }
        
        let trimmedSplitName = splitName.trimmingCharacters(in: .whitespacesAndNewlines)
        let timeMetricStart = Date().unixTimestampInMicroseconds()
        let evaluator: Evaluator = Evaluator.shared
        evaluator.splitClient = self
        
        do {
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
}

// MARK: Track Events
extension DefaultSplitClient {
    
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
        
        if let errorInfo = eventValidator.validate(key: self.key.matchingKey, trafficTypeName: trafficType, eventTypeId: trafficType, value: value) {
            validationLogger.log(errorInfo: errorInfo, tag: "track")
            if errorInfo.isError {
                return false
            }
        }
        
        let event = EventDTO(trafficType: trafficType!.lowercased(), eventType: eventType)
        event.key = self.key.matchingKey
        event.value = value
        event.timestamp = Date().unixTimestampInMiliseconds()
        trackEventsManager.appendEvent(event: event)
        
        return true
    }
}
