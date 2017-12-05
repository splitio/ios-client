//
//  FileStorage.swift
//  Split
//
//  Created by Natalia  Stele on 04/12/2017.
//

import Foundation


public class FileStorage: StorageProtocol {
    
    //------------------------------------------------------------------------------------------------------------------
    public func read(elementId: String) -> String? {
        
        let fileManager = FileManager.default
        
        do {
            
            let documentDirectory = try fileManager.url(for: .documentDirectory, in: .userDomainMask, appropriateFor:nil, create:false)
            let fileURL = documentDirectory.appendingPathComponent(elementId)
            
            return try String(contentsOf: fileURL, encoding: .utf8)
            
        } catch {
            
            print(error)
            
        }
        
        return nil
    }
    //------------------------------------------------------------------------------------------------------------------
    public func write(elementId: String, content: String?) {
        
        let fileManager = FileManager.default
        
        do {
            
            let documentDirectory = try fileManager.url(for: .documentDirectory, in: .userDomainMask, appropriateFor:nil, create:false)
            let fileURL = documentDirectory.appendingPathComponent(elementId)
            
            if let data = content {
                
                try data.write(to: fileURL, atomically: false, encoding: .utf8)
            }
            
        } catch {
            
            print(error)
            
        }
        
    }
    //------------------------------------------------------------------------------------------------------------------
    public func delete(elementId: String) {
        
        do {
            
            let fileManager = FileManager.default
            
            let documentDirectory = try fileManager.url(for: .documentDirectory, in: .userDomainMask, appropriateFor:nil, create:false)
            let fileURL = documentDirectory.appendingPathComponent(elementId)
            
            try fileManager.removeItem(at: fileURL)
            
        }
        catch let error as NSError {
            print("An error took place: \(error)")
        }
    }
    //------------------------------------------------------------------------------------------------------------------
    public func getAllIds() -> [String]? {
        
        let fileMngr = FileManager.default
        
        // Full path to documents directory
        let docs = fileMngr.urls(for: .documentDirectory, in: .userDomainMask)[0].path
        
        // List all contents of directory and return as [String] OR nil if failed
        return try? fileMngr.contentsOfDirectory(atPath:docs)
        
    }
    //------------------------------------------------------------------------------------------------------------------
  
}
