//
//  ArrayBlockingQueueTest.swift
//  Split_Tests
//
//  Created by Sebastian Arrubia on 4/11/18.
//  Copyright © 2018 CocoaPods. All rights reserved.
//

import Foundation
import Quick
import Nimble

@testable import Split

class ArrayBlockingQueueTest: QuickSpec {
    
    override func spec() {
        
        describe("ArrayBlockingQueueTest") {
            
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
}


