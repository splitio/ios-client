//
//  TrafficTypesCache.swift
//  Split
//
//  Created by Javier L. Avrudsky on 03/18/2019.
//  Copyright © 2019 Split. All rights reserved.
//

import Foundation

protocol TrafficTypesCache {
    func set(trafficTypes: [String])
    func removeAll()
    func getAll() -> [String]
    func isInTrafficTypes(name: String) -> Bool
}
