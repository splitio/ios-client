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
        
        let date = Date()
        
        let formatter = DateFormatter()

        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        // again convert your date to string
        let dateString = formatter.string(from: date)
        
        let fileName = ImpressionsFileStorage.IMPRESSIONS_FILE_PREFIX + dateString
        storage.write(elementId: fileName, content: impressions)
        
    }
    
    
    func readImpressions() -> [String] {
        
        var files: [String] = []
        
        let fileNames = impressionFileNames()
        
        for impressionFileName in fileNames {
            
            if let content = storage.readWithProperties(elementId: impressionFileName) {
                
                files.append(content)
                
            }
            
        }
        
        return files
        
    }
    
    func deleteImpressions() {
        
        storage.delete(elementId: ImpressionsFileStorage.IMPRESSIONS_FILE_PREFIX)
        
    }
    
    
    func impressionFileNames() -> [String] {
        
        var splitFileNames: [String] = []
        
        let fileManager = FileManager.default
        let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        do {
            
            if let fileURLs = try? fileManager.contentsOfDirectory(at: documentsURL, includingPropertiesForKeys: nil) {
                // process files
                
                for file in fileURLs {
                    
                    let fileName =  file.lastPathComponent
                    print(fileName)
                    splitFileNames.append(fileName)
                    
                }
 
                let filtered = splitFileNames.filter { $0.contains(ImpressionsFileStorage.IMPRESSIONS_FILE_PREFIX) }
                return filtered
                
            }
            
            return splitFileNames
            
        }
        
    }
    
    
}
