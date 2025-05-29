//
//  RuleBasedSegmentsDecoder.swift
//  Split
//
//  Created by Split on 14/03/2025.
//  Copyright © 2025 Split. All rights reserved.
//

import Foundation

protocol RuleBasedSegmentsDecoder {
    func decode(_ jsonSegments: [String]) -> [RuleBasedSegment]
}

class RuleBasedSegmentsSerialDecoder: RuleBasedSegmentsDecoder {
    private var cipher: Cipher?

    init(cipher: Cipher? = nil) {
        self.cipher = cipher
    }

    func decode(_ jsonSegments: [String]) -> [RuleBasedSegment] {
        var segments = [RuleBasedSegment]()

        for jsonSegment in jsonSegments {
            do {
                let decryptedJson = cipher?.decrypt(jsonSegment) ?? jsonSegment
                let segment = try Json.decodeFrom(json: decryptedJson, to: RuleBasedSegment.self)
                segments.append(segment)
            } catch {
                Logger.e("Error while decoding rule based segment: \(error.localizedDescription)")
                let segment = RuleBasedSegment(name: "unknown")
                segment.isParsed = false
                segment.json = jsonSegment
                segments.append(segment)
            }
        }
        return segments
    }
}
