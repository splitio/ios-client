//
//  PlistLocalPersistance.swift
//  Pods
//
//  Created by Brian Sztamfater on 20/9/17.
//
//

import Foundation

@objc public class PlistSplitPersistence: NSObject, SplitPersistence {
    
    let fileName: String
    
    public init(fileName: String) {
        self.fileName = "\(fileName).plist"
    }
    
    public func save(key: String, value: String) {
        writeToFile(value, forKey: key)
    }
    
    public func saveAll(_ dict: [String : String]) {
        let data = NSMutableDictionary(dictionary: dict)
        data.write(toFile: filePath(), atomically: true)
    }
    
    public func get(key: String) -> String? {
        return object(forKey: key) as? String
    }
    
    public func getAll() -> [String : String] {
        guard let data = NSMutableDictionary(contentsOfFile: filePath()) else {
            return NSMutableDictionary() as! [String : String]
        }
        return data as! [String : String]
    }
    
    public func contains(key: String) -> Bool {
        guard let data = NSMutableDictionary(contentsOfFile: filePath()) else {
            return false
        }
        return data.object(forKey: key) != nil
    }
    
    public func remove(key: String) {
        let path = filePath()
        let data = NSMutableDictionary(contentsOfFile: path)
        data?.removeObject(forKey: key)
        data?.write(toFile: path, atomically: true)
    }
    
    public func removeAll() {
        let data = NSMutableDictionary()
        data.write(toFile: filePath(), atomically: true)
    }
    
    private func filePath() -> String {
        let paths = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0] as String
        let path = paths.appending("/\(self.fileName)")
        let fileManager = FileManager.default
        if (!fileManager.fileExists(atPath: path)) {
            let data = NSMutableDictionary()
            data.write(toFile: path, atomically: true)
        }
        return path
    }
    
    private func writeToFile(_ object: Any, forKey key: String) {
        let data = NSMutableDictionary(contentsOfFile: filePath())
        data?.setObject(object, forKey: key as NSString)
        data?.write(toFile: filePath(), atomically: true)
    }
    
    private func object(forKey key: String) -> Any? {
        let data = NSMutableDictionary(contentsOfFile: filePath())
        return data?.object(forKey: key)
    }
}
