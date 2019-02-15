//
//  LocalhostSplitClient.swift
//  Split
//
//  Created by Javier L. Avrudsky on 14/02/2019.
//  Copyright © 2019 Split. All rights reserved.
//

import Foundation

public final class LocalhostSplitClient: NSObject, SplitClient {
    
    var treatmentFetcher: TreatmentFetcher
    
    init(treatmentFetcher: TreatmentFetcher) {
        self.treatmentFetcher = treatmentFetcher
    }
    
    public func getTreatment(_ split: String, attributes: [String : Any]?) -> String {
        return "CONTROL"
    }
    
    public func getTreatment(_ split: String) -> String {
        return "CONTROL"
    }
    
    public func getTreatments(splits: [String], attributes: [String : Any]?) -> [String : String] {
        return ["FAKE_SPLIT": "CONTROL"]
    }
    
    public func on(_ event: SplitEvent, _ task: SplitEventTask) {
    }
    
    public func on(event: SplitEvent, execute action: @escaping SplitAction) {
    }
    
    public func track(trafficType: String, eventType: String) -> Bool {
        return true
    }
    
    public func track(trafficType: String, eventType: String, value: Double) -> Bool {
        return true
    }
    
    public func track(eventType: String) -> Bool {
        return true
    }
    
    public func track(eventType: String, value: Double) -> Bool {
        return true
    }
    
    
}
