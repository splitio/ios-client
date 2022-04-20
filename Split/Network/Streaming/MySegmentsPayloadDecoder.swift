//
//  MySegmentsPayloadDecoder.swift
//  Split
//
//  Created by Javier Avrudsky on 13-Apr-2022.
//  Copyright © 2022 Split. All rights reserved.
//

import Foundation

protocol MySegmentsPayloadDecoder {
    func hash(userKey: String) -> String
}

class DefaultMySegmentsPayloadDecoder: MySegmentsPayloadDecoder {
    func hash(userKey: String) -> String {
        return Base64Utils.encodeToBase64("\(Murmur3Hash.hashString(userKey, 0))")
    }
}
