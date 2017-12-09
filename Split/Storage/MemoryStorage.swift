//
//  MemoryStorage.swift
//  Split
//
//  Created by Natalia  Stele on 08/12/2017.
//

import Foundation


public class MemoryStorage: StorageProtocol {
    
    public func read(elementId: String) -> String? {
        
    }
    
    public func write(elementId: String, content: String?) {
        
    }
    
    public func delete(elementId: String) {
    
    }
    
    public func getAllIds() -> [String]? {
        
    }
    
    
    private var storage:  [String:String] = [:]
    
    
    
    
    
}
