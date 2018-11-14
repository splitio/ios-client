//
//  CsvHelper.swift
//  SplitTests
//
//  Created by Javier on 12/11/2018.
//  Copyright © 2018 Split. All rights reserved.
//

import Foundation

class CsvHelper {
    static func readDataFromCSV(sourceClass: Any, fileName:String)-> String! {
        
        guard let filepath = Bundle(for: type(of: sourceClass) as! AnyClass).path(forResource: fileName, ofType: "csv") else {
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
    
    
    static func cleanRows(file:String)->String{
        var cleanFile = file
        cleanFile = cleanFile.replacingOccurrences(of: "\r", with: "\n")
        cleanFile = cleanFile.replacingOccurrences(of: "\n\n", with: "\n")
        return cleanFile
    }
    
    static func csv(data: String) -> [[String]] {
        var result: [[String]] = []
        let rows = data.components(separatedBy: "\n")
        for row in rows {
            let columns = row.components(separatedBy: ",")
            result.append(columns)
        }
        return result
    }
    
}
