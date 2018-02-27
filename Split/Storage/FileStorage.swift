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
            
            Logger.e(error.localizedDescription)
            
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
               
                let fileURL = documentDirectory.appendingPathComponent(elementId)
                
                let fileContent = try String(contentsOf: fileURL, encoding: .utf8)
                Logger.d(fileContent)
            }
            
        } catch {
            
            Logger.e(error.localizedDescription)
            
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
            Logger.e("An error took place: \(error)")
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
    public func readWithProperties(elementId: String) -> String? {
        
        let fileManager = FileManager.default
        
        do {
            
            let documentDirectory = try fileManager.url(for: .documentDirectory, in: .userDomainMask, appropriateFor:nil, create:false)
            
            let fileURL = documentDirectory.appendingPathComponent(elementId)
            
            let resources = try fileURL.resourceValues(forKeys: [.creationDateKey])
            let creationDate = resources.creationDate!
            
            if let diff = Calendar.current.dateComponents([.hour], from: creationDate, to: Date()).hour, diff > 24 {

                delete(elementId: elementId)
                return nil
                
            } else {
                
                return try String(contentsOf: fileURL, encoding: .utf8)
                
                
            }
            
        } catch {
            
            Logger.e(error.localizedDescription)
            
        }
        
        return nil
    }
    //------------------------------------------------------------------------------------------------------------------

}
