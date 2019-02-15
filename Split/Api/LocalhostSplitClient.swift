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
        return treatmentFetcher.fetch(splitName: split) ?? SplitConstants.CONTROL
    }
    
    public func getTreatment(_ split: String) -> String {
        return getTreatment(_: split, attributes: nil)
    }
    
    public func getTreatments(splits: [String], attributes: [String : Any]?) -> [String : String] {
        let treatments = treatmentFetcher.fetchAll()
        var results = [String : String]()
        for split in splits {
            results[split] = treatments?[split] ?? SplitConstants.CONTROL
        }
        return results
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
