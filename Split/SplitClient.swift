//
//  LocalSplitClient.swift
//  Pods
//
//  Created by Brian Sztamfater on 20/9/17.
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
        print("SEG")
    }
    
    public func getTreatment(key:String, split: String, atributtes:[String:Any]?) -> String {
        // TODO: Not implemented yet
        return "control" // TODO: Move to a constant on another class
    }
    
    public func getTreatment(key:String, split: String) -> String {
        
        
        // TODO: Not implemented yet
        return "control" // TODO: Move to a constant on another class
    }
    
    public func getTreatment(key:Key, split: String, atributtes:[String:Any]?) -> String {
        
        return "control" // TODO: Move to a constant on another class
        
    }

}
