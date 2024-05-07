//
//  HttpParameters.swift
//  Split
//
//  Created by Gaston Thea on 07/05/2024.
//  Copyright © 2024 Split. All rights reserved.
//

import Foundation

class HttpParameters {
    let order: [String]?
    let values: [String: Any]

    init(values: [String: Any]?, order: [String]? = nil) {
        self.values = values ?? [:]
        self.order = order
    }
}
