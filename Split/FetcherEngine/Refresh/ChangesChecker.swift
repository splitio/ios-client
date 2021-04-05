//
//  ChangesChecker.swift
//  Split
//
//  Created by Javier Avrudsky on 23/03/2021.
//  Copyright © 2021 Split. All rights reserved.
//

import Foundation

protocol SplitsChangesChecker {
    func splitsHaveChanged(oldChangeNumber: Int64, newChangeNumber: Int64) -> Bool
}

protocol MySegmentsChangesChecker {
    func mySegmentsHaveChanged(old: [String], new: [String]) -> Bool
}

struct DefaultSplitsChangesChecker: SplitsChangesChecker {
    func splitsHaveChanged(oldChangeNumber: Int64, newChangeNumber: Int64) -> Bool {
        return oldChangeNumber < newChangeNumber
    }
}

struct DefaultMySegmentsChangesChecker: MySegmentsChangesChecker {
    func mySegmentsHaveChanged(old: [String], new: [String]) -> Bool {
        return !(old.count == new.count && old.sorted() == new.sorted())
    }
}
