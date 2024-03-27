//
//  FeatureFlagsPayloadDecoder.swift
//  Split
//
//  Created by Javier Avrudsky on 26/06/2023.
//  Copyright © 2023 Split. All rights reserved.
//

import Foundation

protocol FeatureFlagsPayloadDecoder {
    func decode(payload: String, compressionUtil: CompressionUtil) throws -> SplitDTO
}

struct DefaultFeatureFlagsPayloadDecoder: FeatureFlagsPayloadDecoder {

    func decode(payload: String, compressionUtil: CompressionUtil) throws -> SplitDTO {
        let json = try decodeAsBytes(payload: payload, compressionUtil: compressionUtil).stringRepresentation
        return try Json.decodeFrom(json: json, to: SplitDTO.self)
    }

    private func decodeAsBytes(payload: String, compressionUtil: CompressionUtil) throws -> Data {
        guard let dec =  Base64Utils.decodeBase64(payload) else {
            throw NotificationPayloadParsingException.errorDecodingBase64
        }
        let descomp = try compressionUtil.decompress(data: dec)
        return descomp
    }
}
