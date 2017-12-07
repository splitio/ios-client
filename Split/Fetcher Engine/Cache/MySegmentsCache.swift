//
//  MySegmentsCache.swift
//  Split
//
//  Created by Natalia  Stele on 07/12/2017.
//

import Foundation
import SwiftyJSON

public class MySegmentsCache: MySegmentsCacheProtocol {
    
    public static let SEGMENT_FILE_PREFIX: String = "SEGMENTIO.split.mysegments";

    var storage: StorageProtocol

    init(storage: StorageProtocol) {
        
        self.storage = storage
    }
    
    public func addSegments(segmentNames: [String]) {
        
            let json: JSON = JSON(segmentNames)
            let jsonString = json.rawString()

        storage.write(elementId: MySegmentsCache.SEGMENT_FILE_PREFIX , content: jsonString)
        
    }
    
    public func removeSegments() {
        
        storage.delete(elementId: MySegmentsCache.SEGMENT_FILE_PREFIX)
    
    }
    
    public func getSegments() -> [String] {
        
        let segments = storage.read(elementId: MySegmentsCache.SEGMENT_FILE_PREFIX)
        if let segmentsStored = segments {
            
            let json: JSON = JSON(segmentsStored)
            
            if let array = json.arrayObject as? [String] {
                
                return array
                
            }
            
        }
        
        return []
    }
    
    public func isInSegment(segmentName: String) -> Bool {
        
        let segments = self.getSegments()
        return segments.contains(segmentName)
        
    }
        
    public func clear() {
        
    }
 
    
}
