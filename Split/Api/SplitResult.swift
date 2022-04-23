//
//  SplitResult.swift
//  Split
//
//  Created by Javier L. Avrudsky on 28/03/2019.
//  Copyright © 2019 Split. All rights reserved.
//

import Foundation

@objc open class SplitResult: NSObject {
    @objc public var treatment: String
    @objc public var config: String?

    init(treatment: String, config: String? = nil) {
        self.treatment = treatment
        self.config = config
    }
}
