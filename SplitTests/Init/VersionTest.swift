//
//  VersionTest.swift
//  SplitTests
//
//  Created by Javier L. Avrudsky on 06/12/2019.
//  Copyright © 2019 Split. All rights reserved.
//

import Foundation
@testable import Split
import XCTest

class VersionTest: XCTestCase {
    func testSemanticVersion() {
        let semanticVersion = Version.semantic
        let sdkVersion = Version.sdk

        if semanticVersion.contains("SNAPSHOT") {
            return
        }
        XCTAssertEqual(3, semanticVersion.split(separator: ".").count)
        XCTAssertEqual(3, sdkVersion.split(separator: ".").count)
        XCTAssertTrue(sdkVersion.split(separator: ".")[0].contains("ios"))
    }

    func testFactoryVersion() {
        XCTAssertEqual(Version.semantic, DefaultSplitFactory.sdkVersion)
    }
}
