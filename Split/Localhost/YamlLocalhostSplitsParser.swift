//
//  YamlLocalhostSplitsParser.swift
//  Split
//
//  Created by Javier L. Avrudsky on 16/04/2019.
//  Copyright © 2019 Split. All rights reserved.
//

import Foundation

// swiftlint:disable cyclomatic_complexity
class YamlLocalhostSplitsParser: LocalhostSplitsParser {

    private let splitHelper = SplitHelper()
    private let kTreatmentField = "treatment"
    private let kConfigField = "config"
    private let kKeysField = "keys"

    func parseContent(_ content: String) -> LocalhostSplits {

        var loadedSplits = LocalhostSplits()
        var document: Yaml?
        do {
            document = try Yaml.load(content)
        } catch {
            Logger.e("Error parsing Yaml content: \(content)")
        }

        if let document = document, let values = document.array {
            for row in values {
                if let rowDic = row.dictionary {
                    let splitNameField = rowDic.keys[rowDic.keys.startIndex]
                    if let splitName = splitNameField.string {
                        var split: Split
                        if let existingSplit = loadedSplits[splitName] {
                            split = existingSplit
                        } else {
                            split = splitHelper.createDefaultSplit(named: splitName)
                        }

                        if let splitMap = rowDic[splitNameField]?.dictionary {
                            let treatment = splitMap[Yaml.string(kTreatmentField)]?.string ?? SplitConstants.control
                            if split.conditions == nil {
                                split.conditions = [Condition]()
                            }
                            if let keys = splitMap[Yaml.string(kKeysField)] {
                                if let keys = keys.array {
                                    for yamlKey in keys {
                                        if let key = yamlKey.string {
                                            split.conditions!.insert(
                                                splitHelper.createWhitelistCondition(key: key,
                                                                                     treatment: treatment), at: 0)
                                        }
                                    }
                                } else if let key = keys.string {
                                    split.conditions!.insert(
                                        splitHelper.createWhitelistCondition(key: key,
                                                                             treatment: treatment), at: 0)
                                }
                            } else {
                                split.conditions!.append(splitHelper.createRolloutCondition(treatment: treatment))
                            }
                            if let yamlConfig = splitMap[Yaml.string(kConfigField)], let config = yamlConfig.string {
                                if split.configurations == nil {
                                    split.configurations = [String: String]()
                                }
                                split.configurations![treatment] = config
                            }
                            loadedSplits[splitName] = split
                        }
                    }
                }
            }
        }
        return loadedSplits
    }
}
