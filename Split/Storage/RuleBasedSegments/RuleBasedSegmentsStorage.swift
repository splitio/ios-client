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
        let snapshot = persistentStorage.getSnapshot()
        let active = snapshot.segments.filter { $0.status == .active }
        let archived = snapshot.segments.filter { $0.status == .archived }

        // Process active segments
        for segment in active {
            if let segmentName = segment.name?.lowercased() {
                inMemorySegments.setValue(segment, forKey: segmentName)
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
        segmentsInUse = persistentStorage.getSegmentsInUse()

        // Process segments to add
        for segment in toAdd {
            if let segmentName = segment.name?.lowercased() {
                inMemorySegments.setValue(segment, forKey: segmentName)
                updated = true
            }
        }
        
        // Keep count of segments in use
        for segment in toAdd {
            checkUsedSegments(segment)
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
        persistentStorage.update(segmentsInUse: segmentsInUse)

        return updated
    }

    func clear() {
        inMemorySegments.removeAll()
        changeNumber = -1
        persistentStorage.clear()
    }
    
    private func checkUsedSegments(_ segment: RuleBasedSegment) {
        // This is an optimization feature. The idea is to keep a count of the flags using
        // segments. If zero -> never call the endpoint.
        
        guard let segmentName = segment.name, let conditions = segment.conditions, !conditions.isEmpty, inMemorySegments.value(forKey: segmentName) == nil else { return }
        
        for condition in conditions {
            let matchers = condition.matcherGroup?.matchers ?? []
            for matcher in matchers {
                if matcher.matcherType == .inRuleBasedSegment {
                    segmentsInUse += 1
                    return
                }
            }
        }
        
        return
    }
}
