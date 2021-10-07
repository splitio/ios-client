//
//  UInt64+bits.swift
//  Split
//
//  Created by Javier Avrudsky on 27-Aug-2021.
//  Copyright © 2021 Split. All rights reserved.
//

import Foundation
// swiftlint:disable identifier_name
extension UInt64 {
    private static let kSize: UInt64 = 64
    func rotateLeft(_ pos: UInt64) -> UInt64 {
        let move = pos % UInt64.kSize
        let n1 = self << move
        let n2 = self >> (UInt64.kSize - move)
        return n1 | n2
    }

    func rotateRight(_ pos: UInt64) -> UInt64 {
        let move = pos % UInt64.kSize
        let n1 = self << (UInt64.kSize - move)
        let n2 = self >> move
        return n1 | n2
    }
}
