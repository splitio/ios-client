//x
//  FeatureFlagsPayloadDecoder.swift
//  Split
//
//  Created by Javier Avrudsky on 26/06/2023.
//  Copyright © 2023 Split. All rights reserved.
//

import Foundation

protocol PayloadDecoder {
    func decodeAsBytes(payload: String, compressionUtil: CompressionUtil) throws -> Data
}

protocol FeatureFlagsPayloadDecoder: PayloadDecoder {
    func decode(payload: String, compressionUtil: CompressionUtil) throws -> Split
}

//protocol SegmentsPayloadDecoder: PayloadDecoder  {
//    func decode(payload: String, compressionUtil: CompressionUtil) throws -> Segment
//}

struct DefaultFeatureFlagsPayloadDecoder: FeatureFlagsPayloadDecoder {
    func decodeAsBytes(payload: String, compressionUtil: any CompressionUtil) throws -> Data {
        guard let dec =  Base64Utils.decodeBase64(payload) else {
            throw NotificationPayloadParsingException.errorDecodingBase64
        }
        let descomp = try compressionUtil.decompress(data: dec)
        return descomp
    }
    
    func decode(payload: String, compressionUtil: CompressionUtil) throws -> Split {
        let json = try decodeAsBytes(payload: payload, compressionUtil: compressionUtil).stringRepresentation
        return try Json.decodeFrom(json: json, to: Split.self)
    }
}

//struct DefaultSegmentsPayloadDecoder: SegmentsPayloadDecoder {
//    func decode(payload: String, compressionUtil: CompressionUtil) throws -> Segment {
//        let json = try decodeAsBytes(payload: payload, compressionUtil: compressionUtil).stringRepresentation
//        return try Json.decodeFrom(json: json, to: Segment.self) //TODO: New Segment DTO
//    }
//}

extension PayloadDecoder {
    private func decodeAsBytes(payload: String, compressionUtil: CompressionUtil) throws -> Data {
        guard let dec =  Base64Utils.decodeBase64(payload) else {
            throw NotificationPayloadParsingException.errorDecodingBase64
        }
        let descomp = try compressionUtil.decompress(data: dec)
        return descomp
    }
}
