//
//  SplitCacheProtocol.swift
//  Pods
//
//  Created by Brian Sztamfater on 2/10/17.
//
//

import Foundation

protocol SplitCacheProtocol {
    func addSplit(splitName: String, split: Split)
    func setChangeNumber(_ changeNumber: Int64)
    func getChangeNumber() -> Int64
    func getSplit(splitName: String) -> Split?
    func getSplits() -> [String: Split]
    func getAllSplits() -> [Split]
    func exists(trafficType: String) -> Bool
    func clear()
    func getTimestamp() -> Int
    func setTimestamp(timestamp: Int)
}
