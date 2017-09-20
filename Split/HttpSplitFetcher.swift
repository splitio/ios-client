//
//  HttpSplitChangeFetcher.swift
//  Pods
//
//  Created by Brian Sztamfater on 19/9/17.
//
//

import Foundation

@objc public class HttpSplitFetcher: NSObject, SplitFetcher {
    
    private let restClient = RestClient()

    public override init() { }
    
    func fetchAll() -> Void {
        
    }
    
    /**
     * Forces a sync of splits, outside of any scheduled
     * syncs. This method MUST NOT throw any exceptions.
     */
    public func forceRefresh() -> Void {
        // TODO: Send real parameters. We need to define where to set and store them to make the interval fetching
        restClient.getTreatments(keys: [Key(matchingKey: "test", trafficType: "user")], attributes: ["key": "value", "key2": 23]) { result in
            if let treatments = try? result.unwrap() {
                // TODO: Persist on local storage
            }
        }
    }

}
