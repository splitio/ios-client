//
//  LoggerTest.swift
//  Split_Tests
//
//  Created by Sebastian Arrubia on 2/21/18.
//  Copyright © 2018 CocoaPods. All rights reserved.
//

import Foundation
import Quick

@testable import Split

class LoggerTest: QuickSpec {
    
    override func spec() {
        
        describe("LoggerTest") {
            Logger.shared.debugLevel(debug: true)
            Logger.v("VERBOSE log message")
            Logger.d("DEBUG log message")
            Logger.i("INFO log message")
            Logger.w("WARNING log message")
            Logger.e("ERROR log message")
        }
    }
    
}
