//
//  DatesTests.swift
//  Split_Example
//
//  Created by Sebastian Arrubia on 2/1/18.
//  Copyright © 2018 CocoaPods. All rights reserved.
//

import Foundation
import Quick
import Nimble

@testable import Split

class DatesTest: QuickSpec {
    
    override func spec() {
        
        describe("DatesTest") {
    
            let timestamp1 = 1461280509
            let timestamp2 = 1461196800
            
            let d1 = normalizeDate(timestamp: TimeInterval(timestamp1))
            let d2 = normalizeDate(timestamp: TimeInterval(timestamp2))
            expect(d1).to(equal(d2))
            
        }
    }
    
    func normalizeDate(timestamp: TimeInterval) -> Date {
        let date = Date(timeIntervalSince1970: timestamp)
        let calendar = Calendar.current
        
        var dateComponents = calendar.dateComponents(in: TimeZone(identifier: "UTC")!, from: date)
         dateComponents.hour = 0
         dateComponents.minute = 0
         dateComponents.second = 0
        
        return calendar.date(from: dateComponents)!
    }
    
    
}
