//
//  PersistentMySegmentsStorageStub.swift
//  SplitTests
//
//  Created by Javier L. Avrudsky on 10/11/2020.
//  Copyright © 2020 Split. All rights reserved.
//

import Foundation
@testable import Split

class PersistentMySegmentsStorageStub: PersistentMySegmentsStorage {
    var segments = [String]()

    func set(_ segments: [String]) {
        self.segments = segments
    }

    func getSnapshot() -> [String] {
        return segments
    }

    func close() {
    }
}
