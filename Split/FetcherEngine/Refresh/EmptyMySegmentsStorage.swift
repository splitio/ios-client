//
//  EmptyMySegmentsStorage.swift
//  Split
//
//  Created by Javier Avrudsky on 11/01/2021.
//  Copyright © 2021 Split. All rights reserved.
//

import Foundation

class EmptyMySegmentsStorage: MySegmentsStorage {
    var keys: Set<String> = Set()

    func loadLocal(forKey key: String) {
    }

    func getAll(forKey key: String) -> Set<String> {
        return Set()
    }

    func set(_ segments: [String], forKey key: String) {
    }

    func clear(forKey key: String) {
    }

    func destroy() {
    }

    func getCount(forKey key: String) -> Int {
        return 0
    }

    func getCount() -> Int {
        return 0
    }
}
