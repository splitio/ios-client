//
//  SplitClient+FeaturePoll.swift
//  Pods
//
//  Created by Brian Sztamfater on 21/9/17.
//
//

import Foundation

extension SplitClient {
    
    func startPollingForFeatures() {
        let queue = DispatchQueue.main
        featurePollTimer = DispatchSource.makeTimerSource(queue: queue)
        featurePollTimer!.scheduleRepeating(deadline: .now(), interval: .seconds(self.config!.pollForFeatureChangesInterval))
        featurePollTimer!.setEventHandler { [weak self] in
            guard let strongSelf = self else {
                return
            }
            guard strongSelf.initialized else {
                strongSelf.stopPollingForFeatures()
                return
            }
            strongSelf.pollForFeatures()
        }
        featurePollTimer!.resume()
    }
    
    func stopPollingForFeatures() {
        featurePollTimer?.cancel()
        featurePollTimer = nil
    }
    
    func pollForFeatures() {
        fetcher.fetchAll(keys: [self.trafficType!.key], attributes: self.trafficType!.attributes) { [weak self] treatments in
            guard let strongSelf = self else {
                return
            }
            let dict = NSMutableDictionary()
            treatments.forEach { dict.setObject($0.treatment, forKey: $0.name as NSString) }
            strongSelf.persistence.saveAll(dict as! [String : String])
        }
    }
    
    func clearFeatures() {
        persistence.removeAll()
    }
}
