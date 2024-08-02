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
    private let fetcher: SegmentsFetcher
    private let restClient: RestClient

    init(restClient: RestClientMySegments,
         segmentsFetcher: SegmentsFetcher,
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

protocol SegmentsFetcher {
    var resource: Resource { get }
    func fetch(userKey: String, headers: [String: String]?) -> DataResult<SegmentChange>?
}

struct MySegmentsFetcher: SegmentsFetcher {
    let resource = Resource.mySegments
    private let restClient: RestClientMySegments

    init(restClient: RestClientMySegments) {
        self.restClient = restClient
    }

    func fetch(userKey: String, headers: [String: String]?) -> DataResult<SegmentChange>? {
        var requestResult: DataResult<SegmentChange>?
        let semaphore = DispatchSemaphore(value: 0)

        restClient.getMySegments(user: userKey, headers: headers) { result in
            requestResult = result
            semaphore.signal()
        }
        semaphore.wait()
        return requestResult
    }
}

struct MyLargeSegmentsFetcher: SegmentsFetcher {
    let resource = Resource.myLargeSegments
    private let restClient: RestClientMyLargeSegments

    init(restClient: RestClientMyLargeSegments) {
        self.restClient = restClient
    }

    func fetch(userKey: String, headers: [String: String]?) -> DataResult<SegmentChange>? {
        let semaphore = DispatchSemaphore(value: 0)
        var requestResult: DataResult<SegmentChange>?
        restClient.getMyLargeSegments(user: userKey, headers: headers) { result in
            requestResult = result
            semaphore.signal()
        }
        semaphore.wait()
        return requestResult
    }
}
