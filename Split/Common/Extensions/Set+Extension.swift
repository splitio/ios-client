//
//  Set+Extension.swift
//  Split
//
//  Created by Javier Avrudsky on 02/08/2024.
//  Copyright © 2024 Split. All rights reserved.
//

import Foundation

extension Set {
    func asArray() -> [Element] {
        return [Element](self)
    }
}
