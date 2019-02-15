//
//  LocalhostSplitManager.swift
//  Split
//
//  Created by Javier L. Avrudsky on 14/02/2019.
//  Copyright © 2019 Split. All rights reserved.
//

import Foundation

/**
 Default implementation of SplitManager protocol
 */
@objc public class LocalhostSplitManager: NSObject, SplitManager {
    
    var treatmentFetcher: TreatmentFetcher
    
    init(treatmentFetcher: TreatmentFetcher) {
        self.treatmentFetcher = treatmentFetcher
    }
    
    public var splits: [SplitView] {
        return [SplitView]()
    }
    
    public var splitNames: [String] {
        return [String]()
    }
    
    public func split(featureName: String) -> SplitView? {
        let filtered = splits.filter { return ( featureName.lowercased() == $0.name?.lowercased() ) }
        return filtered.count > 0 ? filtered[0] : nil
    }
}
