//  Created by Martin Cardozo on 06/06/2025

import XCTest
@testable import Split

class MetadataTypeTest: XCTestCase {
    func testMetadataType() {
        XCTAssertEqual(MetadataType.FLAGS_UPDATED.stringValue, "FLAG_UPDATED")
        XCTAssertEqual(MetadataType.FLAGS_KILLED.stringValue, "FLAG_KILLED")
        XCTAssertEqual(MetadataType.SEGMENTS_UPDATED.stringValue, "SEGMENTS_UPDATED")
        XCTAssertEqual(MetadataType.LARGE_SEGMENTS_UPDATED.stringValue, "LARGE_SEGMENTS_UPDATED")
        XCTAssertEqual(MetadataType.RULE_BASED_SEGMENTS_UPDATED.stringValue, "RULE_BASED_SEGMENTS_UPDATED")
    }
}
