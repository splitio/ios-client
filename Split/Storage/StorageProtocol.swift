//
//  StorageProtocol.swift
//  Split
//
//  Created by Natalia  Stele on 04/12/2017.
//

import Foundation

public protocol StorageProtocol {
    
    func read(elementId: String) -> String?
    func write(elementId: String, content: String?)
    func delete(elementId: String)
    func getAllIds() -> [String]?
    
    
}

