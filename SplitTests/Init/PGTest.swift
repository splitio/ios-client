//
//  PGTest.swift
//  SplitTests
//
//  Created by Javier Avrudsky on 17-Jan-2023.
//  Copyright © 2023 Split. All rights reserved.
//

import Foundation

import XCTest
@testable import Split

class PGTest: XCTestCase {

    override func setUp() {
    }

    func testThis() {
        let objs = """
        {"f1": 1, "f2": true, "v1": {"v11": 1}}, {"f1": 1, "f2": true}
        """
        let json = """
        {"since": 100, "till: 101", "splits": [\(objs )]}
        """

        let data = json.data(using: .utf8)!

        let arrStart = json.firstIndex(of: "[")
        let theStart = json.index(after: arrStart!)
        let arrEnd = json.lastIndex(of: "]")
        print(arrStart)
        print(arrEnd)

        let arra = json[theStart..<arrEnd!]
        lafuncion(json: String(arra))
        print(arra)
        print("listo")
    }

    func lafuncion(json: String) {
        var jsonSplits = [String]()
        var acum = 0

        var start: String.Index?

        for index in json.indices {
            let char = json[index]
            if char == "{" {
                acum+=1
                if acum == 1 {
                    start = index
                }
            } else if char == "}" {
                acum-=1
            }

            if let ustart = start, acum == 0 {
                let jsonSplit = String(json[ustart...index])
                start = nil
                jsonSplits.append(jsonSplit)
            }
        }
        print(jsonSplits)
    }

    //struct Pers: Decodable {
    //    var name: String
    //    var names: [String]
    //}
    //
    //do {
    //    let p: Pers = try JSONDecoder().decode(Pers.self, from: json)
    //    print(p.name)
    //} catch {
    //    print(error)
    //}
}

