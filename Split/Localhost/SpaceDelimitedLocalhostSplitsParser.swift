//
//  SpaceSeparatedLocalhostSplitsParser.swift
//  Split
//
//  Created by Javier L. Avrudsky on 31/01/2019.
//  Copyright © 2019 Split. All rights reserved.
//

import Foundation

class SpaceDelimitedLocalhostSplitsParser: LocalhostSplitsParser {

    let splitHelper = SplitHelper()

    func parseContent(_ content: String) -> LocalhostSplits {

        var loadedSplits = LocalhostSplits()

        let rows = content.split(separator: "\n")

        for row in rows {
            let line = row.trimmingCharacters(in: .whitespacesAndNewlines)
            if line.count > 0, !line.hasSuffix("#") {
                let splits = line.split(separator: " ")
                if splits.count == 2, !splits[0].isEmpty, !splits[1].isEmpty {
                    let splitName = splits[0].trimmingCharacters(in: .whitespacesAndNewlines)
                    let treatment = splits[1].trimmingCharacters(in: .whitespacesAndNewlines)
                    let split = splitHelper.createDefaultSplit(named: splitName)
                    split.conditions = [splitHelper.createRolloutCondition(treatment: treatment)]
                    loadedSplits[splitName] = split
                }
            }
        }
        return loadedSplits
    }

}
