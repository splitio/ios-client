//
//  HttpSplitChangeFetcher.swift
//  Pods
//
//  Created by Brian Sztamfater on 19/9/17.
//
//

import Foundation

@objc public final class HttpSplitFetcher: NSObject, SplitFetcher {
    
    private let restClient = RestClient()

    public override init() { }
    
    public func fetchAll(keys: [Key], attributes: [String : Any]?, handler: @escaping ([Treatment]) -> Void) {
        restClient.getTreatments(keys: keys, attributes: attributes) { result in
            if let treatments = try? result.unwrap() {
                handler(treatments)
            }
        }
    }
}
