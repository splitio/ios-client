//
//  HttpMySegmentsFetcher.swift
//  Split
//
//  Created by Javier Avrudsky on 02-Dic-2020
//
//

import Foundation

protocol HttpMySegmentsFetcher {
    func execute(userKey: String, headers: [String: String]?) throws -> [String]?
}

class DefaultHttpMySegmentsFetcher: HttpMySegmentsFetcher {

    private let restClient: RestClientMySegments
    private let syncHelper: SyncHelper
    private let resource = Resource.mySegments

    init(restClient: RestClientMySegments,
         syncHelper: SyncHelper) {
        self.restClient = restClient
        self.syncHelper = syncHelper
    }

    func execute(userKey: String, headers: [String: String]? = nil) throws -> [String]? {
        try syncHelper.checkEndpointReachability(restClient: restClient, resource: resource)
        Logger.d("Fetching segments")
        let semaphore = DispatchSemaphore(value: 0)
        var requestResult: DataResult<[String]>?
        let startTime = syncHelper.time()
        restClient.getMySegments(user: userKey, headers: headers) { result in
            requestResult = result
            semaphore.signal()
        }
        semaphore.wait()
        syncHelper.recordTelemetry(resource: resource, startTime: startTime)

        do {
            if let segments = try requestResult?.unwrap() {
                return segments
            }
        } catch {
            try syncHelper.throwIfError(syncHelper.handleError(error, resource: resource, startTime: startTime))
        }
        return nil
    }
}
