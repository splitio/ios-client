//
//  FeatureFlagsPayloadDecoder.swift
//  Split
//
//  Created by Javier Avrudsky on 26/06/2023.
//  Copyright © 2023 Split. All rights reserved.
//

import Foundation

protocol TargetingRulePayloadDecoder {
    associatedtype DecodedType
    func decode(payload: String, compressionUtil: CompressionUtil) throws -> DecodedType
}

class DefaultTargetingRulePayloadDecoder<T: Decodable>: TargetingRulePayloadDecoder {
    typealias DecodedType = T

    private let type: T.Type

    init(type: T.Type) {
        self.type = type
    }

    func decode(payload: String, compressionUtil: CompressionUtil) throws -> T {
        let json = try decodeAsBytes(payload: payload, compressionUtil: compressionUtil).stringRepresentation
        return try Json.decodeFrom(json: json, to: type)
    }

    private func decodeAsBytes(payload: String, compressionUtil: CompressionUtil) throws -> Data {
        guard let dec =  Base64Utils.decodeBase64(payload) else {
            throw NotificationPayloadParsingException.errorDecodingBase64
        }
        let descomp = try compressionUtil.decompress(data: dec)
        return descomp
    }
}

typealias DefaultFeatureFlagsPayloadDecoder = DefaultTargetingRulePayloadDecoder<Split>
typealias DefaultRuleBasedSegmentsPayloadDecoder = DefaultTargetingRulePayloadDecoder<RuleBasedSegment>
