//
//  RestClient+UniqueKeys.swift
//  Split
//
//  Created by Javier Avrudsky on 23-May-2022.
//  Copyright © 2022 Split Software. All rights reserved.
//

import Foundation

protocol RestClientUniqueKeys: RestClient {
    func send(uniqueKeys: UniqueKeys, completion: @escaping (DataResult<EmptyValue>) -> Void)
}

extension DefaultRestClient: RestClientUniqueKeys {
    func send(uniqueKeys: UniqueKeys, completion: @escaping (DataResult<EmptyValue>) -> Void) {
        do {
            self.execute(
                    endpoint: endpointFactory.uniqueKeysEndpoint,
                    body: try Json.encodeToJsonData(uniqueKeys),
                    completion: completion)
        } catch {
            Logger.e("Could not send impressions. Error: " + error.localizedDescription)
        }
    }
}
