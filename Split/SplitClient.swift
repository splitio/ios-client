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

    
    public init(config: SplitClientConfig, key: Key) {
        self.config = config
        self.key = key
        
        let refreshableSplitFetcher = RefreshableSplitFetcher(splitChangeFetcher: HttpSplitChangeFetcher(restClient: RestClient(), storage: splitStorage), splitCache: SplitCache(storage: splitStorage), interval: self.config!.getFeaturesRefreshRate())
        
        let refreshableMySegmentsFetcher = RefreshableMySegmentsFetcher(matchingKey: self.key.matchingKey, mySegmentsChangeFetcher: HttpMySegmentsFetcher(restClient: RestClient(), storage: mySegmentStorage), mySegmentsCache: MySegmentsCache(storage: mySegmentStorage), interval: self.config!.getSegmentsRefreshRate())
        
        self.initialized = true
        super.init()

        self.dispatchGroup = nil
        refreshableSplitFetcher.start()
        refreshableMySegmentsFetcher.start()
        configureImpressionManager()
        self.splitFetcher = refreshableSplitFetcher
        self.mySegmentsFetcher = refreshableMySegmentsFetcher
        
        Logger.i("iOS Split SDK initialized!")
    }
    
    //------------------------------------------------------------------------------------------------------------------
    public func getTreatment(split: String, atributtes:[String:Any]?) -> String {
        
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

    func configureImpressionManager() {
        
        splitImpressionManager.interval = (self.config?.getImpressionRefreshRate())!
        
        splitImpressionManager.impressionsChunkSize = (self.config?.getImpressionsChunkSize())!
        
        splitImpressionManager.start()
 
    }
}



