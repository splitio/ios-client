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
    var splitStorage = FileAndMemoryStorage()
    var mySegmentStorage = FileAndMemoryStorage()
    let splitImpressionManager = ImpressionManager.shared
    public var shouldSendBucketingKey: Bool = false

    private var eventsManager: SplitEventsManager
    
    private var trackEventsManager: TrackManager
    
    public init(config: SplitClientConfig, key: Key) {
        
        self.config = config
        self.key = key
        
        eventsManager = SplitEventsManager(config: config)
        eventsManager.start()

        let splitCache = SplitCache(storage: splitStorage)
        let refreshableSplitFetcher = RefreshableSplitFetcher(splitChangeFetcher: HttpSplitChangeFetcher(restClient: RestClient(), splitCache: splitCache), splitCache: splitCache, interval: self.config!.getFeaturesRefreshRate(), eventsManager: eventsManager)
        
        let refreshableMySegmentsFetcher = RefreshableMySegmentsFetcher(matchingKey: self.key.matchingKey, mySegmentsChangeFetcher: HttpMySegmentsFetcher(restClient: RestClient(), storage: mySegmentStorage), mySegmentsCache: MySegmentsCache(storage: mySegmentStorage), interval: self.config!.getSegmentsRefreshRate(), eventsManager: eventsManager)

        
        var trackConfig = TrackManagerConfig()
        trackConfig.pushRate = config.getEventsPushRate()
        trackConfig.firstPushWindow = config.getEventsFirstPushWindow()
        trackConfig.eventsPerPush = config.getEventsPerPush()
        trackConfig.queueSize = config.getEventsQueueSize()
        trackEventsManager = TrackManager(config: trackConfig)
        
        self.initialized = false
        
        super.init()
        
        self.dispatchGroup = nil
        refreshableSplitFetcher.start()
        refreshableMySegmentsFetcher.start()
        configureImpressionManager()
        self.splitFetcher = refreshableSplitFetcher
        self.mySegmentsFetcher = refreshableMySegmentsFetcher
        
        eventsManager.getExecutorResources().setClient(client: self)

        trackEventsManager.start()
        
        Logger.i("iOS Split SDK initialized!")
    }
    
    @available(iOS, deprecated)
    public func on(_ event:SplitEvent, _ task:SplitEventTask) -> Void {
        Logger.w("SplitClient.on(_:_) -> This method is deprecated and will be removed. Please use on(event:execute) method instead.")
        eventsManager.register(event: event, task: task)
    }
    
    public func on(event: SplitEvent, execute action: @escaping SplitAction){
        let task = SplitEventActionTask(action: action)
        eventsManager.register(event: event, task: task)
    }
    
    
    public func getTreatment(_ split: String, attributes:[String:Any]? = nil) -> String {
        
        let evaluator: Evaluator = Evaluator.shared
        evaluator.splitClient = self
        do {
            
            verifyKey()
            
            let result = try Evaluator.shared.evalTreatment(key: self.key.matchingKey, bucketingKey: self.key.bucketingKey, split: split, attributes: attributes)
           
            let label = result![Engine.EVALUATION_RESULT_LABEL] as! String
            let treatment = result![Engine.EVALUATION_RESULT_TREATMENT] as! String
            
            if let val = result![Engine.EVALUATION_RESULT_SPLIT_VERSION] {
                let splitVersion = val as! Int64
                logImpression(label: label, changeNumber: splitVersion, treatment: treatment, splitName: split)
            } else {
                logImpression(label: label, treatment: treatment, splitName: split)
            }
            
            return treatment
        }
        catch {
            logImpression(label: ImpressionsConstants.EXCEPTION, treatment: SplitConstants.CONTROL, splitName: split)
            return SplitConstants.CONTROL
        }
        
    }
    
    
    func logImpression(label: String, changeNumber: Int64? = nil, treatment: String, splitName: String) {
        
        let impression: ImpressionDTO = ImpressionDTO()
        impression.keyName = self.key.matchingKey
        
        impression.bucketingKey = (self.shouldSendBucketingKey) ? self.key.bucketingKey : nil
        impression.label = label
        impression.changeNumber = changeNumber
        impression.treatment = treatment
        impression.time = Date().unixTimestamp()
        ImpressionManager.shared.appendImpressions(impression: impression, splitName: splitName)
    }
    
    
    public func getTreatments(splits: [String], atributtes:[String:Any]?) throws ->  [String:String] {
        
        let evaluator: Evaluator = Evaluator.shared
        evaluator.splitClient = self
        var results: [String:String] = [:]
        
        for split in splits {
            
            do {
                
                verifyKey()
                
                let result = try Evaluator.shared.evalTreatment(key: self.key.matchingKey, bucketingKey: self.key.bucketingKey, split: split, attributes: atributtes)
                
                results[split] = result![Engine.EVALUATION_RESULT_TREATMENT] as? String
                
            } catch {
                
                results[split] =  SplitConstants.CONTROL
    
            }
            
        }
        
        return results
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

    func configureImpressionManager() {
        
        splitImpressionManager.interval = (self.config?.getImpressionRefreshRate())!
        
        splitImpressionManager.impressionsChunkSize = (self.config?.getImpressionsChunkSize())!
        
        splitImpressionManager.start()
 
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
        } else if let trafficType = self.config?.getTrafficType() {
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
