//
//  RestClient+SseAuthenticator.swift
//  Split
//
//  Created by Javier L. Avrudsky on 13/07/2020.
//  Copyright © 2020 Split. All rights reserved.
//

import Foundation

struct SseAuthenticationResponse: Decodable {
    let pushEnabled: Bool
    let token: String?
    let sseConnectionDelay: Int64?

    enum CodingKeys: String, CodingKey {
        case pushEnabled
        case token
        case sseConnectionDelay = "connDelay"
    }
}

protocol RestClientSseAuthenticator: RestClient {
    func authenticate(userKeys: [String], completion: @escaping (DataResult<SseAuthenticationResponse>) -> Void)
}

extension DefaultRestClient: RestClientSseAuthenticator {
    var kUserKeyParameter: String { "users" }
    func authenticate(userKeys: [String], completion: @escaping (DataResult<SseAuthenticationResponse>) -> Void) {
        var parameters: [String: Any] = [kUserKeyParameter: userKeys]
        if !Spec.flagsSpec.isEmpty() {
            parameters["s"] = Spec.flagsSpec
        }
        self.execute(
            endpoint: endpointFactory.sseAuthenticationEndpoint,
            parameters: HttpParameters(values: parameters, order: ["s", kUserKeyParameter]),
            completion: completion)
    }
}
