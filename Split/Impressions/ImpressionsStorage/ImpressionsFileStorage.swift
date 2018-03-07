//
//  ImpressionsFileStorage.swift
//  Split
//
//  Created by Natalia  Stele on 11/01/2018.
//

import Foundation


public class ImpressionsFileStorage {
    
    public static let IMPRESSIONS_FILE_PREFIX: String = "impressions_";
    var storage: FileStorage
    
    //------------------------------------------------------------------------------------------------------------------
    init(storage: FileStorage) {
        
        self.storage = storage
        
    }
    //------------------------------------------------------------------------------------------------------------------
    func saveImpressions(impressions: String? = nil, fileName: String? = nil) {
        
        if impressions == nil {
            return
        }
        
        if fileName != nil {
            
            do {
                
                let fileComponents = parseFileName(fileName: fileName!)
                let attemp = Int(fileComponents[2])! + 1
                let attempString = String(attemp)
                
                if attemp > 3 {
                    Logger.d("Failed 3 attempts, deleting impressions from cache")
                    deleteImpressions(fileName: fileName!)
                } else {
                    
                    let path = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0]
                    let documentDirectory = URL(fileURLWithPath: path)
                    let originPath = documentDirectory.appendingPathComponent(fileName!)
                    let newFileName = fileComponents[0] + "_" + fileComponents[1] + "_" + attempString
                    let destinationPath = documentDirectory.appendingPathComponent(newFileName)
                    try FileManager.default.moveItem(at: originPath, to: destinationPath)
                    
                }
            } catch {
                Logger.e(error.localizedDescription)
            }
            
        } else {

            let dateTimestamp = Int(Date().timeIntervalSince1970)
            let stringDate = String(describing: dateTimestamp)
            let fileName = ImpressionsFileStorage.IMPRESSIONS_FILE_PREFIX + stringDate + "_0"
            storage.write(elementId: fileName, content: impressions)
            
        }
    }
    //------------------------------------------------------------------------------------------------------------------
    func readImpressions() -> [String:String] {
        
        var files: [String:String] = [:]
        
        let fileNames = impressionFileNames()
        
        for impressionFileName in fileNames {
            
            Logger.v(impressionFileName)
            
            if let content = storage.readWithProperties(elementId: impressionFileName) {
                
                files[impressionFileName] = content
                
            }
            
        }
        
        return files
        
    }
    //------------------------------------------------------------------------------------------------------------------
    
    func deleteImpressions(fileName: String) {
        
        storage.delete(elementId: fileName)
        
    }
    //------------------------------------------------------------------------------------------------------------------
    func impressionFileNames() -> [String] {
        
        var splitFileNames: [String] = []
        
        let fileManager = FileManager.default
        let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        do {
            
            if let fileURLs = try? fileManager.contentsOfDirectory(at: documentsURL, includingPropertiesForKeys: nil) {
                // process files
                
                for file in fileURLs {
                    
                    let fileName =  file.lastPathComponent
                    Logger.v(fileName)
                    splitFileNames.append(fileName)
                    Logger.v(fileName)
                }
                
                let filtered = splitFileNames.filter { $0.starts(with:ImpressionsFileStorage.IMPRESSIONS_FILE_PREFIX) }
                return filtered
                
            }
            
            return splitFileNames
            
        }
        
    }
    //------------------------------------------------------------------------------------------------------------------
    func parseFileName(fileName: String) -> [String] {
        
        let array = fileName.split{$0 == "_"}.map(String.init)
        Logger.v(array.debugDescription)
        
        return array
 
    }
}
