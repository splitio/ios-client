//
//  VersionTest.swift
//  SplitTests
//
//  Created by Javier L. Avrudsky on 06/12/2019.
//  Copyright © 2019 Split. All rights reserved.
//

import Foundation
import XCTest
@testable import Split


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

    func testFactoryProtocolDefaultVersionUsesSemantic() {
        let factory: SplitFactory = FactoryWithoutVersionOverride()

        XCTAssertEqual(factory.version, Version.semantic)
    }
}

/// Conforms to SplitFactory without implementing `version`, so the protocol default is used.
private final class FactoryWithoutVersionOverride: SplitFactory {
    var client: SplitClient { SplitClientStub() }
    var manager: SplitManager { SplitManagerStub() }
    var userConsent: UserConsent { .granted }

    func client(key: Key) -> SplitClient { client }
    func client(matchingKey: String) -> SplitClient { client }
    func client(matchingKey: String, bucketingKey: String?) -> SplitClient { client }
    func setUserConsent(enabled: Bool) {}
}
