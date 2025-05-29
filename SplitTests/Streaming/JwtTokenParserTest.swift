//
//  JwtTokenParserTest.swift
//  SplitTests
//
//  Created by Javier L. Avrudsky on 10/08/2020.
//  Copyright © 2020 Split. All rights reserved.
//

import Foundation
@testable import Split
import XCTest

class JwtTokenParserTest: XCTestCase {
    override func setUp() {}

    func testOkToken() throws {
        let jwtToken = "eyJhbGciOiJIUzI1NiIsImtpZCI6ImtleUlkIiwidHlwIjoiSldUIn0.eyJvcmdJ" +
            "ZCI6ImY3ZjAzNTIwLTVkZjctMTFlOC04NDc2LTBlYzU0NzFhM2NlYyIsImVudklkIjoiZjdmN" +
            "jI4OTAtNWRmNy0xMWU4LTg0NzYtMGVjNTQ3MWEzY2VjIiwidXNlcktleXMiOlsiamF2aSJdLC" +
            "J4LWFibHktY2FwYWJpbGl0eSI6IntcIk16TTVOamMwT0RjeU5nPT1fTVRFeE16Z3dOamd4X01" +
            "UY3dOVEkyTVRNME1nPT1fbXlTZWdtZW50c1wiOltcInN1YnNjcmliZVwiXSxcIk16TTVOamMwT" +
            "0RjeU5nPT1fTVRFeE16Z3dOamd4X3NwbGl0c1wiOltcInN1YnNjcmliZVwiXSxcImNvbnRyb2x" +
            "cIjpbXCJzdWJzY3JpYmVcIl19IiwieC1hYmx5LWNsaWVudElkIjoiY2xpZW50SWQiLCJleHAiOj" +
            "E1ODM5NDc4MTIsImlhdCI6MTU4Mzk0NDIxMn0.bSkxugrXKLaJJkvlND1QEd7vrwqWiPjn77pkrJOl4t8"

        let parser = DefaultJwtTokenParser()
        let parsedToken = try parser.parse(raw: jwtToken)
        let channels = parsedToken.channels

        XCTAssertEqual(1583947812, parsedToken.expirationTime)
        XCTAssertEqual(1583944212, parsedToken.issuedAt)
        XCTAssertEqual(jwtToken, parsedToken.rawToken)
        XCTAssertEqual(1, channels.filter { $0 == "MzM5Njc0ODcyNg==_MTExMzgwNjgx_MTcwNTI2MTM0Mg==_mySegments" }.count)
        XCTAssertEqual(1, channels.filter { $0 == "MzM5Njc0ODcyNg==_MTExMzgwNjgx_splits" }.count)
        XCTAssertEqual(1, channels.filter { $0 == "control" }.count)
        XCTAssertEqual(3, channels.count)
    }

    func testOnlyHeader() {
        let jwtToken = "eyJhbGciOiJIUzI1NiIsImtpZCI6ImtleUlkIiwidHlwIjoiSldUIn0."
        let parser = DefaultJwtTokenParser()
        var ex = false

        var parsedToken: JwtToken?
        do {
            parsedToken = try parser.parse(raw: jwtToken)
        } catch {
            ex = true
        }

        XCTAssertNil(parsedToken)
        XCTAssertTrue(ex)
    }

    func testOnlyChannelsWithSeparator() throws {
        let jwtToken = ".eyJvcmdJ" +
            "ZCI6ImY3ZjAzNTIwLTVkZjctMTFlOC04NDc2LTBlYzU0NzFhM2NlYyIsImVudklkIjoiZjdmN" +
            "jI4OTAtNWRmNy0xMWU4LTg0NzYtMGVjNTQ3MWEzY2VjIiwidXNlcktleXMiOlsiamF2aSJdLC" +
            "J4LWFibHktY2FwYWJpbGl0eSI6IntcIk16TTVOamMwT0RjeU5nPT1fTVRFeE16Z3dOamd4X01" +
            "UY3dOVEkyTVRNME1nPT1fbXlTZWdtZW50c1wiOltcInN1YnNjcmliZVwiXSxcIk16TTVOamMwT" +
            "0RjeU5nPT1fTVRFeE16Z3dOamd4X3NwbGl0c1wiOltcInN1YnNjcmliZVwiXSxcImNvbnRyb2x" +
            "cIjpbXCJzdWJzY3JpYmVcIl19IiwieC1hYmx5LWNsaWVudElkIjoiY2xpZW50SWQiLCJleHAiOj" +
            "E1ODM5NDc4MTIsImlhdCI6MTU4Mzk0NDIxMn0.bSkxugrXKLaJJkvlND1QEd7vrwqWiPjn77pkrJOl4t8"
        var ex = false
        let parser = DefaultJwtTokenParser()

        var parsedToken: JwtToken?
        do {
            parsedToken = try parser.parse(raw: jwtToken)
        } catch {
            ex = true
        }

        XCTAssertNil(parsedToken)
        XCTAssertTrue(ex)
    }

    func testGarbageToken() throws {
        let jwtToken = "novalidtoken"
        var ex = false
        let parser = DefaultJwtTokenParser()

        var parsedToken: JwtToken?
        do {
            parsedToken = try parser.parse(raw: jwtToken)
        } catch {
            ex = true
        }

        XCTAssertNil(parsedToken)
        XCTAssertTrue(ex)
    }

    func testEmptyToken() throws {
        let jwtToken = ""
        var ex = false
        let parser = DefaultJwtTokenParser()

        var parsedToken: JwtToken?
        do {
            parsedToken = try parser.parse(raw: jwtToken)
        } catch {
            ex = true
        }

        XCTAssertNil(parsedToken)
        XCTAssertTrue(ex)
    }

    override func tearDown() {}
}
