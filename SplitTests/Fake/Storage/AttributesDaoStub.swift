//
//  AttributesDaoStub.swift
//  SplitTests
//
//  Created by Javier Avrudsky on 8/11/2021.
//  Copyright © 2021 Split. All rights reserved.
//

import Foundation
@testable import Split

class AttributesDaoStub: AttributesDao {
    var attributes = [String: [String: Any]]()
    func getBy(userKey: String) -> [String: Any]? {
        return attributes[userKey]
    }

    func update(userKey: String, attributes: [String: Any]?) {
        if let attributes = attributes {
            self.attributes[userKey] = attributes
        } else {
            self.attributes.removeValue(forKey: userKey)
        }
    }

    func syncUpdate(userKey: String, attributes: [String: Any]?) {
        update(userKey: userKey, attributes: attributes)
    }
}
