//
//  CsvHelper.swift
//  SplitTests
//
//  Created by Javier on 12/11/2018.
//  Copyright © 2018 Split. All rights reserved.
//

import Foundation

class CsvHelper {
    static func readDataFromCSV(sourceClass: Any, fileName: String) -> String? {
        if let file = FileHelper.readDataFromFile(sourceClass: sourceClass, name: fileName, type: "csv") {
            return cleanRows(file: file)
        }
        return nil
    }

    static func cleanRows(file: String) -> String {
        var cleanFile = file
        cleanFile = cleanFile.replacingOccurrences(of: "\r", with: "\n")
        cleanFile = cleanFile.replacingOccurrences(of: "\n\n", with: "\n")
        return cleanFile
    }

    static func csv(data: String) -> [[String]] {
        var result: [[String]] = []
        let rows = data.components(separatedBy: "\n")
        for row in rows {
            if row.isEmpty {
                continue
            }
            let columns = row.components(separatedBy: ",")
            result.append(columns)
        }
        return result
    }
}
