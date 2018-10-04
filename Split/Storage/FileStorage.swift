//
//  FileStorage.swift
//  Split
//
//  Created by Natalia  Stele on 04/12/2017.
//

import Foundation

class FileStorage: StorageProtocol {
    
    func read(fileName: String) -> String? {
        return read(elementId: fileName)
    }
    
    func read(elementId: String) -> String? {
        let fileManager = FileManager.default
        do {
            let cachesDirectory = try fileManager.url(for: .cachesDirectory, in: .userDomainMask, appropriateFor:nil, create:false)
            let fileURL = cachesDirectory.appendingPathComponent(elementId)
            return try String(contentsOf: fileURL, encoding: .utf8)
        } catch {
            // Logger.e(error.localizedDescription)
            // TODO: Improve this code. For now it's normal than first time no file is available
        }
        return nil
    }
    
    func save(fileName: String, content: String) {
        write(elementId: fileName, content: content)
    }
    
    func write(elementId: String, content: String?) {
        let fileManager = FileManager.default
        do {
            let cachesDirectory = try fileManager.url(for: .cachesDirectory, in: .userDomainMask, appropriateFor:nil, create:false)
            let fileURL = cachesDirectory.appendingPathComponent(elementId)
            
            if let data = content {
                try data.write(to: fileURL, atomically: false, encoding: .utf8)
                let fileURL = cachesDirectory.appendingPathComponent(elementId)
                let fileContent = try String(contentsOf: fileURL, encoding: .utf8)
                Logger.d(fileContent)
            }
        } catch {
            Logger.e("File Storage - write: " + error.localizedDescription)
        }
    }
    
    func delete(fileName: String) {
        delete(elementId: fileName)
    }
    
    func delete(elementId: String) {
        do {
            let fileManager = FileManager.default
            let cachesDirectory = try fileManager.url(for: .cachesDirectory, in: .userDomainMask, appropriateFor:nil, create:false)
            let fileURL = cachesDirectory.appendingPathComponent(elementId)
            try? fileManager.removeItem(at: fileURL)
        } catch let error as NSError {
            Logger.e("File Storage - delete: " + "An error took place: \(error)")
        }
    }
    
    func getAllIds() -> [String]? {
        let fileMngr = FileManager.default
        // Full path to documents directory
        let docs = fileMngr.urls(for: .cachesDirectory, in: .userDomainMask)[0].path
        // List all contents of directory and return as [String] OR nil if failed
        return try? fileMngr.contentsOfDirectory(atPath:docs)
    }
    
    func readWithProperties(elementId: String) -> String? {
        let fileManager = FileManager.default
        do {
            let cachesDirectory = try fileManager.url(for: .cachesDirectory, in: .userDomainMask, appropriateFor:nil, create:false)
            let fileURL = cachesDirectory.appendingPathComponent(elementId)
            let resources = try fileURL.resourceValues(forKeys: [.creationDateKey])
            let creationDate = resources.creationDate!
            
            if let diff = Calendar.current.dateComponents([.hour], from: creationDate, to: Date()).hour, diff > 24 {
                delete(elementId: elementId)
                return nil
            } else {
                return try String(contentsOf: fileURL, encoding: .utf8)
            }
        } catch {
            Logger.e("File Storage - readWithProperties: " + error.localizedDescription)
        }
        return nil
    }
}
