//
//  FileAndMemoryStorage.swift
//  Split
//
//  Created by Natalia  Stele on 08/12/2017.
//

import Foundation

public class FileAndMemoryStorage: StorageProtocol {
    
    var memoryStorage = MemoryStorage()
    var fileStorage = FileStorage()
    
    public func read(elementId: String) -> String? {
        
        if let result = memoryStorage.read(elementId: elementId) {
            
            return result
            
        }
        
        if let fromFile = fileStorage.read(elementId: elementId) {
            
            return fromFile
            
        }
        
        return nil
        
    }
    
    public func write(elementId: String, content: String?) {
        
       memoryStorage.write(elementId: elementId, content: content)
       fileStorage.write(elementId: elementId, content: content)
        
    }
    
    public func delete(elementId: String) {
        
        memoryStorage.delete(elementId: elementId)
        fileStorage.delete(elementId: elementId)
        
    }
    
    public func getAllIds() -> [String]? {
        
        return fileStorage.getAllIds()
        
    }

}
