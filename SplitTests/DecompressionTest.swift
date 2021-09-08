//
//  DecompressionTest.swift
//  SplitTests
//
//  Created by Javier Avrudsky on 01-Sep-2021.
//  Copyright © 2021 Split. All rights reserved.
//

import Foundation
import XCTest
@testable import Split

@testable import Split

class DecompressionTest: XCTestCase {

    let zlib = Zlib()
    let gzip = Gzip()

    override func setUp() {
    }

    func testLoremIpsumZlib() {
        let lines = loadLoremIpsum()
        let expected = loadLoremIpsumExpected()
        var results = [String]()
        for line in lines {
            results.append(descompressZlib(line))
        }

        for (i, result) in results.enumerated() {
            XCTAssertEqual(expected[i], result)
        }
    }

    func testLoremIpsumGzip() {
        let lines = loadLoremIpsum()
        let expected = loadLoremIpsumExpected()
        var results = [String]()
        for line in lines {
            results.append(descompressGzip(line))
        }

        for (i, result) in results.enumerated() {
            XCTAssertEqual(expected[i], result)
        }
    }

    func descompressZlib(_ base64: String) -> String {
        guard let dec =  Base64Utils.decodeBase64(base64) else { return "" }

        guard let descomp = try? zlib.decompress(data: dec) else {
            return ""
        }
        return descomp.stringRepresentation
    }

    func descompressGzip(_ base64: String) -> String {
        guard let dec =  Base64Utils.decodeBase64(base64) else { return "" }

        guard let descomp = try? zlib.decompress(data: dec) else {
            return ""
        }
        return descomp.stringRepresentation
    }

    func this(_ b64: String, _ type: CompressionType) {

    }

    func testThis1() {

        // gzip
        this("H4sIAAAAAAAA/2IYBfgAx0A7YBTgB4wD7YABAAID7QC6g5EYy8MEMA20A+gMFAbaAYMZDPXqlGWgHTAKRsEoGAWjgCzQQFjJkKqiiPAPAQAIAAD//5L7VQwAEAAA", .gzip)
        // zlib
        this("eJzMVk3OhDAIVdNFl9/22zVzEo8yR5mjT6LGsRTKg2LiW8yPUnjQB+2kIwM2ThTIKtVU1oknFcRzufz+YGYM/phnHW8sdPvs9EzXW2I+HFzhNyTNgCD/PpW9xpGiHD0Bw1U5HLSS644FbGZgoPovmjpmX5wAzhIxJyN7IAnFQWX1htj+LUl6ZQRV3umMqYG1LCrOJGLPV8+IidBQZFt6sOUA6CqsX5iEFY2gqufs2mfqRtsVWytRnO+iYMN7xIBqJhDqAydV+HidkGOGEJYvk4fhe/8iIukphG/XfFcfVxnMVcALCOF77qL/EU7ODepxlLST6qxFLYRdOyW8EBY4BqVjObnm3V5ZMkZIKf++8+hM7zM1Kd3aFqVZeSHzDQAA//+QUQ3a", .zlib)
        // zlib
        this("eJxiGAX4AMdAO2AU4AeMA+2AAQACA+0AuoORGMvDBDANtAPoDBQG2gGDGQz16pRloB0wCkbBKBgFo4As0EBYyZCqoojwDwEACAAA//+W/QFR", .zlib)
        // gzip
        this("H4sIAAAAAAAA/wTAsRHDUAgD0F2ofwEIkPAqPhdZIW0uu/v97GPXHU004ULuMGrYR6XUbIjlXULPPse+dt1yhJibBODjrTmj3GJ4emduuDDP/w0AAP//18WLsl0AAAA=", .gzip)
        this("eF7zSM3JyVcozy/KSVHwzFUoSC1IBQBE9Abd", .zlib)
    }



    override func tearDown() {
    }

    private func loadLoremIpsum() -> [String] {
        guard let data = FileHelper.readDataFromFile(sourceClass: self, name: "lorem_ipsum", type: "txt") else {
                print("Error loading compression test Data.")
                XCTAssertTrue(false)
                return []
        }
        return data.split(separator: "\n").map { String($0)}
    }

    private func loadLoremIpsumExpected() -> [String] {
        guard let data = FileHelper.readDataFromFile(sourceClass: self, name: "lorem_ipsum_result", type: "txt") else {
                print("Error loading compression test Data.")
                XCTAssertTrue(false)
                return []
        }
        return data.split(separator: "\n").map { String($0)}
    }
}
