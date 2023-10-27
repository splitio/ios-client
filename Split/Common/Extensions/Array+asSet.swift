//
//  Array+asSet.swift
//  Split
//
//  Created by Javier Avrudsky on 26/09/2023.
//  Copyright © 2023 Split. All rights reserved.
//

import Foundation

extension Array where Element: Hashable {
    func asSet() -> Set<Element> {
        return Set(self)
    }
}
