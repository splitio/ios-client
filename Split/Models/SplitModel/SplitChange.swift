//
//  SplitChange.swift
//  Split
//
//  Created by Brian Sztamfater on 28/9/17.
//
//

import Foundation

@objc class SplitChange: NSObject, Codable {
    var splits: [Split]
    var since: Int64
    var till: Int64

    init(splits: [Split], since: Int64, till: Int64) {
        self.splits = splits
        self.since = since
        self.till = till
    }
}

extension SplitChange {
    override public var description: String {
        let since = String(describing: self.since)
        let till = String(describing: self.till)
        let splits = String(describing: self.splits)
        return "{\nsince: \(since),\ntill: \(String(describing: till)),\nsplits: \(String(describing: splits))\n}"
    }
}
