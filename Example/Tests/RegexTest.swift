//
//  RegexTest.swift
//  Split_Example
//
//  Created by Natalia  Stele on 20/02/2018.
//  Copyright © 2018 CocoaPods. All rights reserved.
//

//
//  HashingTest.swift
//  Split
//
//  Created by Natalia  Stele on 11/9/17.
//  Copyright © 2017 CocoaPods. All rights reserved.
//

import Foundation
import Quick
import Nimble

@testable import Split

class RegexTest: QuickSpec {

    override func spec() {

        describe("RegexTest") {
            let files: [String] = ["regex"]
            for file in files {
                var data = readDataFromCSV(fileName: file)
                data = cleanRows(file: data!)
                let csvRows = csv(data: data!)

                context("Regex returns the boolean value expected") {

                    for row in csvRows {

                        if row.count != 3 {
                            continue
                        }
                        let regex: String = row[0]
                        let key: String = row[1]
                        let resultString: String = row[2]
                        let result: Bool = resultString.toBool()!

                        let matcher = MatchesStringMatcher(data: regex, negate: false)
                        let resultEvaluation = matcher.evaluate(matchValue: key, bucketingKey: key, attributes: nil)

                        expect(resultEvaluation).to(equal(result))

                    }
                }
            }
        }
    }

    func readDataFromCSV(fileName:String)-> String! {

        guard let filepath = Bundle(for: type(of: self)).path(forResource: fileName, ofType: "csv") else {
            return nil
        }
        do {
            var contents = try String(contentsOfFile: filepath, encoding: .utf8)
            contents = cleanRows(file: contents)
            return contents
        } catch {
            print("File Read Error for file \(filepath)")
            return nil
        }
    }


    func cleanRows(file:String)->String{
        var cleanFile = file
        cleanFile = cleanFile.replacingOccurrences(of: "\r", with: "\n")
        cleanFile = cleanFile.replacingOccurrences(of: "\n\n", with: "\n")
        return cleanFile
    }

    func csv(data: String) -> [[String]] {
        var result: [[String]] = []
        let rows = data.components(separatedBy: "\n")
        for row in rows {
            let columns = row.components(separatedBy: "#")
            result.append(columns)
        }
        return result
    }

}



extension String {
    func toBool() -> Bool? {
        switch self {
        case "True", "true", "yes", "1":
            return true
        case "False", "false", "no", "0":
            return false
        default:
            return nil
        }
    }
}

