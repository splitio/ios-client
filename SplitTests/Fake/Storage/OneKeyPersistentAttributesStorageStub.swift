//
//  PersistentAttributesStorageStub.swift
//  SplitTests
//
//  Created by Javier L. Avrudsky on 10/11/2020.
//  Copyright © 2020 Split. All rights reserved.
//

import Foundation
@testable import Split

class OneKeyPersistentAttributesStorageStub: OneKeyPersistentAttributesStorage {

    var attributes: [String: Any]?

    func set(_ attributes: [String : Any]) {
        self.attributes = attributes
    }

    func getAll() -> [String : Any]? {
        return attributes
    }

    func clear() {
        attributes = nil
    }
}
