//
//  HttpMySegmentsFetcher.swift
//  Pods
//
//  Created by Brian Sztamfater on 29/9/17.
//
//

import Foundation
import Alamofire

public final class HttpMySegmentsFetcher: NSObject, MySegmentsChangeFetcher {

    private let restClient: RestClient
    private let storage: StorageProtocol
    private let mySegmentCache: MySegmentsCacheProtocol?
    
    public init(restClient: RestClient, storage: StorageProtocol) {
        
        self.restClient = restClient
        self.storage = storage
        self.mySegmentCache = MySegmentsCache(storage: storage)
        
    }
    
    public func fetch(user: String) throws -> [String] {
        
        var reachable: Bool = true
        
        if let reachabilityManager = Alamofire.NetworkReachabilityManager(host: "www.apple.com") {
            
            if (!reachabilityManager.isReachable)  {
                reachable = false
            }
        }
        
        if !reachable {
            
            return (self.mySegmentCache?.getSegments())!
            
        } else {
            
            let semaphore = DispatchSemaphore(value: 0)
            var requestResult: DataResult<[String]>?
            restClient.getMySegments(user: user) { result in
                requestResult = result
                semaphore.signal()
            }
            semaphore.wait()
            
            let segments = try requestResult!.unwrap()
            mySegmentCache?.addSegments(segmentNames: segments)

            return segments
            
        }
        
    }

}
