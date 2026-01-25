//
//  RestClient+Impressions.swift
//  Split
//
//  Created by Javier Avrudsky on 6/4/18.
//  Copyright © 2018 Split Software. All rights reserved.
//

import Foundation

protocol RestClientImpressions: RestClient {
    func sendImpressions(impressions: [ImpressionsTest], completion: @escaping (DataResult<EmptyValue>) -> Void)
}

extension DefaultRestClient: RestClientImpressions {
    func sendImpressions(impressions: [ImpressionsTest], completion: @escaping (DataResult<EmptyValue>) -> Void) {
        do {
            self.execute(
                    endpoint: endpointFactory.impressionsEndpoint,
                    body: try Json.encodeToJsonData(impressions),
                    completion: completion)
        } catch {
            Logger.e("Could not send impressions. Error: " + error.localizedDescription)
        }
    }
}
