//
//  SplitChangeProcessorStub.swift
//  SplitTests
//
//  Created by Javier Avrudsky on 03/12/2020.
//  Copyright © 2020 Split. All rights reserved.
//

import Foundation
@testable import Split

class SplitChangeProcessorStub: SplitChangeProcessor, @unchecked Sendable {
    var processedSplitChange: ProcessedSplitChange = ProcessedSplitChange(activeSplits: [], archivedSplits: [],
                                                                          changeNumber: -1, updateTimestamp: -1)
    var splitChange: SplitChange?
    func process(_ splitChange: SplitChange) -> ProcessedSplitChange {
        self.splitChange = splitChange
        return processedSplitChange
    }
}
