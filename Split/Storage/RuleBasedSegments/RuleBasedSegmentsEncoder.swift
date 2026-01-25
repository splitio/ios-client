//
//  RuleBasedSegmentsEncoder.swift
//  Split
//
//  Created by Split on 14/03/2025.
//  Copyright © 2025 Split. All rights reserved.
//

import Foundation
import Logging

protocol RuleBasedSegmentsEncoder {
    func encode(_ segments: [RuleBasedSegment]) -> [String: String]
}

class RuleBasedSegmentsSerialEncoder: RuleBasedSegmentsEncoder {

    private var cipher: Cipher?

    init(cipher: Cipher? = nil) {
        self.cipher = cipher
    }

    func encode(_ segments: [RuleBasedSegment]) -> [String: String] {
        var result = [String: String]()

        for segment in segments {
            guard let segmentName = segment.name?.lowercased() else {
                continue
            }

            do {
                let json = try Json.encodeToJson(segment)
                let encryptedName = cipher?.encrypt(segmentName) ?? segmentName
                let encryptedJson = cipher?.encrypt(json) ?? json
                result[encryptedName] = encryptedJson
            } catch {
                Logger.e("Error while encoding rule based segment: \(error.localizedDescription)")
            }
        }
        return result
    }
}
