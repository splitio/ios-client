//
//  Segment.swift
//  Split
//
//  Created by Javier L. Avrudsky on 6/11/18.
//

import Foundation

struct Segment: Codable {
    var name: String

    enum CodingKeys: String, CodingKey {
        case name = "n"
    }
}
