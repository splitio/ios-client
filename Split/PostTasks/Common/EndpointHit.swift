//
//  EndpointHit.swift
//  Split
//
//  Created by Javier L. Avrudsky on 09/28/18.
//
import Foundation

class EndpointHit<T: Codable>: Codable {
    var identifier: String
    var items: T
    var attempts: Int = 0
    
    init(identifier: String, items: T){
        self.identifier = identifier
        self.items = items
    }
    
    func addAttempt(){
        attempts += 1
    }
    
}
