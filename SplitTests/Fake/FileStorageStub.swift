//
//  FileStorageStub.swift
//  SplitTests
//
//  Created by Javier Avrudsky on 09/11/2018.
//  Copyright © 2018 Split. All rights reserved.
//

import Foundation
@testable import Split

class FileStorageStub: FileStorageProtocol {

    private var queue: DispatchQueue
    private var files: [String: String]
    var lastModified: [String: Int64]
    
    init(){
        queue = DispatchQueue(label: NSUUID().uuidString, attributes: .concurrent)
        files = [String: String]()
        lastModified = [String: Int64]()
    }
    
    func read(fileName: String) -> String? {
        var content: String?
        queue.sync {
            content = files[fileName]
        }
        return content
    }
    
    func write(fileName: String, content: String?) {
        queue.async(flags: .barrier) {
            self.files[fileName] = content
        }
        
    }
    
    func delete(fileName: String) {
        queue.sync {
            self.files.removeValue(forKey: fileName)
        }
    }
    
    func readWithProperties(fileName: String) -> String? {
        var content: String?
        queue.sync {
            content = files[fileName]
        }
        return content
    }

    func lastModifiedDate(fileName: String) -> Int64 {
        return lastModified[fileName] ?? Date().unixTimestamp()
    }

    func getAllIds() -> [String]? {
        return files.keys.map { $0 }
    }
}
