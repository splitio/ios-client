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
        let queue = DispatchQueue(label: "split-polling-queue")
        featurePollTimer = DispatchSource.makeTimerSource(queue: queue)
        featurePollTimer!.scheduleRepeating(deadline: .now(), interval: .seconds(self.config!.featuresRefreshRate))
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
        dispatchGroup?.enter()
        let queue = DispatchQueue(label: "split-changes-queue")
        queue.async { [weak self] in
            guard let strongSelf = self, strongSelf.initialized else {
                return
            }
            do {
                // TODO: We need to set the last till value we have (if exists)
                let splitChanges = try strongSelf.splitChangeFetcher.fetch(since: -1)
                let dict = NSMutableDictionary()
                dict.setValue(splitChanges, forKey: "splitChanges")
                // TODO: We need to persist data in storage
                strongSelf.dispatchGroup?.leave()
            } catch let error {
                if strongSelf.config!.debugEnabled {
                    debugPrint("Problem fetching splitChanges: %@", error.localizedDescription)
                }
            }
        }
    }
}
