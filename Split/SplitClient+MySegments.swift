//
//  SplitClient+MySegments.swift
//  Pods
//
//  Created by Brian Sztamfater on 2/10/17.
//
//

import Foundation

extension SplitClient {
    
    func startPollingForSegments() {
        let queue = DispatchQueue(label: "split-polling-queue")
        segmentsPollTimer = DispatchSource.makeTimerSource(queue: queue)
        segmentsPollTimer!.scheduleRepeating(deadline: .now(), interval: .seconds(self.config!.segmentsRefreshRate))
        segmentsPollTimer!.setEventHandler { [weak self] in
            guard let strongSelf = self else {
                return
            }
            guard strongSelf.initialized else {
                strongSelf.stopPollingForSegments()
                return
            }
            strongSelf.pollForSegments()
        }
        segmentsPollTimer!.resume()
    }
    
    func stopPollingForSegments() {
        segmentsPollTimer?.cancel()
        segmentsPollTimer = nil
    }
    
    func pollForSegments() {
        dispatchGroup?.enter()
        let queue = DispatchQueue(label: "split-segments-queue")
        queue.async { [weak self] in
            guard let strongSelf = self, strongSelf.initialized else {
                return
            }
            do {
                // TODO: Set real matching key
                let segments = try strongSelf.mySegmentsFetcher.fetch(user: "pepe")
                let dict = NSMutableDictionary()
                dict.setValue(segments, forKey: "mySegments")
                // TODO: We need to persist data in storage
                strongSelf.dispatchGroup?.leave()
            } catch let error {
                if strongSelf.config!.debugEnabled {
                    debugPrint("Problem fetching mySegments: %@", error.localizedDescription)
                }
            }
        }
    }
}
