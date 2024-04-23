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

    static let unsupportedMatcherSplitJson: String = """
      {
          "changeNumber": 1709843458770,
          "trafficTypeName": "user",
          "name": "feature_flag_for_test",
          "trafficAllocation": 100,
          "trafficAllocationSeed": -1364119282,
          "seed": -605938843,
          "status": "ACTIVE",
          "killed": false,
          "defaultTreatment": "off",
          "algo": 2,
          "conditions": [
              {
                  "conditionType": "ROLLOUT",
                  "matcherGroup": {
                      "combiner": "AND",
                      "matchers": [
                          {
                              "keySelector": {
                                  "trafficType": "user",
                                  "attribute": null
                              },
                              "matcherType": "WRONG_MATCHER_TYPE",
                              "negate": false,
                              "userDefinedSegmentMatcherData": null,
                              "whitelistMatcherData": null,
                              "unaryNumericMatcherData": null,
                              "betweenMatcherData": null,
                              "dependencyMatcherData": null,
                              "booleanMatcherData": null,
                              "stringMatcherData": "123123"
                          }
                      ]
                  },
                  "partitions": [
                      {
                          "treatment": "on",
                          "size": 0
                      },
                      {
                          "treatment": "off",
                          "size": 100
                      }
                  ],
                  "label": "wrong matcher type"
              },
              {
                  "conditionType": "ROLLOUT",
                  "matcherGroup": {
                      "combiner": "AND",
                      "matchers": [
                          {
                              "keySelector": {
                                  "trafficType": "user",
                                  "attribute": "sem"
                              },
                              "matcherType": "MATCHES_STRING",
                              "negate": false,
                              "userDefinedSegmentMatcherData": null,
                              "whitelistMatcherData": null,
                              "unaryNumericMatcherData": null,
                              "betweenMatcherData": null,
                              "dependencyMatcherData": null,
                              "booleanMatcherData": null,
                              "stringMatcherData": "1.2.3"
                          }
                      ]
                  },
                  "partitions": [
                      {
                          "treatment": "on",
                          "size": 100
                      },
                      {
                          "treatment": "off",
                          "size": 0
                      }
                  ],
                  "label": "sem matches 1.2.3"
              }
          ],
          "configurations": {},
          "sets": []
      }
    """

    static func createSplits(namePrefix: String, count: Int) -> [Split] {
        var splits = [Split]()
        for i in 0..<count {
            let split = Split(name: "\(namePrefix)\(i)", trafficType: "tt_\(i)", status: .active, sets: nil, json: "")
            split.isParsed = true
            splits.append(split)
        }
        return splits
    }

    static func newSplit(name: String, trafficType: String) -> Split {
        let split = Split(name: name, trafficType: trafficType, status: .active, sets: nil, json: "")
        split.isParsed = true
        return split
    }
}
