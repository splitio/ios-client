//
//  FilterBuilderTest.swift
//  SplitTests
//
//  Created by Javier L. Avrudsky on 04/08/2020.
//  Copyright © 2020 Split. All rights reserved.
//

import Foundation

@testable import Split
import XCTest

class FilterBuilderTest: XCTestCase {
    let flagSetsValidator = DefaultFlagSetsValidator(telemetryProducer: nil)

    func testBasicByNameQueryString() throws {
        // Test that builder generates a query string having the byName filter first
        // then byPrefix filter. Also values should be ordered in each filter
        let byNameFilter = SplitFilter.byName(["nf_a", "nf_c", "nf_b"])
        let byPrefixFilter = SplitFilter.byPrefix(["pf_c", "pf_b", "pf_a"])

        let queryString = try FilterBuilder(flagSetsValidator: flagSetsValidator).add(filters: [
            byNameFilter,
            byPrefixFilter,
        ]).build()

        XCTAssertEqual("&names=nf_a,nf_b,nf_c&prefixes=pf_a,pf_b,pf_c", queryString)
    }

    func testBasicBySetQueryString() throws {
        // Test that builder generates a query string having the byName filter first
        // then byPrefix filter. Also values should be ordered in each filter
        let byNameFilter = SplitFilter.bySet(["nf_a", "nf_c", "nf_b"])
        let byPrefixFilter = SplitFilter.byPrefix(["pf_c", "pf_b", "pf_a"])

        let queryString = try FilterBuilder(flagSetsValidator: flagSetsValidator).add(filters: [
            byNameFilter,
            byPrefixFilter,
        ]).build()

        XCTAssertEqual("&sets=nf_a,nf_b,nf_c", queryString)
    }

    func testBySetAndByNameQueryString() throws {
        let bySetFilter = SplitFilter.bySet(["nf_a", "nf_c", "nf_b"])
        let byNameFilter = SplitFilter.byName(["pf_c", "pf_b", "pf_a"])

        let queryString = try FilterBuilder(flagSetsValidator: flagSetsValidator).add(filters: [
            bySetFilter,
            byNameFilter,
        ]).build()

        XCTAssertEqual("&sets=nf_a,nf_b,nf_c", queryString)
    }

    func testOnlyOneTypeQueryString() throws {
        // When one filter is not present, it has to appear as empty in querystring
        //        // fields order has to be maintained in querystring
        let byNameFilter = SplitFilter.byName(["nf_a", "nf_c", "nf_b"])
        let byPrefixFilter = SplitFilter.byPrefix(["pf_c", "pf_b", "pf_a"])

        let onlyByNameQs = try FilterBuilder(flagSetsValidator: flagSetsValidator).add(filters: [byNameFilter]).build()
        let onlyByPrefixQs = try FilterBuilder(flagSetsValidator: flagSetsValidator).add(filters: [byPrefixFilter])
            .build()

        XCTAssertEqual("&names=nf_a,nf_b,nf_c", onlyByNameQs)
        XCTAssertEqual("&prefixes=pf_a,pf_b,pf_c", onlyByPrefixQs)
    }

    func testFilterByNamesValuesDeduptedAndGrouped() throws {
        // Duplicated filter values should be removed on builing
        let filters: [SplitFilter] = [
            SplitFilter.byName(["nf_a", "nf_c", "nf_b"]),
            SplitFilter.byName(["nf_b", "nf_d"]),
            SplitFilter.byPrefix(["pf_a", "pf_c", "pf_b"]),
            SplitFilter.byPrefix(["pf_d", "pf_a"]),
        ]

        let queryString = try FilterBuilder(flagSetsValidator: flagSetsValidator).add(filters: filters).build()

        XCTAssertEqual("&names=nf_a,nf_b,nf_c,nf_d&prefixes=pf_a,pf_b,pf_c,pf_d", queryString)
    }

    func testFilterBySetsValuesDeduptedAndGrouped() throws {
        // Duplicated filter values should be removed on builing
        let filters: [SplitFilter] = [
            SplitFilter.bySet(["nf_a", "nf_c", "nf_b"]),
            SplitFilter.bySet(["nf_b", "nf_d"]),
            SplitFilter.byPrefix(["pf_a", "pf_c", "pf_b"]),
            SplitFilter.byPrefix(["pf_d", "pf_a"]),
        ]

        let queryString = try FilterBuilder(flagSetsValidator: flagSetsValidator).add(filters: filters).build()

        XCTAssertEqual("&sets=nf_a,nf_b,nf_c,nf_d", queryString)
    }

    func testMaxByNameFilterExceded() throws {
        var exceptionThrown = false

        let values = Array(0 ... 400).map { "f\($0)" }

        do {
            _ = try FilterBuilder(flagSetsValidator: flagSetsValidator)
                .add(filters: [SplitFilter.byName(values)])
                .build()
        } catch {
            exceptionThrown = true
        }

        XCTAssertTrue(exceptionThrown)
    }

    func testMaxByPrefixFilterExceded() throws {
        var exceptionThrown = false

        let values = Array(0 ... 50).map { "f\($0)" }

        do {
            _ = try FilterBuilder(flagSetsValidator: flagSetsValidator)
                .add(filters: [SplitFilter.byPrefix(values)])
                .build()
        } catch {
            exceptionThrown = true
        }

        XCTAssertTrue(exceptionThrown)
    }

    func testNoFilters() throws {
        // When no filter added, query string has to be empty
        let queryString = try FilterBuilder(flagSetsValidator: flagSetsValidator).build()

        XCTAssertEqual("", queryString)
    }

    func testQueryStringWithSpecialChars1() throws {
        // Duplicated filter values should be removed on builing
        let filters: [SplitFilter] = [
            SplitFilter.byName(["\u{0223}abc", "abc\u{0223}asd", "abc\u{0223}"]),
            SplitFilter.byName(["ausgefüllt"]),
        ]

        let queryString = try FilterBuilder(flagSetsValidator: flagSetsValidator).add(filters: filters).build()

        XCTAssertEqual("&names=abc\u{0223},abc\u{0223}asd,ausgefüllt,\u{0223}abc", queryString)
    }

    func testQueryStringWithSpecialChars2() throws {
        // Duplicated filter values should be removed on builing
        let filters: [SplitFilter] = [
            SplitFilter.byPrefix(["\u{0223}abc", "abc\u{0223}asd", "abc\u{0223}"]),
            SplitFilter.byPrefix(["ausgefüllt"]),
            SplitFilter.byName([]),
        ]

        let queryString = try FilterBuilder(flagSetsValidator: flagSetsValidator).add(filters: filters).build()

        XCTAssertEqual("&prefixes=abc\u{0223},abc\u{0223}asd,ausgefüllt,\u{0223}abc", queryString)
    }

    func testQueryStringWithSpecialChars3() throws {
        // Duplicated filter values should be removed on builing
        let filters: [SplitFilter] = [
            SplitFilter.byPrefix(["\u{0223}abc", "abc\u{0223}asd", "abc\u{0223}"]),
            SplitFilter.byPrefix(["ausgefüllt"]),
            SplitFilter.byName(["\u{0223}abc", "abc\u{0223}asd", "abc\u{0223}"]),
            SplitFilter.byName(["ausgefüllt"]),
        ]

        let queryString = try FilterBuilder(flagSetsValidator: flagSetsValidator).add(filters: filters).build()

        XCTAssertEqual(
            "&names=abc\u{0223},abc\u{0223}asd,ausgefüllt,\u{0223}abc&prefixes=abc\u{0223},abc\u{0223}asd,ausgefüllt,\u{0223}abc",
            queryString)
    }

    func testQueryStringWithSpecialChars4() throws {
        // Duplicated filter values should be removed on builing
        let filters: [SplitFilter] = [
            SplitFilter.byName(["__ш", "__a", "%", "%25", " __ш ", "%  "]),
        ]

        let queryString = try FilterBuilder(flagSetsValidator: flagSetsValidator).add(filters: filters).build()

        XCTAssertEqual("&names=%,%25,__a,__ш", queryString)
    }

    override func tearDown() {}
}
