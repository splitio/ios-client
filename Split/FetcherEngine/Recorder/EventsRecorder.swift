//
//  HttpRecorder.swift
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

    init(restClient: RestClientTrackEvents) {
        self.restClient = restClient
    }

    func execute(_ items: [EventDTO]) throws {

        if !restClient.isSdkServerAvailable() {
            Logger.d("Server is not reachable. Events sending will be delayed when host is reachable")
            throw HttpError.serverUnavailable
        }

        let semaphore = DispatchSemaphore(value: 0)
        var httpError: HttpError?

        restClient.sendTrackEvents(events: items, completion: { result in
            do {
                _ = try result.unwrap()
                Logger.d("Event posted successfully")
            } catch {
                Logger.e("Event error: \(String(describing: error))")
                httpError = HttpError.unknown(message: error.localizedDescription)
            }
            semaphore.signal()
        })
        semaphore.wait()

        if let error = httpError {
            throw error
        }
    }
}
