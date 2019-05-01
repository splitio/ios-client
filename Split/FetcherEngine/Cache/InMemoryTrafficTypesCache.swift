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
    private var trafficTypes = [String: Int]()

    init() {
        self.queue = DispatchQueue(label: queueName, attributes: .concurrent)
    }
    
    func update(from splits: [Split]) {
        if splits.count > 0 {
            queue.async(flags: .barrier) {
                for split in splits {
                    if let trafficTypeName = split.trafficTypeName, let status = split.status {
                        if status == .Active {
                            self.add(name: trafficTypeName)
                        } else {
                            self.remove(name: trafficTypeName)
                        }
                            
                    }
                }
            }
        }
    }
    
    func update(with split: Split) {
        queue.async(flags: .barrier) {
            if let trafficTypeName = split.trafficTypeName, let status = split.status {
                if status == .Active {
                    self.add(name: trafficTypeName)
                } else {
                    self.remove(name: trafficTypeName)
                }
            }
        }
    }
    
    func contains(name: String) -> Bool {
        var containsName = false
        queue.sync {
            containsName = (self.trafficTypes[name.lowercased()] != nil)
        }
        return containsName
    }
}

extension InMemoryTrafficTypesCache {
    
    private func add(name: String) {
        let trafficType = name.lowercased()
        let newCount = (trafficTypes[trafficType] ?? 0) + 1
        trafficTypes[trafficType] = newCount
    }
    
    private func remove(name: String) {
        let trafficType = name.lowercased()
        let newCount = (trafficTypes[trafficType] ?? 0) - 1
        if newCount > 0 {
            trafficTypes[trafficType] = newCount
        } else {
            trafficTypes.removeValue(forKey: trafficType)
        }
    }
}
