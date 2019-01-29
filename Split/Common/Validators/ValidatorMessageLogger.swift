//
//  ValidatorMessageLogger.swift
//  Split
//
//  Created by Javier L. Avrudsky on 29/01/2019.
//  Copyright © 2019 Split. All rights reserved.
//

import Foundation

protocol ValidationMessageLogger {
    func e(_ message: String)
    func w(_ message: String)
}

class DefaultValidationMessageLogger: ValidationMessageLogger {
    
    let tag: String
    
    init(tag: String) {
        self.tag = tag
    }
    
    func e(_ message: String) {
        Logger.e("\(tag): \(message)")
    }
    
    func w(_ message: String) {
        Logger.w("\(tag): \(message)")
    }
}
