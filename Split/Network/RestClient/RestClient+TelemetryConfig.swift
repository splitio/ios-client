//
//  RestClient+TelemetryConfig.swift
//  Split
//
//  Created by Javier Avrudsky on 7-Dec-2021
//  Copyright © 2021 Split Software. All rights reserved.
//

import Foundation
import Logging

protocol RestClientTelemetryConfig: RestClient {
    func send(config: TelemetryConfig, completion: @escaping (DataResult<EmptyValue>) -> Void)
}

extension DefaultRestClient: RestClientTelemetryConfig {
    func send(config: TelemetryConfig, completion: @escaping (DataResult<EmptyValue>) -> Void) {
        do {
            self.execute(
                    endpoint: endpointFactory.telemetryConfigEndpoint,
                    body: try Json.encodeToJsonData(config),
                    completion: completion)
        } catch {
            Logger.e("Could not send time metrics. Error: " + error.localizedDescription)
        }
    }
}
