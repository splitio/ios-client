//
//  JwtTokenParser.swift
//  Split
//
//  Created by Javier L. Avrudsky on 10/08/2020.
//  Copyright © 2020 Split. All rights reserved.
//

import Foundation

enum JwtTokenError: Error {
    case tokenIsNull
    case tokenIsInvalid
    case unknonw
}

protocol JwtTokenParser {
    func parse(raw: String?) throws -> JwtToken
}

struct DefaultJwtTokenParser: JwtTokenParser {

    private static let kPublishersChannelMetadata = "channel-metadata:publishers"
    private static let kPublishersCannelPrefix = "[?occupancy=metrics.publishers]"

    func parse(raw: String?) throws -> JwtToken {
        guard let raw = raw else {
            Logger.e("Error: JWT is null.")
            throw JwtTokenError.tokenIsNull
        }

        guard let tokenData = extractTokenData(raw: raw) else {
            Logger.e("SSE authentication JWT payload is not valid.")
            throw JwtTokenError.tokenIsInvalid
        }

        guard let payload = Base64Utils.decodeBase64URL(base64: tokenData) else {
            Logger.e("Could not decode SSE authentication JWT payload.")
            throw JwtTokenError.tokenIsInvalid
        }

        do {
            let authToken = try Json.encodeFrom(json: payload, to: SseAuthToken.self)
            let channelList = try Json.encodeFrom(json: authToken.channels, to: [String: [String]].self)
            let processedChannels: [String] = channelList.compactMap {
                if $0.value.contains(Self.kPublishersChannelMetadata) {
                    return "\(Self.kPublishersCannelPrefix)\($0.key)"
                }
                return $0.key
            }
            return JwtToken(issuedAt: authToken.issuedAt, expirationTime: authToken.expirationTime,
                            channels: processedChannels, rawToken: raw)
        } catch {
            Logger.e("Error parsing SSE authentication JWT json: \(error.localizedDescription)")
            throw JwtTokenError.tokenIsInvalid
        }
    }
}

extension DefaultJwtTokenParser {
    private func extractTokenData(raw: String) -> String? {
        let components = raw.split(separator: ".")
        if components.count > 1 {
            return String(components[1])
        }
        return nil
    }
}
