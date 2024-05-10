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
        self.execute(
            endpoint: endpointFactory.sseAuthenticationEndpoint,
            parameters: buildParameters(userKeys: userKeys),
            completion: completion)
    }

    private func buildParameters(userKeys: [String]) -> HttpParameters {
        var parameters: [HttpParameter] = []
        if !Spec.flagsSpec.isEmpty() {
            parameters.append(HttpParameter(key: "s", value: Spec.flagsSpec))
        }

        parameters.append(HttpParameter(key: kUserKeyParameter, value: userKeys))

        return HttpParameters(parameters)
    }
}
