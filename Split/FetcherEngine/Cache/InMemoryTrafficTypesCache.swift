//
//  InMemoryTrafficTypeCache.swift
//  Split
//
//  Created by Javier L. Avrudsky on 03/18/2019.
//  Copyright © 2019 Split. All rights reserved.
//

import Foundation

class InMemoryTrafficTypesCache: TrafficTypesCache {
    private let queueName = "split.inmemcache-queue.traffictypes"
    private var queue: DispatchQueue
    private var trafficTypes: Set<String>
    
    init(trafficTypes: Set<String>) {
        self.queue = DispatchQueue(label: queueName, attributes: .concurrent)
        self.trafficTypes = trafficTypes
    }
    
    func set(trafficTypes: [String]) {
        queue.async(flags: .barrier) {
            self.trafficTypes.removeAll()
            for trafficType in trafficTypes {
                self.trafficTypes.insert(trafficType)
            }
        }
    }
    
    func removeAll() {
        queue.async(flags: .barrier) {
            self.trafficTypes.removeAll()
        }
    }
    
    func getAll() -> [String] {
        var trafficTypes: Set<String>!
        queue.sync {
            trafficTypes = self.trafficTypes
        }
        return Array(trafficTypes)
    }
    
    func isInTrafficTypes(name: String) -> Bool {
        var trafficTypes: Set<String>!
        queue.sync {
            trafficTypes = self.trafficTypes
        }
        return trafficTypes.contains(name)
    }
}
