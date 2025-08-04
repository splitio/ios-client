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
    func forceParsing() // For Lazy Parsing optimization
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
        
        segmentsInUse = persistentStorage.getSegmentsInUse() ?? 0
        let snapshot = persistentStorage.getSnapshot()
        let active = snapshot.segments.filter { $0.status == .active }
        let archived = snapshot.segments.filter { $0.status == .archived }
        
        // Process active segments
        for segment in active {
            if let segmentName = segment.name?.lowercased() {
                if inMemorySegments.value(forKey: segmentName) == nil, StorageHelper.usesSegments(segment.conditions) {
                    segmentsInUse += 1
                    inMemorySegments.setValue(segment, forKey: segmentName)
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
        persistentStorage.setSegmentsInUse(segmentsInUse)
    }

    func get(segmentName: String) -> RuleBasedSegment? {
        guard let segment = inMemorySegments.value(forKey: segmentName.lowercased()) else { return nil }

        if !segment.isParsed { // Parse if neccesaty (Lazy Parsing)
            if let parsedSegment = parseSegment(segment) {
                return parsedSegment
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
        
        segmentsInUse = persistentStorage.getSegmentsInUse() ?? 0
        self.changeNumber = changeNumber
        
        // Process
        let addResult = processToAdd(toAdd)
        let removeResult = processToRemove(toRemove)

        // Update persistent storage
        persistentStorage.update(toAdd: toAdd, toRemove: toRemove, changeNumber: changeNumber)
        persistentStorage.setSegmentsInUse(segmentsInUse)

        return addResult || removeResult
    }

    private func processToAdd(_ toAdd: Set<RuleBasedSegment>) -> Bool { // Process segments to add
        for segment in toAdd {
            if let segmentName = segment.name?.lowercased() {
                updateSegmentsCount(segment)
                inMemorySegments.setValue(segment, forKey: segmentName)
                return true
            }
        }
        return false
    }
    
    private func processToRemove(_ toRemove: Set<RuleBasedSegment>) -> Bool { // Process segments to remove
        for segment in toRemove {
            if let segmentName = segment.name?.lowercased(), inMemorySegments.value(forKey: segmentName) != nil {
                updateSegmentsCount(segment)
                inMemorySegments.removeValue(forKey: segmentName)
                return true
            }
        }
        return false
    }

    func clear() {
        inMemorySegments.removeAll()
        changeNumber = -1
        persistentStorage.clear()
    }
    
    func forceParsing() {
        let snapshot = persistentStorage.getSnapshot()
        let activeSegments = snapshot.segments.filter { $0.status == .active }
        
        for i in 0..<activeSegments.count {
            guard let segmentName = activeSegments[i].name else { continue }
            
            if let parsedSegment = parseSegment(activeSegments[i]) { // Parse it
                updateSegmentsCount(parsedSegment)
                inMemorySegments.setValue(parsedSegment, forKey: segmentName)
            }
        }
        
        persistentStorage.setSegmentsInUse(segmentsInUse)
    }
    
    fileprivate func parseSegment(_ segment: RuleBasedSegment) -> RuleBasedSegment? {
        guard let parsedSegment = try? Json.decodeFrom(json: segment.json, to: RuleBasedSegment.self) else { return nil }
        return parsedSegment
    }
    
    fileprivate func updateSegmentsCount(_ segment: RuleBasedSegment) {
        if let segmentName = segment.name?.lowercased(), segment.status == .active && inMemorySegments.value(forKey: segmentName) == nil {
            segmentsInUse += 1
        } else if inMemorySegments.value(forKey: segment.name?.lowercased() ?? "") != nil && segment.status != .active {
            segmentsInUse -= 1
        }
    }
}
