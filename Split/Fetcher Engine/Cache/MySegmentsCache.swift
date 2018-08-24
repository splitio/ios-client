//
//  MySegmentsCache.swift
//  Split
//
//  Created by Natalia  Stele on 07/12/2017.
//

import Foundation

public class MySegmentsCache: MySegmentsCacheProtocol {
    
    public static let SEGMENT_FILE_PREFIX: String = "SEGMENTIO.split.mysegments";
    
    private let kClassName = String(describing: MySegmentsCache.self)

    var storage: StorageProtocol

    init(storage: StorageProtocol) {
        
        self.storage = storage
    }
    //------------------------------------------------------------------------------------------------------------------
    public func addSegments(segmentNames: [String], key: String) {

        let userDefaults: UserDefaults = UserDefaults.standard
        userDefaults.set(key, forKey: "key")
        guard let jsonString = try? JSON.encodeToJson(segmentNames) else {
            Logger.e("addSegments: Could not parse data to Json", kClassName)
            return
        }
        storage.write(elementId: MySegmentsCache.SEGMENT_FILE_PREFIX , content: jsonString)
    }
    //------------------------------------------------------------------------------------------------------------------
    public func removeSegments() {
        storage.delete(elementId: MySegmentsCache.SEGMENT_FILE_PREFIX)
    }
    //------------------------------------------------------------------------------------------------------------------
    public func getSegments() -> [String]? {
        return getSegments(key: "")
    }
    
    public func getSegments(key: String) -> [String]? {

        let userDefaults: UserDefaults = UserDefaults.standard
        if let savedKey = userDefaults.string(forKey: "key"), savedKey == key {
            let segments = storage.read(elementId: MySegmentsCache.SEGMENT_FILE_PREFIX)
            if let segmentsStored = segments {
                do {
                    return try JSON.encodeFrom(json: segmentsStored, to: [String].self)
                } catch {
                    Logger.e("getSegments: Error parsing stored segments", kClassName)
                }
            }
        }
        
        return nil
    }
    //------------------------------------------------------------------------------------------------------------------
    public func isInSegment(segmentName: String, key: String) -> Bool {
        
        if let segments = self.getSegments(key:key) {
            return segments.contains(segmentName)
        }
        return false
    }
    //------------------------------------------------------------------------------------------------------------------
    public func clear() {
        
    }
    //------------------------------------------------------------------------------------------------------------------
    
}
