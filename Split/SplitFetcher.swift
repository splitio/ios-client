//
//  SplitChangeFetcher.swift
//  Pods
//
//  Created by Brian Sztamfater on 19/9/17.
//
//

import Foundation

@objc public protocol SplitFetcher {
    
    func fetchAll(keys: [Key], attributes: [String : Any]?, handler: @escaping ([Treatment]) -> Void)
}
