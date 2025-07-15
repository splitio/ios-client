//
//  SplitHelper.swift
//  Split
//
//  Created by Javier L. Avrudsky on 17/12/2018.
//  Copyright © 2018 Split. All rights reserved.
//

import Foundation
@testable import Split

class SplitTestHelper {

    func loadSplitFromFile(name: String) -> Split? {
        var split: Split?
        do {
            split = try JSON.decodeFrom(json: FileHelper.readDataFromFile(sourceClass: self, name: name, type: "json")!, to: Split.self)
        } catch {
            print("Error loading split from file \(name)")
        }
        return split
    }


    static var jsonSplitExample: String {
        return """
              {
              "trafficTypeName":"account",
              "name":"FACUNDO_TEST",
              "trafficAllocation":59,
              "trafficAllocationSeed":-2108186082,
              "seed":-1947050785,
              "status":"ACTIVE",
              "killed":false,
              "defaultTreatment":"off",
              "changeNumber":1506703262916,
              "algo":2,
              "conditions":[
                            {
                            "conditionType":"WHITELIST",
                            "matcherGroup":{
                            "combiner":"AND",
                            "matchers":[
                                        {
                                        "keySelector":null,
                                        "matcherType":"WHITELIST",
                                        "negate":false,
                                        "userDefinedSegmentMatcherData":null,
                                        "whitelistMatcherData":{
                                        "whitelist":[
                                                     "nico_test",
                                                     "othertest"
                                                     ]
                                        },
                                        "unaryNumericMatcherData":null,
                                        "betweenMatcherData":null,
                                        "booleanMatcherData":null,
                                        "dependencyMatcherData":null,
                                        "stringMatcherData":null
                                        }
                                        ]
                            },
                            "partitions":[
                                          {
                                          "treatment":"on",
                                          "size":100
                                          }
                                          ],
                            "label":"whitelisted"
                            },
                            {
                            "conditionType":"WHITELIST",
                            "matcherGroup":{
                            "combiner":"AND",
                            "matchers":[
                                        {
                                        "keySelector":null,
                                        "matcherType":"WHITELIST",
                                        "negate":false,
                                        "userDefinedSegmentMatcherData":null,
                                        "whitelistMatcherData":{
                                        "whitelist":[
                                                     "bla"
                                                     ]
                                        },
                                        "unaryNumericMatcherData":null,
                                        "betweenMatcherData":null,
                                        "booleanMatcherData":null,
                                        "dependencyMatcherData":null,
                                        "stringMatcherData":null
                                        }
                                        ]
                            },
                            "partitions":[
                                          {
                                          "treatment":"off",
                                          "size":100
                                          }
                                          ],
                            "label":"whitelisted"
                            },
                            {
                            "conditionType":"ROLLOUT",
                            "matcherGroup":{
                            "combiner":"AND",
                            "matchers":[
                                        {
                                        "keySelector":{
                                        "trafficType":"account",
                                        "attribute":null
                                        },
                                        "matcherType":"ALL_KEYS",
                                        "negate":false,
                                        "userDefinedSegmentMatcherData":null,
                                        "whitelistMatcherData":null,
                                        "unaryNumericMatcherData":null,
                                        "betweenMatcherData":null,
                                        "booleanMatcherData":null,
                                        "dependencyMatcherData":null,
                                        "stringMatcherData":null
                                        }
                                        ]
                            },
                            "partitions":[
                                          {
                                          "treatment":"on",
                                          "size":0
                                          },
                                          {
                                          "treatment":"off",
                                          "size":100
                                          },
                                          {
                                          "treatment":"visa",
                                          "size":0
                                          }
                                          ],
                            "label":"in segment all"
                            }
                            ]
              }
"""
    }

    static func getUnsupportedMatcherSplitJson(sourceClass: Any) -> String? {
        return FileHelper.readDataFromFile(sourceClass: sourceClass, name: "split_unsupported_matcher", type: "json")
    }

    static func createSplits(namePrefix: String, count: Int) -> [Split] {
        var splits = [Split]()
        for i in 0..<count {
            let split = Split(name: "\(namePrefix)\(i)", trafficType: "tt_\(i)", status: .active, sets: nil, json: "")
            split.isCompletelyParsed = true
            splits.append(split)
        }
        return splits
    }

    static func createHashedImpressions(start: Int = 1, count: Int = 10, expired: Bool = false) -> [HashedImpression] {
        var items = [HashedImpression]()
        for i in start..<(start + count) {
            let item = HashedImpression(impressionHash: UInt32(i),
                                        time: Date.nowMillis(),
                                        createdAt: (expired ? 1 : Date.nowMillis()))
            items.append(item)
        }
        return items
    }

    static func createHashedImpressionsDic(start: Int = 1, count: Int = 10, expired: Bool = false) -> [UInt32: HashedImpression] {
        let items = createHashedImpressions(start: start, count: count, expired: expired)
        var dic = [UInt32: HashedImpression]()
        for item in items {
            dic[item.impressionHash] = item
        }
        return dic
    }

    static func newSplit(name: String, trafficType: String) -> Split {
        
        let splitJSONExample = """
              {
              "trafficTypeName":"\(trafficType)",
              "name": "\(name)\",
              "trafficAllocation":59,
              "trafficAllocationSeed":-2108186082,
              "seed":-1947050785,
              "status":"ACTIVE",
              "killed":false,
              "defaultTreatment":"off",
              "changeNumber":1506703262916,
              "algo":2,
              "conditions":[
                            {
                            "conditionType":"WHITELIST",
                            "matcherGroup":{
                            "combiner":"AND",
                            "matchers":[
                                        {
                                        "keySelector":null,
                                        "matcherType":"WHITELIST",
                                        "negate":false,
                                        "userDefinedSegmentMatcherData":null,
                                        "whitelistMatcherData":{
                                        "whitelist":[
                                                     "nico_test",
                                                     "othertest"
                                                     ]
                                        },
                                        "unaryNumericMatcherData":null,
                                        "betweenMatcherData":null,
                                        "booleanMatcherData":null,
                                        "dependencyMatcherData":null,
                                        "stringMatcherData":null
                                        }
                                        ]
                            },
                            "partitions":[
                                          {
                                          "treatment":"on",
                                          "size":100
                                          }
                                          ],
                            "label":"whitelisted"
                            },
                            {
                            "conditionType":"WHITELIST",
                            "matcherGroup":{
                            "combiner":"AND",
                            "matchers":[
                                        {
                                        "keySelector":null,
                                        "matcherType":"WHITELIST",
                                        "negate":false,
                                        "userDefinedSegmentMatcherData":null,
                                        "whitelistMatcherData":{
                                        "whitelist":[
                                                     "bla"
                                                     ]
                                        },
                                        "unaryNumericMatcherData":null,
                                        "betweenMatcherData":null,
                                        "booleanMatcherData":null,
                                        "dependencyMatcherData":null,
                                        "stringMatcherData":null
                                        }
                                        ]
                            },
                            "partitions":[
                                          {
                                          "treatment":"off",
                                          "size":100
                                          }
                                          ],
                            "label":"whitelisted"
                            },
                            {
                            "conditionType":"ROLLOUT",
                            "matcherGroup":{
                            "combiner":"AND",
                            "matchers":[
                                        {
                                        "keySelector":{
                                        "trafficType":"account",
                                        "attribute":null
                                        },
                                        "matcherType":"ALL_KEYS",
                                        "negate":false,
                                        "userDefinedSegmentMatcherData":null,
                                        "whitelistMatcherData":null,
                                        "unaryNumericMatcherData":null,
                                        "betweenMatcherData":null,
                                        "booleanMatcherData":null,
                                        "dependencyMatcherData":null,
                                        "stringMatcherData":null
                                        }
                                        ]
                            },
                            "partitions":[
                                          {
                                          "treatment":"on",
                                          "size":0
                                          },
                                          {
                                          "treatment":"off",
                                          "size":100
                                          },
                                          {
                                          "treatment":"visa",
                                          "size":0
                                          }
                                          ],
                            "label":"in segment all"
                            }
                            ]
              }
            """
        
        let split = Split(name: name, trafficType: trafficType, status: .active, sets: nil, json: splitJSONExample)
        split.isCompletelyParsed = false
        return split
    }
    
    static func newSplitWithMatcherType(_ matcher: MatcherType) -> Split {
        let split = Split(name: "SPLIT_WITH_MATCHERTYPE", trafficType: "User", status: .active, sets: nil, json: "")
        split.isCompletelyParsed = true
        split.conditions = [Condition()]
        split.conditions?[0].matcherGroup = MatcherGroup()
        split.conditions?[0].matcherGroup!.matchers = [Matcher()]
        split.conditions?[0].matcherGroup!.matchers![0].matcherType = matcher
        return split
    }
}
