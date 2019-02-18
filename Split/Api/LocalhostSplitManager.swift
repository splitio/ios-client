//
//  LocalhostSplitManager.swift
//  Split
//
//  Created by Javier L. Avrudsky on 14/02/2019.
//  Copyright © 2019 Split. All rights reserved.
//

import Foundation

/**
 Localhost implementation of SplitManager protocol
 */
@objc public class LocalhostSplitManager: NSObject, SplitManager {
    
    var treatmentFetcher: TreatmentFetcher
    
    init(treatmentFetcher: TreatmentFetcher) {
        self.treatmentFetcher = treatmentFetcher
    }
    
    public var splits: [SplitView] {
        var splits = [SplitView]()
        if let treatments = treatmentFetcher.fetchAll() {
            for splitName in treatments.keys {
                let split = SplitView()
                split.name = splitName
                split.killed = true
                split.changeNumber = 0
                split.treatments = []
                splits.append(split)
            }
        }
        return splits
    }
    
    public var splitNames: [String] {
        return splits.compactMap { return $0.name }
    }
    
    public func split(featureName: String) -> SplitView? {
        let filtered = splits.filter { return ( featureName.lowercased() == $0.name?.lowercased() ) }
        return filtered.count > 0 ? filtered[0] : nil
    }
}
