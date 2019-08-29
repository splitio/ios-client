//
//  RestClient+Metrics.swift
//  Split
//
//  Created by Javier on 08/10/2018.
//  Copyright © 2018 Split. All rights reserved.
//

import Foundation

protocol MetricsRestClient: RestClientProtocol {
    func sendTimeMetrics(_ times: [TimeMetric], completion: @escaping (DataResult<EmptyValue>) -> Void)
    func sendCounterMetrics(_ counters: [CounterMetric], completion: @escaping (DataResult<EmptyValue>) -> Void)
    func sendGaugeMetrics(_ gauge: MetricGauge, completion: @escaping (DataResult<EmptyValue>) -> Void)
}

extension RestClient: MetricsRestClient {

    func sendTimeMetrics(_ times: [TimeMetric], completion: @escaping (DataResult<EmptyValue>) -> Void) {
        self.execute(target: EnvironmentTargetManager.sendTimeMetrics(times), completion: completion)
    }

    func sendCounterMetrics(_ counters: [CounterMetric], completion: @escaping (DataResult<EmptyValue>) -> Void) {
        self.execute(target: EnvironmentTargetManager.sendCounterMetrics(counters), completion: completion)
    }

    func sendGaugeMetrics(_ gauge: MetricGauge, completion: @escaping (DataResult<EmptyValue>) -> Void) {
        self.execute(target: EnvironmentTargetManager.sendGaugeMetrics(gauge), completion: completion)
    }
}
