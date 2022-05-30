//
//  ImpressionsTest.swift
//  Split
//
//  Created by Natalia  Stele on 08/01/2018.
//

import Foundation

struct ImpressionsTest: Codable {
    var testName: String
    var keyImpressions: [KeyImpression]

    enum CodingKeys: String, CodingKey {
        case testName = "f"
        case keyImpressions = "i"
    }
}
