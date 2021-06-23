//
//  ImpressionsCountPerFeature.swift
//  Split
//
//  Created by Javier Avrudsky on 22/06/2021.
//  Copyright © 2021 Split. All rights reserved.
//

import Foundation

struct ImpressionsCount {
    var perFeature: [ImpressionsCountPerFeature]

    enum CodingKeys: String, CodingKey {
        case perFeature = "pf"
    }
}
