//
//  SynchronizedDictionaryComposed.swift
//  Split
//
//  Created by Javier on 3-Mar-2022.
//  Copyright © 2022 Split. All rights reserved.
//

import Foundation

class SynchronizedDictionaryComposed<K: Hashable, IK: Hashable> {

    private var queue: DispatchQueue = DispatchQueue(label: "Split.SynchronizedDictionaryComposed",
                                                     target: .global())
    private var items = [K: [IK: Any]]()

    func count(forKey key: K) -> Int {
        var count: Int?
        queue.sync {
            count = items[key]?.count
        }
        return count ?? 0
    }

    func values(forKey key: K) -> [IK: Any]? {
        var value: [IK: Any]?
        queue.sync {
            value = items[key]
        }
        return value
    }

    func value(_ innerKey: IK, forKey key: K) -> Any? {
        var value: Any?
        queue.sync {
            value = items[key]?[innerKey]
        }
        return value
    }

    func contains(innerKey: IK, forKey key: K) -> Bool {
        var hasValue: Bool?
        queue.sync {
            hasValue = items[key]?.keys.contains(innerKey)
        }
        return hasValue ?? false
    }

    func set(_ values: [IK: Any], forKey key: K) {
        queue.sync {
            self.items[key] = values
        }
    }

    func set(_ value: Any, forInnerKey innerKey: IK, forKey key: K) {
        queue.sync {
            var values = self.items[key] ?? [:]
            values[innerKey] = value
            self.items[key] = values
        }
    }

    func putValues(_ values: [IK: Any], forKey key: K) {
        queue.sync {
            var newValues = self.items[key] ?? [:]
            for (innerKey, value) in values {
                newValues[innerKey] = value
            }
            self.items[key] = newValues
        }
    }

    func removeValue(_ innerKey: IK, forKey key: K) {
        queue.sync {
            _ = self.items[key]?.removeValue(forKey: innerKey)
        }
    }

    func removeValues(forKey key: K) {
        queue.sync {
            _ = self.items.removeValue(forKey: key)
        }
    }

    func removeAll() {
        queue.sync {
            self.items.removeAll()
        }
    }
}
