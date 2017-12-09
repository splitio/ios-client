//
//  HttpSplitChangeFetcher.swift
//  Pods
//
//  Created by Brian Sztamfater on 19/9/17.
//
//

import Foundation
import Alamofire

@objc public final class HttpSplitChangeFetcher: NSObject, SplitChangeFetcher {
    
    private let restClient: RestClient
    private let storage: StorageProtocol
    private let splitChangeCache: SplitChangeCache?
    
    public init(restClient: RestClient, storage: StorageProtocol) {
        self.restClient = restClient
        self.storage = storage
        self.splitChangeCache = SplitChangeCache(storage: storage)
    }
    
    public func fetch(since: Int64) throws -> SplitChange {
        
        var reachable: Bool = true
        
        if let reachabilityManager = Alamofire.NetworkReachabilityManager(host: "www.apple.com") {
            
            if (!reachabilityManager.isReachable)  {
                reachable = false
            }
        }
        
        if !reachable {
            
            return (self.splitChangeCache?.getChanges(since: since))!
            
        } else {

            let semaphore = DispatchSemaphore(value: 0)
            var requestResult: DataResult<SplitChange>?
            restClient.getSplitChanges(since: since) { result in
                requestResult = result
                semaphore.signal()
            }
            semaphore.wait()
            let change = try requestResult!.unwrap()
            self.splitChangeCache?.addChange(splitChange: change)
            return change
            
        }
    }
}
