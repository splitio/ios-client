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
    internal let persistence: SplitPersistence
    internal var trafficType: TrafficType?
    internal var initialized: Bool = false
    internal var config: SplitClientConfig?
    internal var featurePollTimer: DispatchSourceTimer?
    internal var segmentsPollTimer: DispatchSourceTimer?
    internal var semaphore: DispatchSemaphore?
    internal var dispatchGroup: DispatchGroup?
    
    public static let shared = SplitClient(splitChangeFetcher: HttpSplitChangeFetcher(restClient: RestClient()), mySegmentsFetcher: HttpMySegmentsFetcher(restClient: RestClient()), splitPersistence: PlistSplitPersistence(fileName: "splits"))
    
    init(splitChangeFetcher: SplitChangeFetcher, mySegmentsFetcher: MySegmentsFetcher, splitPersistence: SplitPersistence) {
        self.splitChangeFetcher = splitChangeFetcher
        self.mySegmentsFetcher = mySegmentsFetcher
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
        let blockUntilReady = self.config!.blockUntilReady
        if blockUntilReady > -1 {
            self.dispatchGroup = DispatchGroup()
            self.pollForSplitChanges()
            self.pollForSegments()
            let timeout = DispatchTime.now() + .milliseconds(blockUntilReady)
            if self.dispatchGroup!.wait(timeout: timeout) == .timedOut {
                self.initialized = false
                throw SplitError.timeout(reason: "SDK was not ready in \(blockUntilReady) milliseconds")
            }
        }
        self.dispatchGroup = nil
        stopPolling()
        startPolling()
    }
    
    private func startPolling() {
        startPollingForSplitChanges()
        startPollingForSegments()
    }
    
    private func stopPolling() {
        stopPollingForSplitChanges()
        stopPollingForSegments()
    }
}
