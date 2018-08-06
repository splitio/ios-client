//
//  SplitChange.swift
//  Pods
//
//  Created by Brian Sztamfater on 28/9/17.
//
//

import Foundation

@objc public class SplitChange: NSObject, Codable {
    var splits: [Split]?
    var since: Int64?
    var till: Int64?
}

extension SplitChange {
    override public var description: String {
        let since = self.since == nil ? "nil" : String(describing: self.since!)
        let till = self.till == nil ? "nil" : String(describing: self.till!)
        let splits = self.splits == nil ? "nil" : String(describing: self.splits!)
        return "{\nsince: \(since),\ntill: \(String(describing: till)),\nsplits: \(String(describing: splits))\n}"
    }
}
