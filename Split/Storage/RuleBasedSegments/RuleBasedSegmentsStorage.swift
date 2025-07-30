//
//  RuleBasedSegmentsStorage.swift
//  Split
//
//  Created by Split on 14/03/2025.
//  Copyright 2025 Split. All rights reserved.
//

import Foundation

protocol RuleBasedSegmentsStorage: RolloutDefinitionsCache {
    var changeNumber: Int64 { get }
    var segmentsInUse: Int64 { get }

    func get(segmentName: String) -> RuleBasedSegment?
    func contains(segmentNames: Set<String>) -> Bool
    func update(toAdd: Set<RuleBasedSegment>, toRemove: Set<RuleBasedSegment>, changeNumber: Int64) -> Bool
    func loadLocal()
}

class DefaultRuleBasedSegmentsStorage: RuleBasedSegmentsStorage {

    private var persistentStorage: PersistentRuleBasedSegmentsStorage
    private var inMemorySegments: ConcurrentDictionary<String, RuleBasedSegment>

    private(set) var changeNumber: Int64 = -1
    
    internal var segmentsInUse: Int64 = 0

    init(persistentStorage: PersistentRuleBasedSegmentsStorage) {
        self.persistentStorage = persistentStorage
        self.inMemorySegments = ConcurrentDictionary()
    }

    func loadLocal() {
        
        if persistentStorage.getSegmentsInUse() == nil {
            forceReparsing()
        } else {
            segmentsInUse = persistentStorage.getSegmentsInUse() ?? 0
            let snapshot = persistentStorage.getSnapshot()
            let active = snapshot.segments.filter { $0.status == .active }
            let archived = snapshot.segments.filter { $0.status == .archived }
            
            // Process active segments
            for segment in active {
                if let segmentName = segment.name?.lowercased() {
                    inMemorySegments.setValue(segment, forKey: segmentName)
                    
                    if StorageHelper.usesSegments(segment.conditions) {
                        segmentsInUse += 1
                    }
                }
            }
            
            // Process archived segments - remove them from memory if they exist
            for segment in archived {
                if let segmentName = segment.name?.lowercased() {
                    inMemorySegments.removeValue(forKey: segmentName)
                }
            }
            
            changeNumber = snapshot.changeNumber
        }
        
        persistentStorage.setSegmentsInUse(segmentsInUse)
    }

    func get(segmentName: String) -> RuleBasedSegment? {
        guard let segment = inMemorySegments.value(forKey: segmentName.lowercased()) else {
            return nil
        }

        if !segment.isParsed {
            if let parsed = try? Json.decodeFrom(json: segment.json, to: RuleBasedSegment.self) {
                inMemorySegments.setValue(parsed, forKey: segmentName.lowercased())
                return parsed
            }
            return nil
        }
        return segment
    }

    func contains(segmentNames: Set<String>) -> Bool {
        let lowercasedNames = segmentNames.map { $0.lowercased() }
        let segmentKeys = Set(inMemorySegments.all.keys)
        return !lowercasedNames.filter { segmentKeys.contains($0) }.isEmpty
    }

    func update(toAdd: Set<RuleBasedSegment>, toRemove: Set<RuleBasedSegment>, changeNumber: Int64) -> Bool {
        
        var updated = false
        segmentsInUse = persistentStorage.getSegmentsInUse() ?? 0
        
        // Keep count of Segments in use
        for segment in toAdd.union(toRemove) {
            if StorageHelper.usesSegments(segment.conditions) {
                if let segmentName = segment.name?.lowercased(), segment.status == .active && inMemorySegments.value(forKey: segmentName) == nil {
                    segmentsInUse += 1
                } else if inMemorySegments.value(forKey: segment.name?.lowercased() ?? "") != nil && segment.status != .active {
                    segmentsInUse -= 1
                }
            }
        }

        // Process segments to add
        for segment in toAdd {
            if let segmentName = segment.name?.lowercased() {
                inMemorySegments.setValue(segment, forKey: segmentName)
                updated = true
            }
        }

        // Process segments to remove
        for segment in toRemove {
            if let segmentName = segment.name?.lowercased(), inMemorySegments.value(forKey: segmentName) != nil {
                inMemorySegments.removeValue(forKey: segmentName)
                updated = true
            }
        }

        self.changeNumber = changeNumber

        // Update persistent storage
        persistentStorage.update(toAdd: toAdd, toRemove: toRemove, changeNumber: changeNumber)
        persistentStorage.setSegmentsInUse(segmentsInUse)

        return updated
    }

    func clear() {
        inMemorySegments.removeAll()
        changeNumber = -1
        persistentStorage.clear()
    }
    
    private func forceReparsing() {
        let snapshot = persistentStorage.getSnapshot()
        var persistedActiveSplits = snapshot.segments.filter { $0.status == .active }
        
        for i in 0..<persistedActiveSplits.count {
            guard let splitName = persistedActiveSplits[i].name else { continue }
            
            inMemorySegments.setValue(persistedActiveSplits[i], forKey: splitName) // Add it so get() recognizes them
            
            if let parsedSplit = get(segmentName: splitName) { // Parse it
                persistedActiveSplits[i] = parsedSplit
            }
            inMemorySegments.removeValue(forKey: splitName) // And remove it, so processUpdate() thinks they are new
        }
        
        _ = update(toAdd: Set(persistedActiveSplits), toRemove: Set(snapshot.segments.filter { $0.status == .archived }), changeNumber: snapshot.changeNumber)
    }
}
