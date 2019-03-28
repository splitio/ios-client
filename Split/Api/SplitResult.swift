//
//  SplitResult.swift
//  Split
//
//  Created by Javier L. Avrudsky on 28/03/2019.
//  Copyright © 2019 Split. All rights reserved.
//

import Foundation

@objc public class SplitResult: NSObject {
    var treatment: String
    var configurations: String?
    
    init(treatment: String, configurations: String? = nil) {
        self.treatment = treatment
        self.configurations = configurations
    }
}
