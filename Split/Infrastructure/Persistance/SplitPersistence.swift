//
//  SplitClient.swift
//  Pods
//
//  Created by Brian Sztamfater on 18/9/17.
//
//

import Foundation

@objc public protocol SplitPersistence {
    
    func save(key: String, value: String)

    func get(key: String) -> String?
    
    func getAll() -> [String : String]

    func remove(key: String)
    
    func removeAll()
    
    func contains(key: String) -> Bool
}
