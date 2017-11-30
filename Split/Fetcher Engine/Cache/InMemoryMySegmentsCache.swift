//
//  InMemorySegmentsCache.swift
//  Pods
//
//  Created by Brian Sztamfater on 2/10/17.
//
//

import Foundation

@objc public final class InMemoryMySegmentsCache: NSObject, MySegmentsCacheProtocol {
    
    private var mySegments: NSMutableDictionary = NSMutableDictionary()
    private var changeNumber: Int64

    public init(segments: [String] = [], changeNumber: Int64 = -1) {
        var dict = [String : String]()
        for name in segments {
            dict[name] = name
        }
        self.mySegments.addEntries(from: dict)
        self.changeNumber = changeNumber
    }
    
    public func addSegments(segmentNames: [String]) {
        var dict = [String : String]()
        for name in segmentNames {
            dict[name] = name
        }
        self.mySegments.addEntries(from: dict)
    }
    
    public func removeSegment(segmentName: String) {
        self.mySegments.removeObject(forKey: segmentName)
    }
    
    public func getSegments() -> [String] {
        return self.mySegments.allKeys as! [String]
    }
    
    public func isInSegment(segmentName: String) -> Bool {
        return self.mySegments.object(forKey: segmentName) != nil
    }
    
    public func setChangeNumber(_ changeNumber: Int64) {
        self.changeNumber = changeNumber
    }
    
    public func getChangeNumber() -> Int64 {
        return self.changeNumber
    }
    
    public func clear() {
        self.mySegments.removeAllObjects()
    }
    
}
