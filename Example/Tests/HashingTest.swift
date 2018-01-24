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
import SwiftyJSON

@testable import Split

class HashingTest: QuickSpec {
    
    override func spec() {
        
        describe("HashingTest") {
            
            var data = readDataFromCSV(fileName: "murmur", fileType: "csv")
            data = cleanRows(file: data!)
            let csvRows = csv(data: data!)
            print(csvRows[1][1]) //UXM n. 166/167.
            
            context("Murmur3 returns the bucket expected") {
                
                for row in csvRows {
                    
                    
                    let seed: Int = Int(row[0])!
                    let key: String = row[1]
                    let bucketExpected = Int(row[3])!
                    
                    if seed < 0 {
                        
                        
                        print(seed)
                        
                    }
                    
                    let bucket = Splitter.shared.getBucket(seed: seed, key: key, algo: 2)
                    
                    expect(bucket).toNot(beNil())
                    expect(bucket).to(equal(bucketExpected))
                    
                }
            }
            
        }
        
    }
    
    func readDataFromCSV(fileName:String, fileType: String)-> String! {
        
        guard let filepath = Bundle(for: type(of: self)).path(forResource: "murmur", ofType: "csv") else {
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
            let columns = row.components(separatedBy: ",")
            result.append(columns)
        }
        return result
    }
    
}
