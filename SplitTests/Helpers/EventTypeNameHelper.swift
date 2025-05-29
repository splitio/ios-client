//
//  EventTypeNameHelper.swift
//  SplitTests
//
//  Created by Javier L. Avrudsky on 22/01/2019.
//  Copyright © 2019 Split. All rights reserved.
//

import Foundation

class EventTypeNameHelper {
    var validAllValidChars: String {
        return "Abcdefghij:klmnopkrstuvwxyz_-12345.6789:"
    }

    var validStartNumber: String {
        return "1Abcdefghijklmnopkrstuvwxyz_-12345.6789:"
    }

    var invalidHypenStart: String {
        return "-1Abcdefghijklmnopkrstuvwxyz_-123456789:"
    }

    var invalidUndercoreStart: String {
        return "_1Abcdefghijklmnopkrstuvwxyz_-123456789:"
    }

    var invalidChars: String {
        return "Abcd,;][}{efghijklmnopkrstuvwxyz_-123456789:"
    }
}
