//
//  SplitCacheProtocol.swift
//  Pods
//
//  Created by Brian Sztamfater on 2/10/17.
//
//

import Foundation

protocol SplitCacheProtocol {
    
    var onSplitsUpdatedHandler: (([Split])->Void)? { get set }
    
    func addSplit(splitName: String, split: Split)
    
    func removeSplit(splitName: String)
    
    func setChangeNumber(_ changeNumber: Int64)
    
    func getChangeNumber() -> Int64
    
    func getSplit(splitName: String) -> Split?

    func getSplits() -> [String: Split]
    
    func getAllSplits() -> [Split]

    func clear()
}
