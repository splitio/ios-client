//
//  PersistentMySegmentsStorage.swift
//  Split
//
//  Created by Javier L. Avrudsky on 09/11/2020.
//  Copyright © 2020 Split. All rights reserved.
//

import Foundation

protocol PersistentMySegmentsStorage {
    func set(_ segments: [String])
    func getSnapshot() -> [String]
    func close()
}
