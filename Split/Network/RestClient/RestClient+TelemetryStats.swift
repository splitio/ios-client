//
//  RestClient+TelemetryStats.swift
//  Split
//
//  Created by Javier Avrudsky on 9-Dec-2021
//  Copyright © 2021 Split Software. All rights reserved.
//

import Foundation

protocol RestClientTelemetryStats: RestClient {
    func send(stats: TelemetryStats, completion: @Sendable @escaping (DataResult<EmptyValue>) -> Void)
}

extension DefaultRestClient: RestClientTelemetryStats {
    func send(stats: TelemetryStats, completion: @Sendable @escaping (DataResult<EmptyValue>) -> Void) {
        do {
            self.execute(
                    endpoint: endpointFactory.telemetryUsageEndpoint,
                    body: try Json.encodeToJsonData(stats),
                    completion: completion)
        } catch {
            Logger.e("Could not send time metrics. Error: " + error.localizedDescription)
        }
    }
}
