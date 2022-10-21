//
//  ByKeyMySegmentsStorage.swift
//  Split
//
//  Created by Javier L. Avrudsky on 03-Mar-2022.
//  Copyright © 2022 Split. All rights reserved.
//

import Foundation

protocol ByKeyMySegmentsStorage {
    func loadLocal()
    func getAll() -> Set<String>
    func set(_ segments: [String])
    func getCount() -> Int
}

class DefaultByKeyMySegmentsStorage: ByKeyMySegmentsStorage {

    private let mySegmentsStorage: MySegmentsStorage
    private let userKey: String

    init(mySegmentsStorage: MySegmentsStorage,
         userKey: String) {
        self.mySegmentsStorage = mySegmentsStorage
        self.userKey = userKey
    }

    func loadLocal() {
        mySegmentsStorage.loadLocal(forKey: userKey)
    }

    func getAll() -> Set<String> {
        return mySegmentsStorage.getAll(forKey: userKey)
    }

    func set(_ segments: [String]) {
        mySegmentsStorage.set(segments, forKey: userKey)
    }

    func getCount() -> Int {
        return mySegmentsStorage.getCount(forKey: userKey)
    }
}
