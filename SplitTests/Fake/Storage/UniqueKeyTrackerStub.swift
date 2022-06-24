//
//  UniqueKeyTrackerStub.swift
//  SplitTests
//
//  Created by Javier Avrudsky on 23-May-2022.
//  Copyright © 2022 Split. All rights reserved.
//

import Foundation
@testable import Split

class UniqueKeyTrackerStub: UniqueKeyTracker {
    var trackedKeys = [String: Set<String>]()
    var savedKeys = [[String: Set<String>]]()

    func track(userKey: String, featureName: String) {
        var features = trackedKeys[userKey] ?? Set<String>()
        features.insert(featureName)
        trackedKeys[userKey] = features
    }

    func saveAndClear() {
        savedKeys.append(trackedKeys)
        trackedKeys.removeAll()
    }
}
