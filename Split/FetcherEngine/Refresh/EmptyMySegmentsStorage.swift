//
//  EmptyMySegmentsStorage.swift
//  Split
//
//  Created by Javier Avrudsky on 11/01/2021.
//  Copyright © 2021 Split. All rights reserved.
//

import Foundation

class EmptyMySegmentsStorage: MySegmentsStorage {
    func loadLocal() {
    }

    func getAll() -> Set<String> {
        return Set()
    }

    func set(_ segments: [String]) {
    }

    func clear() {
    }

    func destroy() {
    }

    func getCount() -> Int {
        return 0
    }
}
