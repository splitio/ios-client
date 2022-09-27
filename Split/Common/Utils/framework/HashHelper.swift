//
//  HashUtil.swift
//  Split
//
//  Created by Javier Avrudsky on 24-Feb-2022.
//  Copyright © 2022 Split. All rights reserved.
//

import Foundation

struct HashHelper {
    static func hash(_ string: String, salt: String) -> String? {
        return JFBCrypt.hashPassword(string, withSalt: salt)
    }
}
