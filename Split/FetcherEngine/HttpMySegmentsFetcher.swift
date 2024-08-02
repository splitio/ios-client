//
//  HttpMySegmentsFetcher.swift
//  Split
//
//  Created by Javier Avrudsky on 02-Dic-2020
//
//

import Foundation

protocol HttpMySegmentsFetcher {
    func execute(userKey: String, headers: [String: String]?) throws -> SegmentChange?
}

class DefaultHttpMySegmentsFetcher: HttpMySegmentsFetcher {

    private let syncHelper: SyncHelper
    private let resource: Resource
    private let fetcher: SegmentFetcher
    private let restClient: RestClient

    init(restClient: RestClientMySegments,
         segmentsFetcher: SegmentFetcher,
         syncHelper: SyncHelper) {

        self.restClient = restClient
        self.fetcher = segmentsFetcher
        self.syncHelper = syncHelper
        self.resource = segmentsFetcher.resource
    }

    func execute(userKey: String, headers: [String: String]? = nil) throws -> SegmentChange? {
        try syncHelper.checkEndpointReachability(restClient: restClient, resource: resource)
        Logger.d("Fetching segments")

        let startTime = syncHelper.time()
        let requestResult = fetcher.fetch(userKey: userKey, headers: headers)
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
}

protocol SegmentFetcher {
    var resource: Resource { get }
    func fetch(userKey: String, headers: [String: String]?) -> DataResult<SegmentChange>?
}

struct MySegmentFetcher {
    let resource = Resource.mySegments
    private let restClient: RestClientMySegments
    private let semaphore = DispatchSemaphore(value: 0)

    func fetch(userKey: String, headers: [String: String]?) -> DataResult<SegmentChange>? {
        var requestResult: DataResult<SegmentChange>?
        restClient.getMySegments(user: userKey, headers: headers) { result in
            requestResult = result
            semaphore.signal()
        }
        semaphore.wait()
        return requestResult
    }
}

struct MyLargeSegmentFetcher {
    let resource = Resource.myLargeSegments
    private let restClient: RestClientMyLargeSegments
    private let semaphore = DispatchSemaphore(value: 0)

    func fetch(userKey: String, headers: [String: String]?) -> DataResult<SegmentChange>? {
        var requestResult: DataResult<SegmentChange>?
        restClient.getMyLargeSegments(user: userKey, headers: headers) { result in
            requestResult = result
            semaphore.signal()
        }
        semaphore.wait()
        return requestResult
    }
}
