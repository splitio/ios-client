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
    func read(fileName: String) -> String? {
        return "{}"
    }
    
    func write(fileName: String, content: String?) {
    }
    
    func delete(fileName: String) {
    }
}
