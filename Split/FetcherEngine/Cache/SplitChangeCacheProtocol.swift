//
//  SplitChangeCacheProtocol.swift
//  Split
//
//  Created by Natalia  Stele on 06/12/2017.
//

import Foundation

public protocol SplitChangeCacheProtocol {

    func addChange(splitChange: SplitChange) -> Bool
    func getChanges(since: Int64) -> SplitChange?

}
