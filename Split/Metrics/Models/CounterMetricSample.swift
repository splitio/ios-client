//
//  CounterMetricSample.swift
//  Split
//
//  Created by Javier Avrudsky on 28/09/2018.
//  Copyright © 2018 Split. All rights reserved.
//

import Foundation

struct CounterMetricSample: Codable {
    var name: String
    var delta: Int64 = 0
}
