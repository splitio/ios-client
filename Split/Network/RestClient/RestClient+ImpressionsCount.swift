//
//  RestClient+ImpressionsCount.swift
//  Split
//
//  Created by Javier Avrudsky on 6/23/21.
//  Copyright © 2021 Split Software. All rights reserved.
//

import Foundation

protocol RestClientImpressionsCount: RestClient {
    func send(counts: ImpressionsCount, completion: @escaping (DataResult<EmptyValue>) -> Void)
}

extension DefaultRestClient: RestClientImpressionsCount {
    func send(counts: ImpressionsCount, completion: @escaping (DataResult<EmptyValue>) -> Void) {
        do {
            self.execute(
                    endpoint: endpointFactory.impressionsCountEndpoint,
                    body: try Json.encodeToJsonData(counts),
                    completion: completion)
        } catch {
            Logger.e("Could not send impressions counts. Error: " + error.localizedDescription)
        }
    }
}
