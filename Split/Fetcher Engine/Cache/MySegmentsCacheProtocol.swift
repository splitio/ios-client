//
//  SegmentsCacheProtocol.swift
//  Pods
//
//  Created by Brian Sztamfater on 2/10/17.
//
//

import Foundation

@objc public protocol MySegmentsCacheProtocol {
    
    func addSegments(segmentNames: [String])
    
    func removeSegment(segmentName: String)
    
    func getSegments() -> [String]
    
    func isInSegment(segmentName: String) -> Bool
    
    func setChangeNumber(_ changeNumber: Int64)
    
    func getChangeNumber() -> Int64
    
    func clear()

}
