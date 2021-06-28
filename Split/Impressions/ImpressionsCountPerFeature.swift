//
//  ImpressionsCountPerFeature.swift
//  Split
//
//  Created by Javier Avrudsky on 22/06/2021.
//  Copyright © 2021 Split. All rights reserved.
//

import Foundation

struct ImpressionsCountPerFeature: Codable {
    var storageId: String?
    var feature: String
    var timeframe: Int64
    var count: Int

    enum CodingKeys: String, CodingKey {
        case feature = "f"
        case timeframe = "m"
        case count = "rc"
    }
}
