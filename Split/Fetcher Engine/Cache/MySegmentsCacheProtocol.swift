//
//  SegmentsCacheProtocol.swift
//  Pods
//
//  Created by Brian Sztamfater on 2/10/17.
//
//

import Foundation

public protocol MySegmentsCacheProtocol {
    
    func addSegments(segmentNames: [String], key: String)
    
    func removeSegments()
    
    func getSegments() -> [String]?
    
    func getSegments(key: String) -> [String]?
    
    func isInSegment(segmentName: String, key:String) -> Bool
    
    func clear()

}
