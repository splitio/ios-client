//
//  Murmur3HashingTest.swift
//  SplitTests
//
//  Created by Javier on 04/10/2018.
//  Copyright © 2018 Split. All rights reserved.
//

import XCTest
@testable import Split

class Murmur3HashingTest: XCTestCase {

    func testBucket() {
        let files: [String] = ["murmur3-sample-data-v2",
                               "murmur3-sample-data-non-alpha-numeric-v2",
                               "murmur3-sample-v4",
                               "murmur3-sample-v3",
                               "murmur3-sample-double-treatment-users"]
        for file in files {
            var data = CsvHelper.readDataFromCSV(sourceClass: self, fileName: file)
            data = CsvHelper.cleanRows(file: data!)
            let csvRows = CsvHelper.csv(data: data!)

            for row in csvRows {
                if row.count != 4 {
                    continue
                }
                let seed: Int = Int(row[0])!
                let key: String = row[1]
                let bucketExpected = Int(row[3])!
                let bucket = Splitter.shared.getBucket(seed: seed, key: key, algo: .murmur3)
                
                //print("seed: \(seed) - key: \(key) - buckexp: \(bucketExpected) - bucket: \(bucket) ")
                
                XCTAssertNotNil(bucket, "Bucket should not be nil")
                XCTAssertTrue(bucket == bucketExpected, "Bucket has not expected value: \(bucket) expected => \(bucketExpected)")
            }
        }
    }

    func test64x128() {
        let files: [String] = ["murmur3_64_uuids"]
        for file in files {
            guard var data = CsvHelper.readDataFromCSV(sourceClass: self, fileName: file) else {
                print("Error loading murmur64 test Data. \(file)")
                XCTAssertTrue(false)
                return
            }
            data = CsvHelper.cleanRows(file: data)
            let csvRows = CsvHelper.csv(data: data)

            for row in csvRows {
                if row.count < 3 {
                    continue
                }
                let key: [UInt8] = Array(row[0].utf8)
                let seed: UInt64 = UInt64(row[1]) ?? 0
                let bucketExpected: UInt64 =  toUInt64(value: row[2])
                let bucket: [UInt64] = Murmur64x128.hash(data: key, offset: 0, length: UInt32(key.count), seed: UInt64(seed))

                //print("seed: \(seed) - key: \(key) - buckexp: \(bucketExpected) - bucket: \(bucket) ")

                XCTAssertNotNil(bucket, "Bucket should not be nil")
                XCTAssertTrue(bucket[0] == bucketExpected, "Bucket has not expected value: \(bucket) expected => \(bucketExpected)")
            }
        }
    }

    func toUInt64(value: String) -> UInt64 {
        let numVal = Int64(value) ?? 0
        if numVal < 0 {
            return twoComplement(num: numVal)
        }
        return UInt64(value) ?? 0
    }

    func twoComplement(num: Int64) -> UInt64 {
        let b = UInt64.max - UInt64(abs(num)) + 1
        return UInt64(b)
    }
}
