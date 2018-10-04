//
//  SplitCacheProtocol.swift
//  Pods
//
//  Created by Brian Sztamfater on 2/10/17.
//
//

import Foundation

@objc public protocol SplitCacheProtocol {
    
    func addSplit(splitName: String, split: Split) -> Bool
    
    func removeSplit(splitName: String) -> Bool
    
    func setChangeNumber(_ changeNumber: Int64) -> Bool
    
    func getChangeNumber() -> Int64
    
    func getSplit(splitName: String) -> Split?

    func getAllSplits() -> [Split]

    func clear()
}
