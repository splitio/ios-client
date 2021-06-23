//
//  PersistentImpressionsCountStorage.swift
//  Split
//
//  Created by Javier L. Avrudsky on 12/11/2021.
//  Copyright © 2021 Split. All rights reserved.
//

import Foundation

protocol PersistentImpressionsCountStorage {
    func delete(_ counts: [ImpressionsCountPerFeature])
    func pop(count: Int) -> [ImpressionsCountPerFeature]
    func push(counts: ImpressionsCountPerFeature)
    func setActive(_ counts: [ImpressionsCountPerFeature])
}
