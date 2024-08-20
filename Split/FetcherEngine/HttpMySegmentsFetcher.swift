//
//  HttpMySegmentsFetcher.swift
//  Split
//
//  Created by Javier Avrudsky on 02-Dic-2020
//
//

import Foundation

protocol HttpMySegmentsFetcher {
    func execute(userKey: String, headers: [String: String]?) throws -> AllSegmentsChange?
}

class DefaultHttpMySegmentsFetcher: HttpMySegmentsFetcher {
    private let syncHelper: SyncHelper
    private var resource: Resource = .allMySegments
    private let restClient: RestClientMySegments

    init(restClient: RestClientMySegments,
         syncHelper: SyncHelper) {

        self.restClient = restClient
        self.syncHelper = syncHelper
    }

    func execute(userKey: String, headers: [String: String]? = nil) throws -> AllSegmentsChange? {
        try syncHelper.checkEndpointReachability(restClient: restClient, resource: resource)
        Logger.d("Fetching segments from \(resource)")

        let startTime = syncHelper.time()
        let requestResult = fetch(userKey: userKey, headers: headers)
        syncHelper.recordTelemetry(resource: resource, startTime: startTime)

        do {
            if let change = try requestResult?.unwrap() {
                return change
            }
        } catch {
            try syncHelper.throwIfError(syncHelper.handleError(error, resource: resource, startTime: startTime))
        }
        return nil
    }

    func fetch(userKey: String, headers: [String: String]?) -> DataResult<AllSegmentsChange>? {
        let semaphore = DispatchSemaphore(value: 0)
        var requestResult: DataResult<AllSegmentsChange>?
        restClient.getMySegments(user: userKey, headers: headers) { result in
            requestResult = result
            semaphore.signal()
        }
        semaphore.wait()
        return requestResult
   }
}
