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
    private var trafficTypes = Set<String>()
    
    init(splits: [Split]?) {
        self.queue = DispatchQueue(label: queueName, attributes: .concurrent)
        set(from: splits)
    }
    
    func set(from splits: [Split]?) {
        if let splits = splits, splits.count > 0 {
            queue.async(flags: .barrier) {
                self.trafficTypes.removeAll()
                for split in splits {
                    if let trafficTypeName = split.trafficTypeName, let status = split.status, status == .Active {
                        self.trafficTypes.insert(trafficTypeName.lowercased())
                    }
                }
            }
        }
    }

    func removeAll() {
        queue.async(flags: .barrier) {
            self.trafficTypes.removeAll()
        }
    }
    
    func getAll() -> [String] {
        var trafficTypes: [String]!
        queue.sync {
            trafficTypes = Array(self.trafficTypes)
        }
        return trafficTypes
    }
    
    func contains(name: String) -> Bool {
        var containsName = false
        queue.sync {
            containsName = self.trafficTypes.contains(name.lowercased())
        }
        return containsName
    }
}
