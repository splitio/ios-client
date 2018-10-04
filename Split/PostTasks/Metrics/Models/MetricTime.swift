//
//  MetricCounter.swift
//  Split
//
//  Created by Javier Avrudsky on 28/09/2018.
//  Copyright © 2018 Split. All rights reserved.
//

import Foundation

struct MetricTime {
    var name: String
    var latencies: [Int] {
        set {
            latencyCounter.fillCounters(values: newValue)
        }
        get {
            return latencyCounter.counters
        }
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

extension MetricTime: Decodable {
    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        name = try values.decode(String.self, forKey: .name)
        let latencies = try values.decode([Int].self, forKey: .latencies)
        latencyCounter.fillCounters(values: latencies)
    }
}

extension MetricTime: Encodable {
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(name, forKey: .name)
        try container.encode(latencies, forKey: .latencies)
    }
}

