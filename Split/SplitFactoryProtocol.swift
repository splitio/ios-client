//
//  SplitFactoryProtocol.swift
//  Pods
//
//  Created by Brian Sztamfater on 27/9/17.
//
//

import Foundation

public protocol SplitFactoryProtocol {
    
    func client() -> SplitClientTreatmentProtocol
    
    func manager() -> SplitManagerProtocol
    
}
