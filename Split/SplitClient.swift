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
    internal var trafficType: TrafficType?
    internal var initialized: Bool = false
    internal var config: SplitClientConfig?
    internal var dispatchGroup: DispatchGroup?
    public static let CONTROL : String = "control"
    
    public init(config: SplitClientConfig, trafficType: TrafficType) throws {
        self.config = config
        self.trafficType = trafficType
        let refreshableSplitFetcher = RefreshableSplitFetcher(splitChangeFetcher: HttpSplitChangeFetcher(restClient: RestClient()), splitCache: InMemorySplitCache(), interval: self.config!.featuresRefreshRate)
        let refreshableMySegmentsFetcher = RefreshableMySegmentsFetcher(matchingKey: self.trafficType!.key.matchingKey, mySegmentsChangeFetcher: HttpMySegmentsFetcher(restClient: RestClient()), mySegmentsCache: InMemoryMySegmentsCache(), interval: self.config!.segmentsRefreshRate)
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
                debugPrint("SDK was not ready in \(blockUntilReady) milliseconds")
                throw SplitError.Timeout
            }
        }
        self.dispatchGroup = nil
        refreshableSplitFetcher.start()
        refreshableMySegmentsFetcher.start()
        self.splitFetcher = refreshableSplitFetcher
        self.mySegmentsFetcher = refreshableMySegmentsFetcher
        print("DEBUG")
    }
   
    //------------------------------------------------------------------------------------------------------------------
    public func getTreatment(key: Key, split: String, atributtes:[String:Any]?) -> String {
        
        let evaluator: Evaluator = Evaluator.shared
        evaluator.splitClient = self

        let result = Evaluator.shared.evalTreatment(key: key.matchingKey, bucketingKey: key.bucketingKey, split: split, atributtes: atributtes)
        
        return result![Engine.EVALUATION_RESULT_TREATMENT] as! String
    
    }
    //------------------------------------------------------------------------------------------------------------------
 
    
    
    
}
