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
    
    init(){
        queue = DispatchQueue(label: NSUUID().uuidString, attributes: .concurrent)
        files = [String: String]()
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
        queue.async(flags: .barrier) {
            self.files.removeValue(forKey: fileName)
        }
    }
}
