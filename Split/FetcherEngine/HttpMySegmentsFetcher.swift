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

/// Base clase to fetche segments
class HttpSegmentsFetcher: HttpMySegmentsFetcher {
    private let syncHelper: SyncHelper
    private var resource: Resource
    private let restClient: RestClientSegments

    init(restClient: RestClientSegments,
         syncHelper: SyncHelper,
         resource: Resource = .mySegments) {

        self.restClient = restClient
        self.syncHelper = syncHelper
        self.resource = resource
    }

    func execute(userKey: String, headers: [String: String]? = nil) throws -> SegmentChange? {
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

    func fetch(userKey: String, headers: [String: String]?) -> DataResult<SegmentChange>? {
        return nil
    }
}

class DefaultHttpMySegmentsFetcher: HttpSegmentsFetcher {

    private let syncHelper: SyncHelper
    private let resource: Resource = .mySegments
    private let restClient: RestClientSegments

    init(restClient: RestClientSegments,
         syncHelper: SyncHelper) {

        self.restClient = restClient
        self.syncHelper = syncHelper
        super.init(restClient: restClient, syncHelper: syncHelper, resource: .mySegments)
    }

    override func fetch(userKey: String, headers: [String: String]?) -> DataResult<SegmentChange>? {
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

class HttpMyLargeSegmentsFetcher: HttpSegmentsFetcher {

    private let syncHelper: SyncHelper
    private let resource: Resource = .myLargeSegments
    private let restClient: RestClientMyLargeSegments

    init(restClient: RestClientSegments,
         syncHelper: SyncHelper) {

        self.restClient = restClient
        self.syncHelper = syncHelper
        super.init(restClient: restClient, syncHelper: syncHelper, resource: resource)
    }

    override func fetch(userKey: String, headers: [String: String]?) -> DataResult<SegmentChange>? {
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
