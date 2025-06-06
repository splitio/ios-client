//  Created by Martin Cardozo on 06/06/2025

import XCTest
@testable import Split

class MetadataTypeTest: XCTestCase {
    func testMetadataType() {
        XCTAssertEqual(MetadataType.FLAGS_UPDATED.toString(), "FLAGS_UPDATED")
        XCTAssertEqual(MetadataType.FLAGS_KILLED.toString(), "FLAGS_KILLED")
        XCTAssertEqual(MetadataType.SEGMENTS_UPDATED.toString(), "SEGMENTS_UPDATED")
        XCTAssertEqual(MetadataType.LARGE_SEGMENTS_UPDATED.toString(), "LARGE_SEGMENTS_UPDATED")
        XCTAssertEqual(MetadataType.RULE_BASED_SEGMENTS_UPDATED.toString(), "RULE_BASED_SEGMENTS_UPDATED")
    }
}
