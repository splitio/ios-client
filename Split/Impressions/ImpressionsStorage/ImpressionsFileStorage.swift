//
//  ImpressionsFileStorage.swift
//  Split
//
//  Created by Natalia  Stele on 11/01/2018.
//

import Foundation


public class ImpressionsFileStorage {
    
    public static let IMPRESSIONS_FILE_PREFIX: String = "IMPRESSIONSIO.split.impressions";
    var storage: FileStorage
    
    
    init(storage: FileStorage) {
        
        self.storage = storage
        
    }
    
    
    func saveImpressions(impressions: String) {
        
        storage.write(elementId: ImpressionsFileStorage.IMPRESSIONS_FILE_PREFIX, content: impressions)
        
    }
    
    
    func readImpressions() -> String {
        
        if let content = storage.read(elementId: ImpressionsFileStorage.IMPRESSIONS_FILE_PREFIX) {
            
            return content
        }
        
        return " "
        
    }
    
    func deleteImpressions() {
        
        storage.delete(elementId: ImpressionsFileStorage.IMPRESSIONS_FILE_PREFIX)
        
    }
    
}
