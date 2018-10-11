//
//  MetricsRestClientStub.swift
//  SplitTests
//
//  Created by Javier on 09/10/2018.
//  Copyright © 2018 Split. All rights reserved.
//

import Foundation
@testable import Split

class MetricsRestClientStub {
    
    var timeMetrics: [TimeMetric]?
    var counterMetrics: [CounterMetric]?
    
    var timeOperations: Set<String> {
        var operations = Set<String>()
        if let timeMetrics = self.timeMetrics {
            for timeMetric in timeMetrics {
                operations.insert(timeMetric.name)
            }
        }
        return operations
    }
    
    var counterNames: Set<String> {
        var names = Set<String>()
        if let counterMetrics = self.counterMetrics {
            for counterMetric in counterMetrics {
                names.insert(counterMetric.name)
            }
        }
        return names
    }
}

extension MetricsRestClientStub: MetricsRestClient {
    func isServerAvailable(_ url: URL) -> Bool {
        return true
    }
    
    func isServerAvailable(_ url: String) -> Bool {
        return true
    }
    
    func isEventsServerAvailable() -> Bool {
        return true
    }
    
    func isSdkServerAvailable() -> Bool {
        return true
    }
    
    func sendTimeMetrics(_ times: [TimeMetric], completion: @escaping (DataResult<EmptyValue>) -> Void) {
        timeMetrics = times
        completion( DataResult{ return nil } )
    }
    
    func sendCounterMetrics(_ counters: [CounterMetric], completion: @escaping (DataResult<EmptyValue>) -> Void) {
        counterMetrics = counters
        completion( DataResult{ return nil } )
    }
    
    func sendGaugeMetrics(_ gauge: MetricGauge, completion: @escaping (DataResult<EmptyValue>) -> Void) {
        
        completion( DataResult{ return nil } )
    }
}
