//
//  SplitClient.swift
//  Pods
//
//  Created by Brian Sztamfater on 18/9/17.
//
//

import Foundation

@objc public protocol SplitClientProtocol {
    
    func initialize(withConfig config: SplitClientConfig, andTrafficType trafficType: TrafficType)

    func getTreatment(forSplit split: String) -> String
    
}
