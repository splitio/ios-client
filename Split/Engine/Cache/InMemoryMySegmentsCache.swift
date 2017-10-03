//
//  InMemorySegmentsCache.swift
//  Pods
//
//  Created by Brian Sztamfater on 2/10/17.
//
//

import Foundation

@objc public final class InMemoryMySegmentsCache: NSObject, MySegmentsCacheProtocol {
    
    private let mySegments: NSMutableArray
    private var changeNumber: Int64

    public init(segments: [String] = [], changeNumber: Int64 = -1) {
        self.mySegments = NSMutableArray(array: segments)
        self.changeNumber = changeNumber
    }
    
    public func addSegments(segmentNames: [String]) {
        for segmentName in segmentNames {
            if !isInSegment(segmentName: segmentName) {
                self.mySegments.add(segmentName)
            }
        }
    }
    
    public func removeSegment(segmentName: String) {
        for mySegment in mySegments as NSArray as! [String] {
            if segmentName == mySegment {
                self.mySegments.remove(segmentName)
                return
            }
        }
    }
    
    public func getSegments() -> [String] {
        return self.mySegments as! [String]
    }
    
    public func isInSegment(segmentName: String) -> Bool {
        for mySegment in self.mySegments as NSArray as! [String] {
            if segmentName == mySegment {
                return true
            }
        }
        return false
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
