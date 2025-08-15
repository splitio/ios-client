//  Created by Martin Cardozo on 11/08/2025

import XCTest
@testable import Split

class SplitEventsTests: XCTestCase {
    func testInternalEventsWithMetadataErrorType() {
        var event = SplitInternalEventWithMetadata(.splitsUpdated, metadata: EventMetadata(type: .featureFlagsSyncError, data: []))
        XCTAssertEqual(event.metadata!.type.toString(), "FEATURE_FLAGS_SYNC_ERROR")
        event = SplitInternalEventWithMetadata(.splitsUpdated, metadata: EventMetadata(type: .segmentsSyncError, data: []))
        XCTAssertEqual(event.metadata!.type.toString(), "SEGMENTS_SYNC_ERROR")
    }
}
