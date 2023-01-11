//
//  UserConsent.swift
//  Split
//
//  Created by Javier Avrudsky on 23-Nov-2022.
//  Copyright © 2022 Split. All rights reserved.
//

import Foundation

@objc public enum UserConsent: Int {
    case granted = 0
    case declined = 1
    case unknown = 2
}
