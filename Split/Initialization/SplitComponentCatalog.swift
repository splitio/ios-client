//
//  SplitComponentCatalog.swift
//  Split
//
//  Created by Javier Avrudsky on 05/06/2023.
//  Copyright © 2023 Split. All rights reserved.
//

import Foundation

class SplitComponentCatalog {
    private var components: [String: Any] = [:]

    func get<T>(for classType: T) -> Any? {
        // If component exists, return it
        return components[String(describing: classType.self)]
    }

    // This function is implemented using generics
    // because this way type(of: component) returns the original
    // static type.
    // If using Any instead of T we'd get the dynamic type
    func add<T>(component: T) {
        components[String(describing: type(of: component))] = component
    }

    // These two method is used to maintain more than one reference
    // to an instance of the same object
    func add<T>(name: String, component: T) {
        components[name] = component
    }

    func get(byName name: String) -> Any? {
        return components[name]
    }

    func clear() {
        components.removeAll()
    }
}
