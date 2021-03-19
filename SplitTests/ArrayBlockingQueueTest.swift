//
//  ArrayBlockingQueueTest.swift
//  Split_Tests
//
//  Created by Sebastian Arrubia on 4/11/18.
//  Copyright © 2018 CocoaPods. All rights reserved.
//

import Foundation
import XCTest

@testable import Split

class ArrayBlockingQueueTests: XCTestCase {
    
    override func setUp() {
    }
    
    override func tearDown() {
    }
    
    func testArrayBlockingQueue() {
        
        let abqt = SynchronizedArrayQueue<String>()
        
        abqt.append("STR_1")
        abqt.append("STR_2")
        abqt.append("STR_3")
        
        let str1 = abqt.take()
        let str2 = abqt.take()
        let str3 = abqt.take()
        
        XCTAssertEqual("STR_1", str1)
        XCTAssertEqual("STR_2", str2)
        XCTAssertEqual("STR_3", str3)
        
    }
}


