//
//  SplitClientStub.swift
//  SplitTests
//
//  Created by Javier L. Avrudsky on 06/05/2019.
//  Copyright © 2019 Split. All rights reserved.
//

import Foundation
@testable import Split

class SplitClientStub: SplitClient {
    func getTreatment(_ split: String, attributes: [String : Any]?) -> String {
        return SplitConstants.CONTROL
    }
    
    func getTreatment(_ split: String) -> String {
        return SplitConstants.CONTROL
    }
    
    func getTreatments(splits: [String], attributes: [String : Any]?) -> [String : String] {
        return ["feature": SplitConstants.CONTROL]
    }
    
    func getTreatmentWithConfig(_ split: String) -> SplitResult {
        return SplitResult(treatment: SplitConstants.CONTROL)
    }
    
    func getTreatmentWithConfig(_ split: String, attributes: [String : Any]?) -> SplitResult {
        return SplitResult(treatment: SplitConstants.CONTROL)
    }
    
    func getTreatmentsWithConfig(splits: [String], attributes: [String : Any]?) -> [String : SplitResult] {
        return ["feature": SplitResult(treatment: SplitConstants.CONTROL)]
    }
    
    func on(event: SplitEvent, execute action: @escaping SplitAction) {
    }
    
    func track(trafficType: String, eventType: String) -> Bool {
        return true
    }
    
    func track(trafficType: String, eventType: String, value: Double) -> Bool {
        return true
    }
    
    func track(eventType: String) -> Bool {
        return true
    }
    
    func track(eventType: String, value: Double) -> Bool {
        return true
    }
}
