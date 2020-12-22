//
//  SplitChangeCacheProtocol.swift
//  Split
//
//  Created by Natalia  Stele on 06/12/2017.
//

import Foundation

@available(*, deprecated, message: "To be removed in integration PR")
protocol SplitChangeCacheProtocol {

    func addChange(splitChange: SplitChange) -> Bool
    func getChanges(since: Int64) -> SplitChange?

}
