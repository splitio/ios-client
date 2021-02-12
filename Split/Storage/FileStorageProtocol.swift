//
//  FileStorageProtocol.swift
//  Split
//
//  Created by Javier on 08/11/2018.
//  Copyright © 2018 Split. All rights reserved.
//

import Foundation

protocol FileStorageProtocol {
    func read(fileName: String) -> String?
    func write(fileName: String, content: String?)
    func delete(fileName: String)
    func readWithProperties(fileName: String) -> String?
    func getAllIds() -> [String]?
    func lastModifiedDate(fileName: String) -> Int64
}
