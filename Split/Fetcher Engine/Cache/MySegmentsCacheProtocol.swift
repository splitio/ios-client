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
    
    func removeSegments()
    
    func getSegments() -> [String]
    
    func isInSegment(segmentName: String) -> Bool
    
    func clear()

}
