//
//  DataResult.swift
//  SwiftSeedProject
//
//  Created by Brian Sztamfater on 9/19/17.
//  Copyright © 2017 Split Software. All rights reserved.
//

import Foundation

struct EmptyValue: Codable {
}

enum DataResult<Value> {
    case Success(value: Value?)
    case Failure(error: NSError)
    
    init(_ f: () throws -> Value?) {
        do {
            let value = try f()
            self = .Success(value: value)
        } catch let error as NSError {
            self = .Failure(error: error)
        }
    }
    
    func unwrap() throws -> Value? {
        switch self {
        case .Success(let value):
            return value
        case .Failure(let error):
            throw error
        }
    }
}
