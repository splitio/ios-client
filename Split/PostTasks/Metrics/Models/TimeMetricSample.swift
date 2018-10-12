//
//  TimeMetricSample.swift
//  Split
//
//  Created by Javier Avrudsky on 28/09/2018.
//  Copyright © 2018 Split. All rights reserved.
//

import Foundation

struct TimeMetricSample: Codable {
    var operation: String
    var latency: Int64
}
