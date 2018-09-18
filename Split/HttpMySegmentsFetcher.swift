//
//  HttpMySegmentsFetcher.swift
//  Pods
//
//  Created by Brian Sztamfater on 29/9/17.
//
//

import Foundation

public final class HttpMySegmentsFetcher: NSObject, MySegmentsChangeFetcher {
    
    private let restClient: RestClient
    private let storage: StorageProtocol
    private let mySegmentCache: MySegmentsCacheProtocol?
    
    public init(restClient: RestClient, storage: StorageProtocol) {
        
        self.restClient = restClient
        self.storage = storage
        self.mySegmentCache = MySegmentsCache(storage: storage)
    }
    
    public func fetch(user: String, policy: FecthingPolicy) throws -> [String]? {
        
        if policy == .cacheOnly || !self.restClient.isSdkServerAvailable() {
            return self.mySegmentCache?.getSegments(key: user)
        } else {
            let semaphore = DispatchSemaphore(value: 0)
            var requestResult: DataResult<[String]>?
            restClient.getMySegments(user: user) { result in
                requestResult = result
                semaphore.signal()
            }
            semaphore.wait()
            guard let segments = try requestResult?.unwrap() else {
                return nil
            }
            mySegmentCache?.addSegments(segmentNames: segments, key: user)
            return segments
        }
    }
}
