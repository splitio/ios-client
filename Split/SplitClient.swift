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
    internal let config: SplitClientConfig
    
    internal var featurePollTimer: DispatchSourceTimer?
    internal var semaphore: DispatchSemaphore?

    internal var initialized: Bool? = false

    public init(fetcher: SplitChangeFetcher, persistence: SplitPersistence, config: SplitClientConfig) throws {
        self.fetcher = fetcher
        self.persistence = persistence
        self.config = config
        self.initialized = true
        super.init()
        let blockUntilReady = self.config.blockUntilReady
        if blockUntilReady > -1 {
            self.semaphore = DispatchSemaphore(value: 0)
            let timeout = DispatchTime.now() + .milliseconds(blockUntilReady)
            if self.semaphore!.wait(timeout: timeout) == .timedOut {
                self.initialized = false
                debugPrint("SDK was not ready in \(blockUntilReady) milliseconds")
                throw SplitError.Timeout
            }
        }
    }
    
    public func getTreatment(forSplit split: String) -> String {
        guard let treatment = self.persistence.get(key: split) else {
            return "control" // TODO: Move to a constant on another class
        }
        return treatment
    }
}
