//
//  SplitManagerStub.swift
//  SplitTests
//
//  Created by Javier L. Avrudsky on 06/05/2019.
//  Copyright © 2019 Split. All rights reserved.
//

import Foundation
@testable import Split

class SplitManagerStub: SplitManager, Destroyable {
    var splits: [SplitView]
    var splitNames: [String]

    init() {
        self.splits = []
        self.splitNames = []
    }

    func split(featureName: String) -> SplitView? {
        return nil
    }

    var destroyCalled = false
    func destroy() {
        destroyCalled = true
    }
}
