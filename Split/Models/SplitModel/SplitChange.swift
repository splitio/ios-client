//
//  SplitChange.swift
//  Pods
//
//  Created by Brian Sztamfater on 28/9/17.
//
//

import Foundation

@objc public class SplitChange: NSObject, Codable, Validatable {
    
    typealias Entity = SplitChange
    
    var splits: [Split]?
    var since: Int64?
    var till: Int64?
    
    func isValid<V>(validator: V) -> Bool where V : Validator, SplitChange.Entity == V.Entity {
        return validator.isValidEntity(self)
    }
    
}

extension SplitChange {
    override public var description: String {
        let since = self.since == nil ? "nil" : String(describing: self.since!)
        let till = self.till == nil ? "nil" : String(describing: self.till!)
        let splits = self.splits == nil ? "nil" : String(describing: self.splits!)
        return "{\nsince: \(since),\ntill: \(String(describing: till)),\nsplits: \(String(describing: splits))\n}"
    }
}
