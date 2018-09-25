//
//  SplitClient.swift
//  Pods
//
//  Created by Brian Sztamfater on 18/9/17.
//
//

import Foundation

public typealias SplitAction = () -> Void

public protocol SplitClientProtocol: class {
    
    func getTreatment(_ split: String, attributes:[String:Any]?) -> String
    func getTreatments(splits: [String], attributes:[String:Any]?) ->  [String:String]

    func on(_ event:SplitEvent, _ task:SplitEventTask) -> Void
    func on(event: SplitEvent, execute action: @escaping SplitAction)
    
    // Track feature
    func track(trafficType: String, eventType: String) -> Bool
    func track(trafficType: String, eventType: String, value: Double) -> Bool
    func track(eventType: String) -> Bool
    func track(eventType: String, value: Double) -> Bool
}

public extension SplitClientProtocol {
    
    func getTreatment(_ split: String, attributes:[String:Any]? = nil) -> String {
        return getTreatment(split, attributes: attributes)
    }
    
}
