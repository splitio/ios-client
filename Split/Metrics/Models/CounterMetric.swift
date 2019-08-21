//
//  CounterMetric.swift
//  Split
//
//  Created by Javier Avrudsky on 28/09/2018.
//  Copyright © 2018 Split. All rights reserved.
//

import Foundation

struct CounterMetric: Codable {
    var name: String
    var delta: Int64 = 0

    init(name: String) {
        self.name = name
    }

    mutating func addDelta(_ delta: Int64) {
        self.delta += delta
    }
}
