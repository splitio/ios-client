//
//  FileStorageProtocol.swift
//  Split
//
//  Created by Javier on 08/11/2018.
//  Copyright © 2018 Split. All rights reserved.
//

import Foundation

protocol FileStorage {
    func read(fileName: String) -> String?
    func write(fileName: String, content: String?)
    func delete(fileName: String)
    func getAllIds() -> [String]?
}
