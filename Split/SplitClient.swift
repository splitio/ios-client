//
//  LocalSplitClient.swift
//  Pods
//
//  Created by Brian Sztamfater on 20/9/17.
//
//

import Foundation

@objc public final class SplitClient: NSObject, SplitClientProtocol {
    
    internal let splitChangeFetcher: SplitChangeFetcher
    internal let mySegmentsFetcher: MySegmentsFetcher
    internal let config: SplitClientConfig
    internal var dispatchGroup: DispatchGroup?

    internal var initialized: Bool? = false

    public init(splitChangeFetcher: SplitChangeFetcher, mySegmentsFetcher: MySegmentsFetcher, config: SplitClientConfig, trafficType: TrafficType) throws {
        self.splitChangeFetcher = splitChangeFetcher
        self.mySegmentsFetcher = mySegmentsFetcher
        self.config = config
        self.initialized = true
        super.init()
        let blockUntilReady = self.config.blockUntilReady
        if blockUntilReady > -1 {
            self.dispatchGroup = DispatchGroup()
            let timeout = DispatchTime.now() + .milliseconds(blockUntilReady)
            if self.dispatchGroup!.wait(timeout: timeout) == .timedOut {
                self.initialized = false
                debugPrint("SDK was not ready in \(blockUntilReady) milliseconds")
                throw SplitError.Timeout
            }
        }
        self.dispatchGroup = nil
    }
    
    public func getTreatment(forSplit split: String) -> String {
        return "control" // TODO: Move to a constant on another class
    }
}
