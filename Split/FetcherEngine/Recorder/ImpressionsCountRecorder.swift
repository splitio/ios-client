//
//  HttpImpressionsCountRecorder.swift
//  Split
//
//  Created by Javier Avrudsky on 18/12/2020.
//  Copyright © 2020 Split. All rights reserved.
//

import Foundation

protocol HttpImpressionsCountRecorder {
    func execute(_ counts: ImpressionsCount) throws
}

class DefaultHttpImpressionsCountRecorder: HttpImpressionsCountRecorder {

    private let restClient: RestClientImpressionsCount

    init(restClient: RestClientImpressionsCount) {
        self.restClient = restClient
    }

    func execute(_ counts: ImpressionsCount) throws {

        if !restClient.isSdkServerAvailable() {
            Logger.d("Server is not reachable. Impressions count sending will be delayed when host is reachable")
            throw HttpError.serverUnavailable
        }

        let semaphore = DispatchSemaphore(value: 0)
        var httpError: HttpError?

        restClient.send(counts: counts, completion: { result in
            do {
                _ = try result.unwrap()
            } catch {
                Logger.e("Impression count error: \(String(describing: error))")
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
