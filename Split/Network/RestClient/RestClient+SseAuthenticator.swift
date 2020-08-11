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
    let token: String
}

protocol RestClientSseAuthenticator: RestClient {
    func authenticate(userKey: String, completion: @escaping (DataResult<SseAuthenticationResponse>) -> Void)
}

extension DefaultRestClient: RestClientSseAuthenticator {
    var kUserKeyParameter: String { "users" }
    func authenticate(userKey: String, completion: @escaping (DataResult<SseAuthenticationResponse>) -> Void) {
        self.execute(
            endpoint: endpointFactory.splitChangesEndpoint,
            parameters: [kUserKeyParameter: userKey],
            completion: completion)
    }
}
