//
//  HttpImpressionsRecorder.swift
//  Split
//
//  Created by Javier Avrudsky on 18/12/2020.
//  Copyright © 2020 Split. All rights reserved.
//

import Foundation

protocol HttpImpressionsRecorder {
    func execute(_ items: [ImpressionsTest]) throws
}

class DefaultHttpImpressionsRecorder: HttpImpressionsRecorder {

    private let restClient: RestClientImpressions

    init(restClient: RestClientImpressions) {
        self.restClient = restClient
    }

    func execute(_ items: [ImpressionsTest]) throws {

        if !restClient.isSdkServerAvailable() {
            Logger.d("Server is not reachable. Impressions sending will be delayed when host is reachable")
            throw HttpError.serverUnavailable
        }

        let semaphore = DispatchSemaphore(value: 0)
        var httpError: HttpError?

        restClient.sendImpressions(impressions: items, completion: { result in
            do {
                _ = try result.unwrap()
                Logger.d("Impression posted successfully")
            } catch {
                Logger.e("Impression error: \(String(describing: error))")
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
