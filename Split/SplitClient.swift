//
//  LocalSplitClient.swift
//  Pods
//
//  Created by Brian Sztamfater on 20/9/17.
//
//

import Foundation

@objc public final class SplitClient: NSObject, SplitClientProtocol {
    
    internal let fetcher: SplitChangeFetcher
    internal let persistence: SplitPersistence
    internal var trafficType: TrafficType?
    internal var initialized: Bool = false
    internal var config: SplitClientConfig?
    internal var featurePollTimer: DispatchSourceTimer?
    internal var semaphore: DispatchSemaphore?
    
    public static let shared = SplitClient(splitFetcher: HttpSplitChangeFetcher(restClient: RestClient()), splitPersistence: PlistSplitPersistence(fileName: "splits"))
    
    init(splitFetcher: SplitChangeFetcher, splitPersistence: SplitPersistence) {
        self.fetcher = splitFetcher
        self.persistence = splitPersistence
    }
    
    public func getTreatment(forSplit split: String) -> String {
        guard let treatment = self.persistence.get(key: split) else {
            return "control" // TODO: Move to a constant on another class
        }
        return treatment
    }
    
    public func initialize(withConfig config: SplitClientConfig, andTrafficType trafficType: TrafficType) throws {
        self.config = config
        self.trafficType = trafficType
        self.initialized = true
        stopPollingForSplitChanges()
        startPollingForSplitChanges()
        let blockUntilReady = self.config!.blockUntilReady
        if blockUntilReady > -1 {
            self.semaphore = DispatchSemaphore(value: 0)
            let timeout = DispatchTime.now() + .milliseconds(blockUntilReady)
            if self.semaphore!.wait(timeout: timeout) == .timedOut {
                self.initialized = false
                throw SplitError.timeout(reason: "SDK was not ready in \(blockUntilReady) milliseconds")
            }
        }
    }
}
