//
//  ValidationConfig.swift
//  Split
//
//  Created by Javier L. Avrudsky on 17/01/2019.
//  Copyright © 2019 Split. All rights reserved.
//

import Foundation

struct ValidationConfig {
    var maximumKeyLength = 250
    var trackEventNamePattern = "^[a-zA-Z0-9][-_.:a-zA-Z0-9]{0,79}$"
    
    static var `default`: ValidationConfig = {
        return ValidationConfig()
    }()
}
