//
//  PersistentSplitsStorage.swift
//  Split
//
//  Created by Javier L. Avrudsky on 10/11/2020.
//  Copyright © 2020 Split. All rights reserved.
//

import Foundation

protocol PersistentSplitsStorage {
    func update(splitChange: ProcessedSplitChange)
    func getFilterQueryString() -> String
    func getSplitsSnapshot() -> SplitsSnapshot
    func getAll() -> [Split]
    func delete(splitNames: [String])
    func clear()
    func close()
}
