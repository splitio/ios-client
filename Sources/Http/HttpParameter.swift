//
//  HttpParameter.swift
//  Http
//
//  Copyright © 2024 Split. All rights reserved.
//

import Foundation

public struct HttpParameter {

    let key: String
    let value: Any?

    public init(key: String, value: Any? = nil) {
        self.key = key
        self.value = value
    }
}
