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
            
        case .Between: return AllKeysMatcher()

        case .ContainsAllOfSet: return AllKeysMatcher()
            
        case .ContainsString:
            
            return ContainsStringMatcher(data: whitelistMatcherData?.whitelist, negate: self.negate, atributte: self.keySelector?.attribute, type: self.matcherType) 
        
        case .EndsWith: return AllKeysMatcher()
            
        case .EqualTo: return AllKeysMatcher()

        case .EqualToBoolean: return AllKeysMatcher()

        case .EqualToSet: return AllKeysMatcher()
            
        case .GreaterThanOrEqualTo: return AllKeysMatcher()
        
        case .InSegment: return AllKeysMatcher()
            
        case .LessThanOrEqualTo: return AllKeysMatcher()
            
        case .MatchesString: return AllKeysMatcher()
        
        case .PartOfSet: return AllKeysMatcher()
            
        case .StartsWith: return AllKeysMatcher()
            
        case .Whitelist: return AllKeysMatcher()
            
        case .Dependency: return AllKeysMatcher()


        default:
            return AllKeysMatcher()
        }

    }
    //--------------------------------------------------------------------------------------------------

}
