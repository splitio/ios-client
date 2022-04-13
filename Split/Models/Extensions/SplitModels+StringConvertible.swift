//
//  SplitModels+StringConvertible.swift
//  Split
//
//  Created by Javier Avrudsky on 8/6/18.
//
//
// Generated using Sourcery 0.11.0 — https://github.com/krzysztofzablocki/Sourcery
// DO NOT EDIT

// swiftlint:disable inclusive_language
extension BetweenMatcherData {
  override public var debugDescription: String {
    var output: String = "BetweenMatcherData {\n"
    if let dataType = dataType {
      output+="dataType = \(String(reflecting: dataType)) \n"
    } else {
      output+="dataType = nil\n"
    }
    if let start = start {
      output+="start = \(start) \n"
    } else {
      output+="start = nil\n"
    }
    if let end = end {
      output+="end = \(end) \n"
    } else {
      output+="end = nil\n"
    }
    output+="description = \(description) \n"
    output+="}"
    return output
  }
}

extension Condition {
  override public var debugDescription: String {
    var output: String = "Condition {\n"
    if let conditionType = conditionType {
      output+="conditionType = \(String(reflecting: conditionType)) \n"
    } else {
      output+="conditionType = nil\n"
    }
    if let matcherGroup = matcherGroup {
      output+="matcherGroup = \(String(reflecting: matcherGroup)) \n"
    } else {
      output+="matcherGroup = nil\n"
    }
    if let partitions = partitions {
      output+="partitions = \(partitions) \n"
    } else {
      output+="partitions = nil\n"
    }
    if let label = label {
      output+="label = \(label) \n"
    } else {
      output+="label = nil\n"
    }
    output+="}"
    return output
  }
}

extension DependencyMatcherData {
  override public var debugDescription: String {
    var output: String = "DependencyMatcherData {\n"
    if let split = split {
      output+="split = \(split) \n"
    } else {
      output+="split = nil\n"
    }
    if let treatments = treatments {
      output+="treatments = \(treatments) \n"
    } else {
      output+="treatments = nil\n"
    }
    output+="}"
    return output
  }
}

extension KeySelector {
  override public var debugDescription: String {
    var output: String = "KeySelector {\n"
    if let trafficType = trafficType {
      output+="trafficType = \(trafficType) \n"
    } else {
      output+="trafficType = nil\n"
    }
    if let attribute = attribute {
      output+="attribute = \(attribute) \n"
    } else {
      output+="attribute = nil\n"
    }
    output+="}"
    return output
  }
}

extension Matcher {
  override public var debugDescription: String {
    var output: String = "Matcher {\n"
    if let keySelector = keySelector {
      output+="keySelector = \(String(reflecting: keySelector)) \n"
    } else {
      output+="keySelector = nil\n"
    }
    if let matcherType = matcherType {
      output+="matcherType = \(String(reflecting: matcherType)) \n"
    } else {
      output+="matcherType = nil\n"
    }
    if let negate = negate {
      output+="negate = \(negate) \n"
    } else {
      output+="negate = nil\n"
    }
    if let userDefinedSegmentMatcherData = userDefinedSegmentMatcherData {
      output+="userDefinedSegmentMatcherData = \(String(reflecting: userDefinedSegmentMatcherData)) \n"
    } else {
      output+="userDefinedSegmentMatcherData = nil\n"
    }
    if let whitelistMatcherData = whitelistMatcherData {
      output+="whitelistMatcherData = \(String(reflecting: whitelistMatcherData)) \n"
    } else {
      output+="whitelistMatcherData = nil\n"
    }
    if let unaryNumericMatcherData = unaryNumericMatcherData {
      output+="unaryNumericMatcherData = \(String(reflecting: unaryNumericMatcherData)) \n"
    } else {
      output+="unaryNumericMatcherData = nil\n"
    }
    if let betweenMatcherData = betweenMatcherData {
      output+="betweenMatcherData = \(String(reflecting: betweenMatcherData)) \n"
    } else {
      output+="betweenMatcherData = nil\n"
    }
    if let dependencyMatcherData = dependencyMatcherData {
      output+="dependencyMatcherData = \(String(reflecting: dependencyMatcherData)) \n"
    } else {
      output+="dependencyMatcherData = nil\n"
    }
    if let booleanMatcherData = booleanMatcherData {
      output+="booleanMatcherData = \(booleanMatcherData) \n"
    } else {
      output+="booleanMatcherData = nil\n"
    }
    if let stringMatcherData = stringMatcherData {
      output+="stringMatcherData = \(stringMatcherData) \n"
    } else {
      output+="stringMatcherData = nil\n"
    }
    output+="}"
    return output
  }
}

extension MatcherGroup {
  override public var debugDescription: String {
    var output: String = "MatcherGroup {\n"
    if let matcherCombiner = matcherCombiner {
      output+="matcherCombiner = \(String(reflecting: matcherCombiner)) \n"
    } else {
      output+="matcherCombiner = nil\n"
    }
    if let matchers = matchers {
      output+="matchers = \(matchers) \n"
    } else {
      output+="matchers = nil\n"
    }
    output+="}"
    return output
  }
}

extension Split {
  override public var debugDescription: String {
    var output: String = "Split {\n"
    if let name = name {
      output+="name = \(name) \n"
    } else {
      output+="name = nil\n"
    }
    if let seed = seed {
      output+="seed = \(seed) \n"
    } else {
      output+="seed = nil\n"
    }
    if let status = status {
      output+="status = \(String(reflecting: status)) \n"
    } else {
      output+="status = nil\n"
    }
    if let killed = killed {
      output+="killed = \(killed) \n"
    } else {
      output+="killed = nil\n"
    }
    if let defaultTreatment = defaultTreatment {
      output+="defaultTreatment = \(defaultTreatment) \n"
    } else {
      output+="defaultTreatment = nil\n"
    }
    if let conditions = conditions {
      output+="conditions = \(conditions) \n"
    } else {
      output+="conditions = nil\n"
    }
    if let trafficTypeName = trafficTypeName {
      output+="trafficTypeName = \(trafficTypeName) \n"
    } else {
      output+="trafficTypeName = nil\n"
    }
    if let changeNumber = changeNumber {
      output+="changeNumber = \(changeNumber) \n"
    } else {
      output+="changeNumber = nil\n"
    }
    if let trafficAllocation = trafficAllocation {
      output+="trafficAllocation = \(trafficAllocation) \n"
    } else {
      output+="trafficAllocation = nil\n"
    }
    if let trafficAllocationSeed = trafficAllocationSeed {
      output+="trafficAllocationSeed = \(trafficAllocationSeed) \n"
    } else {
      output+="trafficAllocationSeed = nil\n"
    }
    if let algo = algo {
      output+="algo = \(algo) \n"
    } else {
      output+="algo = nil\n"
    }
    output+="}"
    return output
  }
}

extension SplitChange {
    override public var debugDescription: String {
        var output: String = "SplitChange {\n"
        output+="splits = \(splits) \n"
        output+="since = \(since) \n"
        output+="till = \(till) \n"
        output+="}"
        return output
    }
}

extension Treatment {
  override public var debugDescription: String {
    var output: String = "Treatment {\n"
    if let name = name {
      output+="name = \(name) \n"
    } else {
      output+="name = nil\n"
    }
    if let treatment = treatment {
      output+="treatment = \(treatment) \n"
    } else {
      output+="treatment = nil\n"
    }
    output+="}"
    return output
  }
}

extension UnaryNumericMatcherData {
  override public var debugDescription: String {
    var output: String = "UnaryNumericMatcherData {\n"
    if let dataType = dataType {
      output+="dataType = \(String(reflecting: dataType)) \n"
    } else {
      output+="dataType = nil\n"
    }
    if let value = value {
      output+="value = \(value) \n"
    } else {
      output+="value = nil\n"
    }
    output+="}"
    return output
  }
}

extension UserDefinedSegmentMatcherData {
  override public var debugDescription: String {
    var output: String = "UserDefinedSegmentMatcherData {\n"
    if let segmentName = segmentName {
      output+="segmentName = \(segmentName) \n"
    } else {
      output+="segmentName = nil\n"
    }
    output+="}"
    return output
  }
}

extension WhitelistMatcherData {
  override public var debugDescription: String {
    var output: String = "WhitelistMatcherData {\n"
    if let whitelist = whitelist {
      output+="whitelist = \(whitelist) \n"
    } else {
      output+="whitelist = nil\n"
    }
    output+="}"
    return output
  }
}

extension Partition {
    override public var debugDescription: String {
        var output: String = "Partition {\n"
        if let treatment = treatment {
            output+="treatment = \(treatment) \n"
        } else {
            output+="treatment = nil\n"
        }
        if let size = size {
            output+="size = \(size) \n"
        } else {
            output+="size = nil\n"
        }
        output+="}"
        return output
    }
}
