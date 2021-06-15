//
//  YamlLocalhostSplitsParser.swift
//  Split
//
//  Created by Javier L. Avrudsky on 16/04/2019.
//  Copyright © 2019 Split. All rights reserved.
//

import Foundation

class YamlLocalhostSplitsParser: LocalhostSplitsParser {

    private let splitHelper = SplitHelper()
    private let kTreatmentField = "treatment"
    private let kConfigField = "config"
    private let kKeysField = "keys"

    func parseContent(_ content: String) -> LocalhostSplits {

        var loadedSplits = LocalhostSplits()

        let splittedYaml = splitYamlBySplitContent(content: content)
        for splitRow in splittedYaml {
            var document: Yaml?
            do {
                document = try Yaml.load(splitRow)
            } catch {
                Logger.e("Error parsing Yaml content row: \(splitRow) \n \(error)")
                continue
            }

            if let document = document,
               let values = document.array,
               values.count > 0,
               let split = parseSplit(row: values[0], splits: loadedSplits),
               let splitName = split.name {
                loadedSplits[splitName] = split
            }
        }
        return loadedSplits
    }

    func parseSplit(row: Yaml, splits: LocalhostSplits) -> Split? {
        if let rowDic = row.dictionary {
            let splitNameField = rowDic.keys[rowDic.keys.startIndex]
            if let splitName = splitNameField.string {
                var split: Split
                if let existingSplit = splits[splitName] {
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
                            split.conditions?.insert(
                                splitHelper.createWhitelistCondition(keys: keys.compactMap { $0.string },
                                                                     treatment: treatment), at: 0)

                        } else if let key = keys.string {
                            split.conditions?.insert(
                                splitHelper.createWhitelistCondition(keys: [key],
                                                                     treatment: treatment), at: 0)
                        }
                    } else {
                        split.conditions?.append(splitHelper.createRolloutCondition(treatment: treatment))
                    }
                    if let yamlConfig = splitMap[Yaml.string(kConfigField)],
                       let config = yamlConfig.string {
                        if split.configurations == nil {
                            split.configurations = [String: String]()
                        }
                        split.configurations?[treatment] = config
                    }
                    return split
                }
            }
        }
        return nil
    }

    //
    // Splits Yaml by Split to avoid an issue with the library
    // when processing large files.
    // This way the library only parses one Split at a time
    private func splitYamlBySplitContent(content: String) -> [String] {
        let newLineChar: Character = "\n"
        let newSplitChar = "-"
        var splitsYaml = [String]()
        let rows = content.split(separator: newLineChar)
        var currentSplit = ""
        for row in rows {
            let line = row.trimmingCharacters(in: .newlines)
            if !line.isEmpty() {
                if line.hasPrefix(newSplitChar) { // New split found
                    if !currentSplit.isEmpty() {
                        splitsYaml.append(currentSplit)
                    }
                    currentSplit = String(line)
                } else {
                    currentSplit+=line
                }
                currentSplit.append(newLineChar)
            }
        }
        if !currentSplit.isEmpty() {
            splitsYaml.append(currentSplit)
        }
        return splitsYaml
    }
}
