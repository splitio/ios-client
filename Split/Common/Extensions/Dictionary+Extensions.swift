//
//  Dictionary+JSON.swift
//  Split
//
//  Created by Brian Sztamfater on 20/9/17.
//
//

import Foundation

// swiftlint:disable identifier_name
public func += <K, V> ( left: inout [K: V], right: [K: V]) {
    for (k, v) in right {
        left.updateValue(v, forKey: k)
    }
}
