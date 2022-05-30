//
//  HttpUniqueKeysRecorder.swift
//  Split
//
//  Created by Javier Avrudsky on 23-May-2022.
//  Copyright © 2022 Split. All rights reserved.
//

import Foundation

protocol HttpUniqueKeysRecorder {
    func execute(_ uniqueKeys: UniqueKeys) throws
}

class DefaultHttpUniqueKeysRecorder: HttpUniqueKeysRecorder {

    private let restClient: RestClientUniqueKeys
    private let syncHelper: SyncHelper
    private let resource = Resource.uniqueKeys

    init(restClient: RestClientUniqueKeys,
         syncHelper: SyncHelper) {
        self.restClient = restClient
        self.syncHelper = syncHelper
    }

    func execute(_ uniqueKeys: UniqueKeys) throws {

        try syncHelper.checkEndpointReachability(restClient: restClient, resource: resource)

        let semaphore = DispatchSemaphore(value: 0)
        var httpError: HttpError?
        restClient.send(uniqueKeys: uniqueKeys, completion: { result in
            do {
                _ = try result.unwrap()
            } catch {
                httpError = HttpError.unknown(code: -1, message: error.localizedDescription)
            }
            semaphore.signal()
        })
        semaphore.wait()

        try syncHelper.throwIfError(httpError)

    }
}
