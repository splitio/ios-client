//
//  Matcher.swift
//  Pods
//
//  Created by Brian Sztamfater on 28/9/17.
//
//

import Foundation
import SwiftyJSON

@objc public class Matcher: NSObject {
    
    var keySelector: KeySelector?
    var matcherType: MatcherType?
    var negate: Bool?
    var userDefinedSegmentMatcherData: UserDefinedSegmentMatcherData?
    var whitelistMatcherData: WhitelistMatcherData?
    var unaryNumericMatcherData: UnaryNumericMatcherData?
    var betweenMatcherData: BetweenMatcherData?
    var dependencyMatcherData: DependencyMatcherData?
    var booleanMatcherData: Bool?
    var stringMatcherData: String?
    public var client: SplitClient?
    
    public init(_ json: JSON) {
        self.keySelector = json["keySelector"] != JSON.null ? KeySelector(json["keySelector"]) : nil
        self.matcherType = MatcherType.enumFromString(string: json["matcherType"].stringValue)
        self.negate = json["negate"].boolValue
        self.userDefinedSegmentMatcherData = json["userDefinedSegmentMatcherData"] != JSON.null ? UserDefinedSegmentMatcherData(json["userDefinedSegmentMatcherData"]) : nil
        self.whitelistMatcherData = json["whitelistMatcherData"] != JSON.null ? WhitelistMatcherData(json["whitelistMatcherData"]) : nil
        self.unaryNumericMatcherData = json["unaryNumericMatcherData"] != JSON.null ? UnaryNumericMatcherData(json["unaryNumericMatcherData"]) : nil
        self.betweenMatcherData = json["betweenMatcherData"] != JSON.null ? BetweenMatcherData(json["betweenMatcherData"]) : nil
        self.dependencyMatcherData = json["dependencyMatcherData"] != JSON.null ? DependencyMatcherData(json["dependencyMatcherData"]) : nil
        self.booleanMatcherData = json["booleanMatcherData"] != JSON.null ? json["booleanMatcherData"].boolValue : nil
        self.stringMatcherData = json["stringMatcherData"] != JSON.null ? json["stringMatcherData"].stringValue : nil
    }
    //--------------------------------------------------------------------------------------------------
    public func getMatcher() -> MatcherProtocol {
        
        switch self.matcherType! {
            
        case .AllKeys: return AllKeysMatcher()
            
        case .ContainsAllOfSet: return ContainsAllOfSetMatcher(data: whitelistMatcherData?.whitelist, negate: self.negate, atributte: self.keySelector?.attribute, type: self.matcherType)
            
        case .ContainsString: return ContainsStringMatcher(data: whitelistMatcherData?.whitelist, negate: self.negate, atributte: self.keySelector?.attribute, type: self.matcherType)
            
        case .EndsWith: return EndsWithMatcher(data: whitelistMatcherData?.whitelist, negate: self.negate, atributte: self.keySelector?.attribute, type: self.matcherType)
            
        case .StartsWith: return StartWithMatcher(data: whitelistMatcherData?.whitelist, negate: self.negate, atributte: self.keySelector?.attribute, type: self.matcherType)
            
        case .EqualTo: return EqualToMatcher(data: self.unaryNumericMatcherData, negate: self.negate, atributte: self.keySelector?.attribute, type: self.matcherType)
            
        case .EqualToBoolean: return EqualToBooleanMatcher(data: self.booleanMatcherData, negate: self.negate, atributte: self.keySelector?.attribute, type: self.matcherType)
            
        case .EqualToSet: return EqualToSetMatcher(data: whitelistMatcherData?.whitelist, negate: self.negate, atributte: self.keySelector?.attribute, type: self.matcherType)
            
        case .InSegment: return InSegmentMatcher(data: self.userDefinedSegmentMatcherData, splitClient: self.client, negate: self.negate, atributte: self.keySelector?.attribute, type: self.matcherType)
            
        case .MatchesString: return MatchesStringMatcher(data: self.stringMatcherData, negate: self.negate, atributte: self.keySelector?.attribute, type: self.matcherType)
            
        case .Whitelist: return Whitelist(data: whitelistMatcherData?.whitelist, negate: self.negate, atributte: self.keySelector?.attribute, type: self.matcherType)
            
        case .Dependency: return DependencyMatcher(splitClient: self.client, negate: self.negate, atributte: self.keySelector?.attribute, type: self.matcherType, dependencyData: self.dependencyMatcherData)
            
        case .ContainsAnyOfSet: return ContainsAnyOfSetMatcher(data: whitelistMatcherData?.whitelist, negate: self.negate, atributte: self.keySelector?.attribute, type: self.matcherType)
            
        case .PartOfSet: return PartOfSetMatcher(data: whitelistMatcherData?.whitelist, negate: self.negate, atributte: self.keySelector?.attribute, type: self.matcherType)
            
        case .LessThanOrEqualTo: return LessThanOrEqualToMatcher(data: self.unaryNumericMatcherData, negate: self.negate, atributte: self.keySelector?.attribute, type: self.matcherType)
            
        case .GreaterThanOrEqualTo: return GreaterThanOrEqualToMatcher(data: self.unaryNumericMatcherData, negate: self.negate, atributte: self.keySelector?.attribute, type: self.matcherType)
            
        case .Between: return BetweenMatcher(data: self.betweenMatcherData, negate: self.negate, atributte: self.keySelector?.attribute, type: self.matcherType)
            
            
        }
        
    }
    //--------------------------------------------------------------------------------------------------
    
}
