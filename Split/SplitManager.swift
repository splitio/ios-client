//
//  SplitManager.swift
//  Pods
//
//  Created by Brian Sztamfater on 27/9/17.
//
//

import Foundation

@objc public class SplitManager: NSObject, SplitManagerProtocol {
    
    private var splitCache: SplitCacheProtocol
    private var cachedChangeNumber = Int64(-1)
    private var cachedSplits = [SplitView]()
    private var cachedSplitsNames = [String]()
    
    init(splitCache: SplitCacheProtocol) {
        self.splitCache = splitCache
        super.init()
    }
    
    private var shouldReturnCache: Bool {
        return  cachedChangeNumber > -1 && cachedChangeNumber == splitCache.getChangeNumber()
    }
    
    public var splits: [SplitView] {
        
        if shouldReturnCache {
            return cachedSplits
        }
        
        let splits: [SplitView] = splitCache.getAllSplits().map { split in
            let splitView = SplitView()
            splitView.name = split.name
            splitView.changeNumber = split.changeNumber
            splitView.trafficType = split.trafficTypeName
            splitView.killed = split.killed
            
            if let conditions = split.conditions {
                var treatments = Set<String>()
                conditions.forEach { condition in
                    if let partitions = condition.partitions {
                        partitions.forEach { partition in
                            if let treatment  = partition.treatment {
                                treatments.insert(treatment)
                            }
                        }
                    }
                }
                if treatments.count > 0 {
                    splitView.treatments = Array(treatments)
                }
            }
            return splitView
        }
        cachedChangeNumber = splitCache.getChangeNumber()
        cachedSplits = splits
        
        return cachedSplits
    }
    
    public var splitNames: [String] {
        return splits.compactMap { return $0.name }
    }
    
    public func split(featureName: String) -> SplitView? {
        let filtered = splits.filter { return ( featureName.lowercased() == $0.name?.lowercased() ) }
        return filtered.count > 0 ? filtered[0] : nil
    }
}
