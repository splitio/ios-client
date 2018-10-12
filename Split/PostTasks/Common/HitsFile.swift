//
//  HitsFile.swift
//  Split
//
//  Created by Javier L. Avrudsky on 09/28/18.
//

import Foundation

class HitsFile<T: Codable>: Codable {
    var oldHits: [String: T]?
    var currentHit: T?
}
