//
//  MySegmentsStorage.swift
//  Split
//
//  Created by Javier L. Avrudsky on 09/11/2020.
//  Copyright © 2020 Split. All rights reserved.
//

import Foundation

protocol MySegmentsStorage {
    func loadLocal()
    func getAll() -> Set<String>
    func set(_ segments: [String])
    func clear()
}

class DefaultMySegmentsStorage: MySegmentsStorage {
     
    func loadLocal() {

    }

    func getAll() -> Set<String> {
        return Set()
    }

    func set(_ segments: [String]) {

    }

    func clear() {

    }
}
