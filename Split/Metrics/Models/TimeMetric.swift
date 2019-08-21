//
//  MetricCounter.swift
//  Split
//
//  Created by Javier Avrudsky on 28/09/2018.
//  Copyright © 2018 Split. All rights reserved.
//

import Foundation

struct TimeMetric {
    var name: String
    var latencies: [Int] {
        return latencyCounter.counters
    }

    private let latencyCounter = LatencyCounter()

    func addLatency(microseconds latency: Int64) {
        latencyCounter.addLatency(microseconds: latency)
    }

    enum CodingKeys: String, CodingKey {
        case name
        case latencies
    }
}

extension TimeMetric: Encodable {
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(name, forKey: .name)
        try container.encode(latencies, forKey: .latencies)
    }
}
