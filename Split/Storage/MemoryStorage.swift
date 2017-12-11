//
//  MemoryStorage.swift
//  Split
//
//  Created by Natalia  Stele on 08/12/2017.
//

import Foundation


public class MemoryStorage: StorageProtocol {
    
    var elements: [String:String] = [:]
   
    //------------------------------------------------------------------------------------------------------------------
    public func read(elementId: String) -> String? {
        
        return elements[elementId]
        
    }
    //------------------------------------------------------------------------------------------------------------------
    public func write(elementId: String, content: String?) {
        
        elements[elementId] = content
        
    }
    //------------------------------------------------------------------------------------------------------------------
    public func delete(elementId: String) {
        
      elements.removeValue(forKey: elementId)
        
    }
    //------------------------------------------------------------------------------------------------------------------
    public func getAllIds() -> [String]? {
        
        var keys: [String] = []
        
        for key in elements.keys {
            
            keys.append(key)
            
        }
        
        return keys
    }
    //------------------------------------------------------------------------------------------------------------------

    
}
