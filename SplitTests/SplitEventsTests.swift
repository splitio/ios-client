//  Created by Martin Cardozo on 11/08/2025

import XCTest
@testable import Split

class SplitEventsTests: XCTestCase {
    func testInternalEventsWithMetadataErrorType() {
        var event = SplitInternalEventWithMetadata(.splitsUpdated, metadata: EventMetadata(type: .errorFeatureFlagsSync, data: []))
        XCTAssertEqual(event.metadata!.type.toString(), "ERROR_FEATURE_FLAGS_SYNC")
        event = SplitInternalEventWithMetadata(.splitsUpdated, metadata: EventMetadata(type: .errorSegmentsSync, data: []))
        XCTAssertEqual(event.metadata!.type.toString(), "ERROR_SEGMENTS_SYNC")
    }
}
