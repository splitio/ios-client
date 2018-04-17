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

    //internal var onReadytask:SplitEventTask?
    
    private var _eventsManager: SplitEventsManager
    
    public init(config: SplitClientConfig, key: Key) {
        
        self.config = config
        self.key = key
        
        _eventsManager = SplitEventsManager(config: config)
        _eventsManager.start()
        
        
        let refreshableSplitFetcher = RefreshableSplitFetcher(splitChangeFetcher: HttpSplitChangeFetcher(restClient: RestClient(), storage: splitStorage), splitCache: SplitCache(storage: splitStorage), interval: self.config!.getFeaturesRefreshRate(), eventsManager: _eventsManager)
        
        let refreshableMySegmentsFetcher = RefreshableMySegmentsFetcher(matchingKey: self.key.matchingKey, mySegmentsChangeFetcher: HttpMySegmentsFetcher(restClient: RestClient(), storage: mySegmentStorage), mySegmentsCache: MySegmentsCache(storage: mySegmentStorage), interval: self.config!.getSegmentsRefreshRate(), eventsManager: _eventsManager)
        
        self.initialized = false
        
        super.init()
        

        //___________________________________
        /*
        DispatchQueue.global().async {
            // Background thread
            [weak self] in
            guard let strongSelf = self else {
                return
            }
            
            strongSelf.dispatchGroup = DispatchGroup()
            refreshableSplitFetcher.dispatchGroup = strongSelf.dispatchGroup
            refreshableSplitFetcher.forceRefresh()
            refreshableMySegmentsFetcher.dispatchGroup = strongSelf.dispatchGroup
            refreshableMySegmentsFetcher.forceRefresh()
            
            let timeout = DispatchTime.now() + .milliseconds(30000)
            if strongSelf.dispatchGroup!.wait(timeout: timeout) == .timedOut {
                strongSelf.initialized = false
                debugPrint("SDK was not ready in milliseconds")
            }
            
            strongSelf.dispatchGroup!.wait()
            strongSelf.initialized = true
            DispatchQueue.main.async(execute: {
                // UI Updates
                // TRIGGER ON READY
                //strongSelf.onReadyListeners[0].onPostExecution(cli: self!)
                strongSelf.onReadytask?.onPostExecuteView(client: self! )
            })
            strongSelf.dispatchGroup = nil
            refreshableSplitFetcher.start()
            refreshableMySegmentsFetcher.start()
        }
        */
        //___________________________________
        
        self.dispatchGroup = nil
        refreshableSplitFetcher.start()
        refreshableMySegmentsFetcher.start()
        configureImpressionManager()
        self.splitFetcher = refreshableSplitFetcher
        self.mySegmentsFetcher = refreshableMySegmentsFetcher
        
        _eventsManager.getExecutorResources().setClient(client: self)
        
        Logger.i("iOS Split SDK initialized!")
    }
    
    public func on(_ event:SplitEvent, _ task:SplitEventTask) -> Void {
        _eventsManager.register(event: event, task: task)
    }
    
    //------------------------------------------------------------------------------------------------------------------
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
        impression.time = Int64(Date().timeIntervalSince1970 * 1000)
        ImpressionManager.shared.appendImpressions(impression: impression, splitName: splitName)
    }
    
    //------------------------------------------------------------------------------------------------------------------
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
    //------------------------------------------------------------------------------------------------------------------
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



