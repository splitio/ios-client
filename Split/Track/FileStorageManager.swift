//
//  FileStorageManager.swift
//  Split
//
//  Created by Javier Avrudsky on 06/14/2018.
//

import Foundation

public class FileStorageManager {
    
    var storage: FileStorage
    var filePrefix: String
    var limitAttempts = true
    
    init(storage: FileStorage, filePrefix: String) {
        self.storage = storage
        self.filePrefix = "\(filePrefix)_"
    }
    
    func save(content: String? = nil, fileName: String? = nil) {
        
        if content == nil {
            Logger.d("There's no data to store")
            if let fileName = fileName {
                delete(fileName: fileName)
            }
            return
        }
        
        if fileName != nil {
            do {
                let fileComponents = parseFileName(fileName: fileName!)
                let attemp = limitAttempts ? Int(fileComponents[3])! + 1 : 0
                let attempString = String(attemp)
                
                if limitAttempts, attemp > 3 {
                    Logger.d("Failed 3 attempts, deleting Track from cache")
                    delete(fileName: fileName!)
                } else {
                    let path = NSSearchPathForDirectoriesInDomains(.cachesDirectory, .userDomainMask, true)[0]
                    let cachesDirectory = URL(fileURLWithPath: path)
                    let originPath = cachesDirectory.appendingPathComponent(fileName!)
                    let newFileName = fileComponents[0] + "_" + fileComponents[1] + "_" + attempString
                    let destinationPath = cachesDirectory.appendingPathComponent(newFileName)
                    try FileManager.default.moveItem(at: originPath, to: destinationPath)
                }
            } catch {
                Logger.e(error.localizedDescription)
            }
        } else {
            let dateTimestamp = Int(Date().timeIntervalSince1970)
            let stringDate = String(describing: dateTimestamp)
            let fileName = "\(filePrefix)_\(NSUUID().uuidString)_\(stringDate)_0"
            storage.write(elementId: fileName, content: content)
        }
    }
    
    func save(content: String, as fileName: String) {
        storage.write(elementId: fileName, content: content)
    }
    
    func read() -> [String:String] {
        var files: [String:String] = [:]
        let fileNames = storedFileNames()
        
        for fileName in fileNames {
            Logger.v(fileName)
            if let content = storage.readWithProperties(elementId: fileName) {
                files[fileName] = content
            }
        }
        return files
    }
    
    func read(fileName: String) -> String? {
        return storage.readWithProperties(elementId: fileName)
    }
    
    func delete(fileName: String) {
        storage.delete(elementId: fileName)
    }
    
    func storedFileNames() -> [String] {
        var splitFileNames: [String] = []
        
        let fileManager = FileManager.default
        let documentsURL = fileManager.urls(for: .cachesDirectory, in: .userDomainMask)[0]
        do {
            
            if let fileURLs = try? fileManager.contentsOfDirectory(at: documentsURL, includingPropertiesForKeys: nil) {
                for file in fileURLs {
                    let fileName =  file.lastPathComponent
                    Logger.v(fileName)
                    splitFileNames.append(fileName)
                    Logger.v(fileName)
                }
                let filtered = splitFileNames.filter { $0.starts(with:filePrefix) }
                return filtered
            }
            return splitFileNames
        }
    }
    
    func parseFileName(fileName: String) -> [String] {
        let array = fileName.split{$0 == "_"}.map(String.init)
        Logger.v(array.debugDescription)
        
        return array
    }
}
