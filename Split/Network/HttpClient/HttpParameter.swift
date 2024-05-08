//
//  HttpParameter.swift
//  Split
//
//  Created by Gaston Thea on 08/05/2024.
//  Copyright © 2024 Split. All rights reserved.
//

import Foundation

struct HttpParameter {

    let key: String
    let value: Any?

    init(_ key: String, _ value: Any? = nil) {
        self.key = key
        self.value = value
    }
}
