//
//  SynchronizedDictionaryComposed.swift
//  Split
//
//  Created by Javier on 3-Mar-2022.
//  Copyright © 2022 Split. All rights reserved.
//

import Foundation

public class SynchronizedDictionaryComposed<K: Hashable, IK: Hashable>: @unchecked Sendable {

    private var queue: DispatchQueue = DispatchQueue(label: "split-synchronized-dictionary-composed",
                                                     target: .global())
    private var items = [K: [IK: Any]]()

    public init() {}

    public func count(forKey key: K) -> Int {
        var count: Int?
        queue.sync {
            count = items[key]?.count
        }
        return count ?? 0
    }

    public func values(forKey key: K) -> [IK: Any]? {
        var value: [IK: Any]?
        queue.sync {
            value = items[key]
        }
        return value
    }

    public func value(_ innerKey: IK, forKey key: K) -> Any? {
        var value: Any?
        queue.sync {
            value = items[key]?[innerKey]
        }
        return value
    }

    public func contains(innerKey: IK, forKey key: K) -> Bool {
        var hasValue: Bool?
        queue.sync {
            hasValue = items[key]?.keys.contains(innerKey)
        }
        return hasValue ?? false
    }

    public func set(_ values: [IK: Any], forKey key: K) {
        queue.sync {
            self.items[key] = values
        }
    }

    public func set(_ value: Any, forInnerKey innerKey: IK, forKey key: K) {
        queue.sync {
            var values = self.items[key] ?? [:]
            values[innerKey] = value
            self.items[key] = values
        }
    }

    public func putValues(_ values: [IK: Any], forKey key: K) {
        queue.sync {
            var newValues = self.items[key] ?? [:]
            for (innerKey, value) in values {
                newValues[innerKey] = value
            }
            self.items[key] = newValues
        }
    }

    public func removeValue(_ innerKey: IK, forKey key: K) {
        queue.sync {
            _ = self.items[key]?.removeValue(forKey: innerKey)
        }
    }

    public func removeValues(forKey key: K) {
        queue.sync {
            _ = self.items.removeValue(forKey: key)
        }
    }

    public func removeAll() {
        queue.sync {
            self.items.removeAll()
        }
    }
}
