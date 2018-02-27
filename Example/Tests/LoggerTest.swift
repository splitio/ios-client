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
            Logger.v("VERBOSE log message", [1,2,3,4], "STRINGGGG", 876)
            
            Logger.d("DEBUG log message")
            Logger.i("INFO log message")
            Logger.w("WARNING log message")
            
            Logger.e(String(format:"Problem fetching mySegments: %@", "HTTP status code 500 Internal server Error"))
            
            
            Logger.d("DEBUG log message", [1,2,3,4], "STRINGGGG", 876)
            Logger.i("INFO log message", [1,2,3,4], "STRINGGGG", 876)
            Logger.w("WARNING log message", [1,2,3,4], "STRINGGGG", 876)
            Logger.e("ERROR log message", [1,2,3,4], "STRINGGGG", 876)
        }
    }
    
}
