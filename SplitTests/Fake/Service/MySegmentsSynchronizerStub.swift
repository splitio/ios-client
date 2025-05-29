//
//  MySegmentsSynchronizerStub.swift
//  SplitTests
//
//  Created by Javier Avrudsky on 10-Mar-2022.
//  Copyright © 2022 Split. All rights reserved.
//

import Foundation
@testable import Split

class MySegmentsSynchronizerStub: MySegmentsSynchronizer {
    var loadMySegmentsFromCacheCalled = false
    var synchronizeMySegmentsCalled = false
    var forceMySegmentsSyncCalled = false
    var forceMySegmentsSyncParams: ForceMySegmentsParams?
    var startPeriodicFetchingCalled = false
    var stopPeriodicFetchingCalled = false
    var pauseCalled = false
    var resumeCalled = false
    var destroyCalled = false

    func loadMySegmentsFromCache() {
        loadMySegmentsFromCacheCalled = true
    }

    func synchronizeMySegments() {
        synchronizeMySegmentsCalled = true
    }

    func forceMySegmentsSync(changeNumbers: SegmentsChangeNumber, delay: Int64) {
        forceMySegmentsSyncCalled = true
        forceMySegmentsSyncParams = ForceMySegmentsParams(segmentsCn: changeNumbers, delay: delay)
    }

    func startPeriodicFetching() {
        startPeriodicFetchingCalled = true
    }

    func stopPeriodicFetching() {
        stopPeriodicFetchingCalled = true
    }

    func pause() {
        pauseCalled = true
    }

    func resume() {
        resumeCalled = true
    }

    func destroy() {
        destroyCalled = true
    }
}
