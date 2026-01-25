//
//  RestClient+TrackEvents.swift
//  Split
//
//  Created by Javier Avrudsky on 6/4/18.
//  Copyright © 2018 Split Software. All rights reserved.
//

import Foundation

protocol RestClientTrackEvents: RestClient {
    func sendTrackEvents(events: [EventDTO], completion: @escaping (DataResult<EmptyValue>) -> Void)
}

extension DefaultRestClient: RestClientTrackEvents {
    func sendTrackEvents(events: [EventDTO], completion: @escaping (DataResult<EmptyValue>) -> Void) {
        do {
            self.execute(
                    endpoint: endpointFactory.eventsEndpoint,
                    body: try Json.dynamicEncodeToJsonData(events),
                    completion: completion)
        } catch {
            Logger.e("Could not send time metrics. Error: " + error.localizedDescription)
        }
    }
}
