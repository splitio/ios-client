//
//  GzipTest.swift
//  SplitTests
//
//  Created by Javier Avrudsky on 01-Sep-2021.
//  Copyright © 2021 Split. All rights reserved.
//

import Foundation
@testable import Split
import XCTest

@testable import Split

class DecompressionTest: XCTestCase {
    let zlib = Zlib()

    override func setUp() {}

//    func testZlibBasic() {
//        let text = "0123456789_0123456789"
//        let res =  "eJwzMDQyNjE1M7ewjDeAMwEwowR6"
//        let textdata = text.data(using: .utf8)!
//
    ////        let comp = try? zlib.compress(textdata)
    ////        let decomp = try? zlib.decompress(comp!)
//        let b64b = "eJzMVk3OhDAIVdNFl9/22zVzEo8yR5mjT6LGsRTKg2LiW8yPUnjQB+2kIwM2ThTIKtVU1oknFcRzufz+YGYM/phnHW8sdPvs9EzXW2I+HFzhNyTNgCD/PpW9xpGiHD0Bw1U5HLSS644FbGZgoPovmjpmX5wAzhIxJyN7IAnFQWX1htj+LUl6ZQRV3umMqYG1LCrOJGLPV8+IidBQZFt6sOUA6CqsX5iEFY2gqufs2mfqRtsVWytRnO+iYMN7xIBqJhDqAydV+HidkGOGEJYvk4fhe/8iIukphG/XfFcfVxnMVcALCOF77qL/EU7ODepxlLST6qxFLYRdOyW8EBY4BqVjObnm3V5ZMkZIKf++8+hM7zM1Kd3aFqVZeSHzDQAA//+QUQ3a"
//        let b64 = "H4sIAAAAAAAA/wTAsRHDUAgD0F2ofwEIkPAqPhdZIW0uu/v97GPXHU004ULuMGrYR6XUbIjlXULPPse+dt1yhJibBODjrTmj3GJ4emduuDDP/w0AAP//18WLsl0AAAA="
    ////        let unos = Base64Utils.decodeBase64URL(base64: b64)
    ////        let uno = Base64Utils.decodeBase64(b64)?.dropFirst().dropFirst()
//
//        var uno = Base64Utils.decodeBase64(b64)
//        for i in 0..<3 {
//            uno = uno?.dropFirst()
//        }
    ////        let unojaf = try? zlib.decompress(uno!)
//        let unojaf = try? zlib.decompress(uno!)
//        let dos = uno?.stringRepresentation
//
    ////        let bas = String(data: comp!, encoding: .ascii)
    ////
    ////        XCTAssertEqual(text, decomp?.stringRepresentation ?? "")
//        //XCTAssertEqual(res, res1 ?? "")
//    }
//
//
//    func test() {
//        zlibWhat(text: "a")
//        zlibWhat(text: "b")
//        zlibWhat(text: "c")
//        zlibWhat(text: "abc")
//        zlibWhat(text: "aaabbbccc")
//        zlibWhat(text: "aaa")
//        zlibWhat(text: "aaaaaaa")
    ////        zlibWhat(text: "aaaaaaaaaaaa")
//        zlibWhat(text: "abbbc")
//        zlibWhat(text: "bbbbbbb")
//        zlibWhat(text: "bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb")
//    }
//
//    func zlibWhat(text: String) {
//        let comp = try? zlib.compress(Data(text.utf8))
//        let abits = comp?.binaryRepresentation
//        let ahex = comp?.hexadecimalRepresentation
//        print("\(text): \(abits)")
//        print("\(text): \(ahex)")
//        print("------")
//    }
//
//    func testZlibMany() {
//        for text in generateRamdom() {
//            let textdata = text.data(using: .utf8)!
//            let comp = try? zlib.compress(textdata)
//            let decomp = try? zlib.decompress(comp!)
//            XCTAssertEqual(text, decomp?.stringRepresentation ?? "")
//        }
//    }
//
//    func testZlibLoremIpsum() {
//        for text in loadLoremIpsum() {
//            let textdata = text.data(using: .utf8)!
//            let comp = try? zlib.compress(textdata)
//            let decomp = try? zlib.decompress(comp!)
//            XCTAssertEqual(text, decomp?.stringRepresentation ?? "")
//        }
//    }
//
//    func testGzipBasic() {
//        let text = "0123456789_0123456789"
//        let compressed = "H4sIAAAAAAAA/zMwNDI2MTUzt7CMN4AzAR17K0EVAAAA"
//        let textdata = text.data(using: .utf8)!
//
//        let comp = try? zlib.compress(textdata)
//        let decomp = try? zlib.decompress(comp!)
//
//        XCTAssertEqual(text, decomp?.stringRepresentation ?? "")
//    }

    func testBasicGzip() {}

    func descompress(_ base64: String) -> String {
        guard var dec = Base64Utils.decodeBase64(base64) else { return "" }

        guard let descomp = try? zlib.decompress(data: dec, type: type) else {
            print("NO DESCOMP")
            return ""
        }
        return descomp.stringRepresentation
    }

    func this(_ b64: String, _ type: CompressionType) {
//        let unos = Base64Utils.decodeBase64URL(base64: b64)
        guard var dec = Base64Utils.decodeBase64(b64) else { return }

        guard let descomp = try? zlib.decompress(data: dec, type: type) else {
            print("NO DESCOMP")
            return
        }
        let abits = descomp.binaryRepresentation
        let ahex = descomp.dropFirst().dropFirst().hexadecimalRepresentation
        print("\(type)".uppercased())
//        print("BITS: \(abits)")
        print("HEX: \(ahex)")
        print("STR: \(descomp.stringRepresentation)")
        print(String(repeating: "-", count: 100))
    }

    func testThis1() {
        // gzip
        this(
            "H4sIAAAAAAAA/2IYBfgAx0A7YBTgB4wD7YABAAID7QC6g5EYy8MEMA20A+gMFAbaAYMZDPXqlGWgHTAKRsEoGAWjgCzQQFjJkKqiiPAPAQAIAAD//5L7VQwAEAAA",
            .gzip)
        // zlib
        this(
            "eJzMVk3OhDAIVdNFl9/22zVzEo8yR5mjT6LGsRTKg2LiW8yPUnjQB+2kIwM2ThTIKtVU1oknFcRzufz+YGYM/phnHW8sdPvs9EzXW2I+HFzhNyTNgCD/PpW9xpGiHD0Bw1U5HLSS644FbGZgoPovmjpmX5wAzhIxJyN7IAnFQWX1htj+LUl6ZQRV3umMqYG1LCrOJGLPV8+IidBQZFt6sOUA6CqsX5iEFY2gqufs2mfqRtsVWytRnO+iYMN7xIBqJhDqAydV+HidkGOGEJYvk4fhe/8iIukphG/XfFcfVxnMVcALCOF77qL/EU7ODepxlLST6qxFLYRdOyW8EBY4BqVjObnm3V5ZMkZIKf++8+hM7zM1Kd3aFqVZeSHzDQAA//+QUQ3a",
            .zlib)
        // zlib
        this(
            "eJxiGAX4AMdAO2AU4AeMA+2AAQACA+0AuoORGMvDBDANtAPoDBQG2gGDGQz16pRloB0wCkbBKBgFo4As0EBYyZCqoojwDwEACAAA//+W/QFR",
            .zlib)
        // gzip
        this(
            "H4sIAAAAAAAA/wTAsRHDUAgD0F2ofwEIkPAqPhdZIW0uu/v97GPXHU004ULuMGrYR6XUbIjlXULPPse+dt1yhJibBODjrTmj3GJ4emduuDDP/w0AAP//18WLsl0AAAA=",
            .gzip)
        this("eF7zSM3JyVcozy/KSVHwzFUoSC1IBQBE9Abd", .zlib)
    }

    override func tearDown() {}

    private func generateRamdom() -> [String] {
        var text = [String]()
        for _ in 1 ..< 100 {
            text.append(UUID().uuidString)
        }
        return text
    }

    private func loadLoremIpsum() -> [String] {
        guard let data = FileHelper.readDataFromFile(sourceClass: self, name: "lorem_ipsum", type: "txt") else {
            print("Error loading compression test Data.")
            XCTAssertTrue(false)
            return []
        }
        return data.split(separator: "\n").map { String($0) }
    }
}
