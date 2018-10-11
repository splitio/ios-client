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
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }
    
    func testArrayBlockingQueue() {
        
        let abqt = SynchronizedArrayQueue<String>()
        
        abqt.append("STR_1")
        abqt.append("STR_2")
        abqt.append("STR_3")
        
        abqt.take(completion: {(element:String) -> Void in
            assert(element == "STR_1")
        })
        
        abqt.take(completion: {(element:String) -> Void in
            assert(element == "STR_2")
        })
        
        abqt.take(completion: {(element:String) -> Void in
            assert(element == "STR_3")
        })
        
    }
}


