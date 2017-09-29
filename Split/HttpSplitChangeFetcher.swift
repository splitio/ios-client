//
//  HttpSplitChangeFetcher.swift
//  Pods
//
//  Created by Brian Sztamfater on 19/9/17.
//
//

import Foundation

@objc public final class HttpSplitChangeFetcher: NSObject, SplitChangeFetcher {
    
    private let restClient: RestClient

    public init(restClient: RestClient) {
        self.restClient = restClient
    }
    
    public func fetch(since: Int64) throws -> SplitChange {
        let semaphore = DispatchSemaphore(value: 0)
        var requestResult: DataResult<SplitChange>?
        restClient.getSplitChanges(since: since) { result in
            requestResult = result
            semaphore.signal()
        }
        semaphore.wait()
        return try requestResult!.unwrap()
    }
}
