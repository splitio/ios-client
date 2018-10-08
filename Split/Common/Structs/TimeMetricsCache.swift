//
//  TimeMetricsCache.swift
//  Split
//
//  Created by Javier on 17/09/2018.
//  Copyright © 2018 Split. All rights reserved.
//

import Foundation

class TimeMetricsCache {
    
    private var queue: DispatchQueue
    private var items: [String:MetricTime]
    
    var all: [String:MetricTime] {
        var allItems: [String:MetricTime]? = nil
        queue.sync {
            allItems = items
        }
        return allItems!
    }
    
    var count: Int {
        var count: Int = 0
        queue.sync {
            count = items.count
        }
        return count
    }
    
    init(){
        queue = DispatchQueue(label: NSUUID().uuidString, attributes: .concurrent)
        items = [String:MetricTime]()
    }
    
    func value(forKey key: String) -> MetricTime? {
        var value: MetricTime? = nil
        queue.sync {
            value = items[key]
        }
        return value
    }
    
    func removeValue(forKeys keys: Dictionary<String, MetricTime>.Keys) {
        queue.async(flags: .barrier) {
            for key in keys {
                self.items.removeValue(forKey: key)
            }
        }
    }
    
    func removeAll() {
        queue.async(flags: .barrier) {
            self.items.removeAll()
        }
    }
    
    func setValue(_ value: MetricTime, toKey key: String) {
        queue.async(flags: .barrier) {
            self.items[key] = value
        }
    }
}
