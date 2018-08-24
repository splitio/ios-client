//
//  MatcherTest.swift
//  Split_Example
//
//  Created by Sebastian Arrubia on 3/8/18.
//  Copyright © 2018 CocoaPods. All rights reserved.
//

import Foundation
import Quick
import Nimble

@testable import Split

class MatcherTest: QuickSpec {
 
    override func spec() {
        describe("MatcherTest") {
            
            let matcher = try? JSON.encodeFrom(json: "{}", to: Matcher.self)
            
            let expectedVal = EngineError.MatcherNotFound
            do {
                _ = try matcher!.getMatcher()
            } catch EngineError.MatcherNotFound {
                debugPrint("MATCHER NOT FOUND")
                expect(expectedVal).to(equal(EngineError.MatcherNotFound))
                return
            } catch {
                debugPrint("Exception")
            }
            
            
        }
    }
}
