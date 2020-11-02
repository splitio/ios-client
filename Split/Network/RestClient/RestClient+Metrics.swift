//
//  RestClient+Metrics.swift
//  Split
//
//  Created by Javier on 08/10/2018.
//  Copyright © 2018 Split. All rights reserved.
//

import Foundation

protocol MetricsRestClient: RestClient {
    func sendTimeMetrics(_ times: [TimeMetric], completion: @escaping (DataResult<EmptyValue>) -> Void)
    func sendCounterMetrics(_ counters: [CounterMetric], completion: @escaping (DataResult<EmptyValue>) -> Void)
    func sendGaugeMetrics(_ gauge: MetricGauge, completion: @escaping (DataResult<EmptyValue>) -> Void)
}

extension DefaultRestClient: MetricsRestClient {

    func sendTimeMetrics(_ times: [TimeMetric], completion: @escaping (DataResult<EmptyValue>) -> Void) {
        do {
            self.execute(
                    endpoint: endpointFactory.timeMetricsEndpoint,
                    body: try Json.encodeToJsonData(times),
                    completion: completion)
        } catch {
            Logger.e("Could not send time metrics. Error: " + error.localizedDescription)
        }
    }

    func sendCounterMetrics(_ counters: [CounterMetric], completion: @escaping (DataResult<EmptyValue>) -> Void) {
        do {
            self.execute(
                    endpoint: endpointFactory.countMetricsEndpoint,
                    body: try Json.encodeToJsonData(counters),
                    completion: completion)
        } catch {
            Logger.e("Could not send count metrics. Error: " + error.localizedDescription)
        }
    }

    func sendGaugeMetrics(_ gauge: MetricGauge, completion: @escaping (DataResult<EmptyValue>) -> Void) {
        do {
            self.execute(
                    endpoint: endpointFactory.gaugeMetricsEndpoint,
                    body: try Json.encodeToJsonData(gauge),
                    completion: completion)
        } catch {
            Logger.e("Could not send gauge metrics. Error: " + error.localizedDescription)
        }
    }
}
