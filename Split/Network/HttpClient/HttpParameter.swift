//
//  HttpParameter.swift
//  Split
//
//  Copyright © 2024 Split. All rights reserved.
//

import Foundation

struct HttpParameter {
    let key: String
    let value: Any?

    init(key: String, value: Any? = nil) {
        self.key = key
        self.value = value
    }
}
