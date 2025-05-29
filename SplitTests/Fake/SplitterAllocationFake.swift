//
//  SplitterAllocationFake.swift
//  SplitTests
//
//  Created by Javier L. Avrudsky on 17/12/2018.
//  Copyright © 2018 Split. All rights reserved.
//

import Foundation
@testable import Split

class SplitterAllocationFake: SplitterProtocol {
    func getTreatment(
        key: Key,
        seed: Int,
        attributes: [String: Any]?,
        partions: [Partition]?,
        algo: Algorithm) -> String {
        return Splitter.shared.getTreatment(
            key: key,
            seed: seed,
            attributes: attributes,
            partions: partions,
            algo: algo)
    }

    func getBucket(seed: Int, key: String, algo: Algorithm) -> Int64 {
        return 1
    }
}
