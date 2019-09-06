//
//  ValidationConfig.swift
//  Split
//
//  Created by Javier L. Avrudsky on 17/01/2019.
//  Copyright © 2019 Split. All rights reserved.
//

import Foundation

///
///  Default config for validations component
///  This configuration should be overwrote in factory or client instantiation
///  with Split Config values
///
struct ValidationConfig {

    ///
    ///  Maximum character length for Matching key
    ///  and Bucketing key
    ///
    var maximumKeyLength = 250

    ///
    ///  Regex used to validate Track Event Name
    ///
    var trackEventNamePattern = "^[a-zA-Z0-9][-_.:a-zA-Z0-9]{0,79}$"

    ///
    /// maximumEventPropertyBytes
    ///
    let maximumEventPropertyBytes: Int = 32768

    ///
    /// Maximum properties count for a track event
    ///
    let maxEventPropertiesCount = 300

    static var `default`: ValidationConfig = {
        return ValidationConfig()
    }()
}
