//
//  ImpressionsCount.swift
//  Split
//
//  Created by Javier Avrudsky on 22/06/2021.
//  Copyright © 2021 Split. All rights reserved.
//

import Foundation

// This struct could be Encodable,
// but Decodable is needed test properly
struct ImpressionsCount: Codable {
    var perFeature: [ImpressionsCountPerFeature]

    enum CodingKeys: String, CodingKey {
        case perFeature = "pf"
    }
}
