//
//  DataResult.swift
//  SwiftSeedProject
//
//  Created by Brian Sztamfater on 9/19/17.
//  Copyright © 2017 Split Software. All rights reserved.
//

import Foundation

struct EmptyValue: Codable {}

enum DataResult<Value> {
    case success(value: Value?)
    case failure(error: NSError)

    init(_ function: () throws -> Value?) {
        do {
            let value = try function()
            self = .success(value: value)
        } catch let error as NSError {
            self = .failure(error: error)
        }
    }

    func unwrap() throws -> Value? {
        switch self {
        case let .success(value):
            return value
        case let .failure(error):
            throw error
        }
    }
}
