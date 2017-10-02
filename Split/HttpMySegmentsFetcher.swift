//
//  HttpMySegmentsFetcher.swift
//  Pods
//
//  Created by Brian Sztamfater on 29/9/17.
//
//

import Foundation

@objc public final class HttpMySegmentsFetcher: NSObject, MySegmentsFetcher {

    private let restClient: RestClient
    
    public init(restClient: RestClient) {
        self.restClient = restClient
    }
    
    public func fetch(user: String) throws -> [String] {
        let semaphore = DispatchSemaphore(value: 0)
        var requestResult: DataResult<[String]>?
        restClient.getMySegments(user: user) { result in
            requestResult = result
            semaphore.signal()
        }
        semaphore.wait()
        return try requestResult!.unwrap()
    }

}
