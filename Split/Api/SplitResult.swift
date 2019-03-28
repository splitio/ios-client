//
//  SplitResult.swift
//  Split
//
//  Created by Javier L. Avrudsky on 28/03/2019.
//  Copyright © 2019 Split. All rights reserved.
//

import Foundation

public struct SplitResult {
    var treatment: String
    var configurations: String?
    
    init(treatment: String, configurations: String? = nil) {
        self.treatment = treatment
        self.configurations = configurations
    }
}
