//
//  SplitEncryptionLevel.swift
//  Split
//
//  Created by Javier Avrudsky on 27-Mar-2023.
//  Copyright © 2023 Split. All rights reserved.
//

import Foundation

@objc public enum SplitEncryptionLevel: Int, Codable {
    case aes128Cbc
    case none
}
