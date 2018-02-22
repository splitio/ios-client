//
//  LocalSplitClient.swift
//  Pods
//
//  Created by Brian Sztamfater on 20/9/17.
//  Modified by Natalia Stele on 11/10/17.

//
//

import Foundation


public enum SplitEnvironment {
    
    case Production, Staging, Preprod
}

public protocol SplitClientTreatmentProtocol {
    
    func getTreatment(split: String, atributtes:[String:Any]?) throws -> String
    
}

public final class SplitClient: NSObject, SplitClientTreatmentProtocol {
    
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

    
    public init(config: SplitClientConfig, key: Key) {
        self.config = config
        self.key = key
        
        let refreshableSplitFetcher = RefreshableSplitFetcher(splitChangeFetcher: HttpSplitChangeFetcher(restClient: RestClient(), storage: splitStorage), splitCache: SplitCache(storage: splitStorage), interval: self.config!.featuresRefreshRate)
        
        let refreshableMySegmentsFetcher = RefreshableMySegmentsFetcher(matchingKey: self.key.matchingKey, mySegmentsChangeFetcher: HttpMySegmentsFetcher(restClient: RestClient(), storage: mySegmentStorage), mySegmentsCache: MySegmentsCache(storage: mySegmentStorage), interval: self.config!.segmentsRefreshRate)
        
        self.initialized = true
        super.init()
        let blockUntilReady = self.config!.blockUntilReady
        if blockUntilReady > -1 {
            self.dispatchGroup = DispatchGroup()
            refreshableSplitFetcher.dispatchGroup = self.dispatchGroup
            refreshableSplitFetcher.forceRefresh()
            refreshableMySegmentsFetcher.dispatchGroup = self.dispatchGroup
            refreshableMySegmentsFetcher.forceRefresh()
            let timeout = DispatchTime.now() + .milliseconds(blockUntilReady)
            if self.dispatchGroup!.wait(timeout: timeout) == .timedOut {
                self.initialized = false
                Logger.d("SDK was not ready in \(blockUntilReady) milliseconds")
            }
        }
        self.dispatchGroup = nil
        refreshableSplitFetcher.start()
        refreshableMySegmentsFetcher.start()
        configureImpressionManager()
        self.splitFetcher = refreshableSplitFetcher
        self.mySegmentsFetcher = refreshableMySegmentsFetcher

    }
    
    //------------------------------------------------------------------------------------------------------------------
    public func getTreatment(split: String, atributtes:[String:Any]?) throws -> String {
        
        let evaluator: Evaluator = Evaluator.shared
        evaluator.splitClient = self
        do {
            
            verifyKey()
            
            let result = try Evaluator.shared.evalTreatment(key: self.key.matchingKey, bucketingKey: self.key.bucketingKey, split: split, atributtes: atributtes)
           
            return result![Engine.EVALUATION_RESULT_TREATMENT] as! String
            
            
        }
        catch {
            
            return SplitConstants.CONTROL
            
        }
        
    }
    
    //------------------------------------------------------------------------------------------------------------------
    public func getTreatments(splits: [String], atributtes:[String:Any]?) throws ->  [String:String] {
        
        let evaluator: Evaluator = Evaluator.shared
        evaluator.splitClient = self
        var results: [String:String] = [:]
        
        for split in splits {
            
            do {
                
                verifyKey()
                
                let result = try Evaluator.shared.evalTreatment(key: self.key.matchingKey, bucketingKey: self.key.bucketingKey, split: split, atributtes: atributtes)
                
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
    //------------------------------------------------------------------------------------------------------------------
    func configureImpressionManager() {
        
        splitImpressionManager.environment = self.config?.environment
        
        splitImpressionManager.interval = (self.config?.impressionRefreshRate)!
        
        splitImpressionManager.impressionsChunkSize = (self.config?.impressionsChunkSize)!
        
        splitImpressionManager.start()
 
    }
    //------------------------------------------------------------------------------------------------------------------

}



