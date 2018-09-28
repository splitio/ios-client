//
//  MetricCounter.swift
//  Split
//
//  Created by Javier on 28/09/2018.
//  Copyright © 2018 Split. All rights reserved.
//

import Foundation

struct MetricTime: Codable {
    var name: String
    var latencies: [Int64]
}

