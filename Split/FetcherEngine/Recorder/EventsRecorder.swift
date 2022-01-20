//
//  HttpEventsRecorder.swift
//  Split
//
//  Created by Javier Avrudsky on 18/12/2020.
//  Copyright © 2020 Split. All rights reserved.
//

import Foundation

protocol HttpEventsRecorder {
    func execute(_ items: [EventDTO]) throws
}

class DefaultHttpEventsRecorder: HttpEventsRecorder {

    private let restClient: RestClientTrackEvents
    private let syncHelper: SyncHelper
    private let resource = Resource.events

    init(restClient: RestClientTrackEvents,
         syncHelper: SyncHelper) {
        self.restClient = restClient
        self.syncHelper = syncHelper
    }

    func execute(_ items: [EventDTO]) throws {

        try syncHelper.checkEndpointReachability(restClient: restClient, resource: resource)

        let semaphore = DispatchSemaphore(value: 0)
        var httpError: HttpError?
        let startTime = syncHelper.time()
        restClient.sendTrackEvents(events: items, completion: { result in
            do {
                _ = try result.unwrap()
            } catch {
                httpError = self.syncHelper.handleError(error, resource: self.resource, startTime: startTime)
            }
            semaphore.signal()
        })
        semaphore.wait()
        try syncHelper.throwIfError(httpError)
        syncHelper.recordTelemetry(resource: resource, startTime: startTime)
    }
}
