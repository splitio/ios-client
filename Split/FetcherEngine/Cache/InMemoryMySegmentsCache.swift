//
//  InMemorySegmentsCache.swift
//  Pods
//
//  Created by Brian Sztamfater on 2/10/17.
//
//

import Foundation

class InMemoryMySegmentsCache: MySegmentsCacheProtocol {
    private let queueName = "split.inmemcache-queue.mysegments"
    private var queue: DispatchQueue
    private var mySegments: Set<String>

    init(segments: Set<String>) {
        self.queue = DispatchQueue(label: queueName, attributes: .concurrent)
        mySegments = segments
    }

    func setSegments(_ segments: [String]) {
        queue.async(flags: .barrier) {
            self.mySegments.removeAll()
            for segment in segments {
                self.mySegments.insert(segment)
            }
        }
    }

    func removeSegments() {
        queue.async(flags: .barrier) {
            self.mySegments.removeAll()
        }
    }

    func getSegments() -> [String] {
        var segments: Set<String>!
        queue.sync {
            segments = self.mySegments
        }
        return Array(segments)
    }

    func isInSegments(name: String) -> Bool {
        var segments: Set<String>!
        queue.sync {
            segments = self.mySegments
        }
        return segments.contains(name)
    }

    func clear() {
        queue.async(flags: .barrier) {
            self.mySegments.removeAll()
        }
    }
}
