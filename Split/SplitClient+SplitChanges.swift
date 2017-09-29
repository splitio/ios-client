//
//  SplitClient+FeaturePoll.swift
//  Pods
//
//  Created by Brian Sztamfater on 21/9/17.
//
//

import Foundation

extension SplitClient {
    
    func startPollingForSplitChanges() {
        let queue = DispatchQueue(label: "split-timer-queue")
        featurePollTimer = DispatchSource.makeTimerSource(queue: queue)
        featurePollTimer!.scheduleRepeating(deadline: .now(), interval: .seconds(self.config!.pollForFeatureChangesInterval))
        featurePollTimer!.setEventHandler { [weak self] in
            guard let strongSelf = self else {
                return
            }
            guard strongSelf.initialized else {
                strongSelf.stopPollingForSplitChanges()
                return
            }
            strongSelf.pollForSplitChanges()
        }
        featurePollTimer!.resume()
    }
    
    func stopPollingForSplitChanges() {
        featurePollTimer?.cancel()
        featurePollTimer = nil
    }
    
    func pollForSplitChanges() {
        let splitChanges = try? fetcher.fetch(since: -1)
        let dict = NSMutableDictionary()
        dict.setValue(splitChanges, forKey: "splitChanges")
        if let semaphore = self.semaphore {
            semaphore.signal()
            self.semaphore = nil
        }
    }
}
