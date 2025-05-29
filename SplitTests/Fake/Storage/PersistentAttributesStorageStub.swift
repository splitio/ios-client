//
//  PersistentAttributesStorageStub.swift
//  SplitTests
//
//  Created by Javier L. Avrudsky on 10/11/2020.
//  Copyright © 2020 Split. All rights reserved.
//

import Foundation
@testable import Split

class PersistentAttributesStorageStub: PersistentAttributesStorage {
    var attributes = [String: [String: Any]]()
    func set(_ attributes: [String: Any], forKey key: String) {
        self.attributes[key] = attributes
    }

    func getAll(forKey key: String) -> [String: Any]? {
        return attributes[key]
    }

    func clear(forKey key: String) {
        attributes.removeValue(forKey: key)
    }
}
