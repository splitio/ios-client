//
//  TrafficTypesCache.swift
//  Split
//
//  Created by Javier L. Avrudsky on 03/18/2019.
//  Copyright © 2019 Split. All rights reserved.
//

import Foundation

protocol TrafficTypesCache {
    func set(from splits: [Split]?)
    func removeAll()
    func getAll() -> [String]
    func contains(name: String) -> Bool
}
