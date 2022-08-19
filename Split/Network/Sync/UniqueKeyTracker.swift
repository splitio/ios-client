//
//  UniqueKeyTracker.swift
//  Split
//
//  Created by Javier Avrudsky on 19-May-2022.
//  Copyright © 2022 Split. All rights reserved.
//

import Foundation

protocol UniqueKeyTracker {
    func track(userKey: String, featureName: String)
    func saveAndClear()
}

class DefaultUniqueKeyTracker: UniqueKeyTracker {

    let uniqueKeyStorage: PersistentUniqueKeysStorage
    let inMemoryKeys = SynchronizedDictionarySet<String, String>()
    init(persistentUniqueKeyStorage: PersistentUniqueKeysStorage) {
        self.uniqueKeyStorage = persistentUniqueKeyStorage
    }

    func track(userKey: String, featureName: String) {
        inMemoryKeys.insert(featureName, forKey: userKey)
    }

    func saveAndClear() {
        let keys = inMemoryKeys.takeAll()
        var uniqueKeys = [UniqueKey]()
        keys.forEach { userKey, features in
            uniqueKeys.append(UniqueKey(userKey: userKey, features: features))
        }
        uniqueKeyStorage.pushMany(keys: uniqueKeys)
    }
}
