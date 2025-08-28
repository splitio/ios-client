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

    func get(segmentName: String) -> RuleBasedSegment?
    func contains(segmentNames: Set<String>) -> Bool
    func update(toAdd: Set<RuleBasedSegment>, toRemove: Set<RuleBasedSegment>, changeNumber: Int64) -> Bool
    func loadLocal()
    func forceParsing() // For Lazy Parsing optimization
}

class DefaultRuleBasedSegmentsStorage: RuleBasedSegmentsStorage {

    private var persistentStorage: PersistentRuleBasedSegmentsStorage
    private var generalInfoStorage: GeneralInfoStorage
    private var inMemorySegments: ConcurrentDictionary<String, RuleBasedSegment>

    private(set) var changeNumber: Int64 = -1

    init(persistentStorage: PersistentRuleBasedSegmentsStorage, generalInfoStorage: GeneralInfoStorage) {
        self.persistentStorage = persistentStorage
        self.inMemorySegments = ConcurrentDictionary()
        self.generalInfoStorage = generalInfoStorage
    }

    func loadLocal() {
        var segmentsInUse: Int64 = generalInfoStorage.getSegmentsInUse() ?? 0
        let snapshot = persistentStorage.getSnapshot()
        let active = snapshot.segments.filter { $0.status == .active }
        let archived = snapshot.segments.filter { $0.status == .archived }

        _ = processToAdd(Set(active), &segmentsInUse)
        _ = processToRemove(Set(archived), &segmentsInUse)

        changeNumber = snapshot.changeNumber
        generalInfoStorage.setSegmentsInUse(segmentsInUse)
    }

    func get(segmentName: String) -> RuleBasedSegment? {
        guard let segment = inMemorySegments.value(forKey: segmentName.lowercased()) else { return nil }

        if !segment.isParsed { // Parse if neccesaty (Lazy Parsing)
            if let parsedSegment = parseSegment(segment) {
                inMemorySegments.setValue(parsedSegment, forKey: segmentName.lowercased())
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
        
        var segmentsInUse = generalInfoStorage.getSegmentsInUse() ?? 0
        self.changeNumber = changeNumber
        
        // Process
        let addResult = processToAdd(toAdd, &segmentsInUse)
        let removeResult = processToRemove(toRemove, &segmentsInUse)

        // Update persistent storage
        persistentStorage.update(toAdd: toAdd, toRemove: toRemove, changeNumber: changeNumber)
        generalInfoStorage.setSegmentsInUse(segmentsInUse)

        return addResult || removeResult
    }

    private func processToAdd(_ toAdd: Set<RuleBasedSegment>, _ segmentsInUse: inout Int64) -> Bool { // Process segments to add
        var result = false
        
        for segment in toAdd {
            if let segmentName = segment.name?.lowercased() {
                segmentsInUse += updateSegmentsCount(segment)
                inMemorySegments.setValue(segment, forKey: segmentName)
                result = true
            }
        }
        
        return result
    }
    
    private func processToRemove(_ toRemove: Set<RuleBasedSegment>, _ segmentsInUse: inout Int64) -> Bool { // Process segments to remove
        var result = false
        
        for segment in toRemove {
            if let segmentName = segment.name?.lowercased(), inMemorySegments.value(forKey: segmentName) != nil {
                segmentsInUse += updateSegmentsCount(segment)
                inMemorySegments.removeValue(forKey: segmentName)
                result = true
            }
        }
        return result
    }

    func clear() {
        inMemorySegments.removeAll()
        changeNumber = -1
        persistentStorage.clear()
    }
    
    func forceParsing() {
        var segmentsInUse = generalInfoStorage.getSegmentsInUse() ?? 0
        let activeSegments = persistentStorage.getSnapshot().segments.filter { $0.status == .active }
        
        for i in 0..<activeSegments.count {
            guard let segmentName = activeSegments[i].name else { continue }
            
            if let parsedSegment = parseSegment(activeSegments[i]) { // Parse it
                segmentsInUse += updateSegmentsCount(parsedSegment)
                inMemorySegments.setValue(parsedSegment, forKey: segmentName)
            }
        }
        
        generalInfoStorage.setSegmentsInUse(segmentsInUse)
    }
    
    private func parseSegment(_ segment: RuleBasedSegment) -> RuleBasedSegment? {
        guard let parsedSegment = try? Json.decodeFrom(json: segment.json, to: RuleBasedSegment.self) else { return nil }
        return parsedSegment
    }
    
    private func updateSegmentsCount(_ segment: RuleBasedSegment) -> Int64 {
        var segmentsInUse: Int64 = 0
        let segmentName = segment.name?.lowercased() ?? ""
        let inMemorySegment = inMemorySegments.value(forKey: segmentName)
        
        // 1. New Segment
        if inMemorySegment == nil, segment.status == .active, StorageHelper.usesSegments(segment.conditions) {
            segmentsInUse += 1
        }
        
        // 2. Known Segment
        if inMemorySegment != nil, segment.status == .active {
           
            if StorageHelper.usesSegments(segment.conditions ?? []) {

                // Previously not using Segments?
                if StorageHelper.usesSegments(inMemorySegment?.conditions ?? []) == false {
                    return 1
                }
            } else {
                // Not using Segments but previously yes?
                if StorageHelper.usesSegments(inMemorySegment?.conditions ?? []) {
                    return -1
                }
            }
        }
        
        // 3. Known segment just archived
        if inMemorySegment != nil, segment.status == .archived {
            if StorageHelper.usesSegments(segment.conditions ?? []) {
                return -1
            }
        }
        
        return segmentsInUse
    }
    
    #if DEBUG
    func getInMemorySegments() -> ConcurrentDictionary<String, RuleBasedSegment>  {
        inMemorySegments
    }
    #endif
}
