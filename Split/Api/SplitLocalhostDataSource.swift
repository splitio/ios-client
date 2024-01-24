//
//  SplitLocalhostDataSource.swift
//  Split
//
//  Created by Javier Avrudsky on 05/01/2024.
//  Copyright © 2024 Split. All rights reserved.
//

import Foundation

@objc public protocol SplitLocalhostDataSource {
    func updateLocalhost(yaml: String) -> Bool
    func updateLocalhost(splits: String) -> Bool
}
