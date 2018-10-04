 //
//  Matcher.swift
//  Pods
//
//  Created by Brian Sztamfater on 28/9/17.
//
//

import Foundation

@objc public class Matcher: NSObject, Codable {
    
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
    
    enum CodingKeys: String, CodingKey {
        case keySelector
        case matcherType
        case negate
        case userDefinedSegmentMatcherData
        case whitelistMatcherData
        case unaryNumericMatcherData
        case betweenMatcherData
        case dependencyMatcherData
        case booleanMatcherData
        case stringMatcherData
    }

    public required init(from decoder: Decoder) throws {
        if let values = try? decoder.container(keyedBy: CodingKeys.self) {
            keySelector = try? values.decode(KeySelector.self, forKey: .keySelector)
            matcherType = try? values.decode(MatcherType.self, forKey: .matcherType)
            negate = (try? values.decode(Bool.self, forKey: .negate)) ?? false
            userDefinedSegmentMatcherData = try? values.decode(UserDefinedSegmentMatcherData.self, forKey: .userDefinedSegmentMatcherData)
            whitelistMatcherData = try? values.decode(WhitelistMatcherData.self, forKey: .whitelistMatcherData)
            unaryNumericMatcherData = try? values.decode(UnaryNumericMatcherData.self, forKey: .unaryNumericMatcherData)
            betweenMatcherData = try? values.decode(BetweenMatcherData.self, forKey: .betweenMatcherData)
            dependencyMatcherData = try? values.decode(DependencyMatcherData.self, forKey: .dependencyMatcherData)
            booleanMatcherData = try? values.decode(Bool.self, forKey: .booleanMatcherData)
            stringMatcherData = try? values.decode(String.self, forKey: .stringMatcherData)
        }
    }
 
    //--------------------------------------------------------------------------------------------------
    public func getMatcher() throws -> MatcherProtocol {
        
        if self.matcherType == nil {
            throw EngineError.MatcherNotFound
        }
        
        switch self.matcherType! {
            
        case .AllKeys: return AllKeysMatcher()
            
        case .ContainsAllOfSet: return ContainsAllOfSetMatcher(data: whitelistMatcherData?.whitelist, negate: self.negate, attribute: self.keySelector?.attribute, type: self.matcherType)
            
        case .ContainsString: return ContainsStringMatcher(data: whitelistMatcherData?.whitelist, negate: self.negate, attribute: self.keySelector?.attribute, type: self.matcherType)
            
        case .EndsWith: return EndsWithMatcher(data: whitelistMatcherData?.whitelist, negate: self.negate, attribute: self.keySelector?.attribute, type: self.matcherType)
            
        case .StartsWith: return StartWithMatcher(data: whitelistMatcherData?.whitelist, negate: self.negate, attribute: self.keySelector?.attribute, type: self.matcherType)
            
        case .EqualTo: return EqualToMatcher(data: self.unaryNumericMatcherData, negate: self.negate, attribute: self.keySelector?.attribute, type: self.matcherType)
            
        case .EqualToBoolean: return EqualToBooleanMatcher(data: self.booleanMatcherData, negate: self.negate, attribute: self.keySelector?.attribute, type: self.matcherType)
            
        case .EqualToSet: return EqualToSetMatcher(data: whitelistMatcherData?.whitelist, negate: self.negate, attribute: self.keySelector?.attribute, type: self.matcherType)
            
        case .InSegment: return InSegmentMatcher(data: self.userDefinedSegmentMatcherData, splitClient: self.client, negate: self.negate, attribute: self.keySelector?.attribute, type: self.matcherType)
            
        case .MatchesString: return MatchesStringMatcher(data: self.stringMatcherData, negate: self.negate, attribute: self.keySelector?.attribute, type: self.matcherType)
            
        case .Whitelist: return Whitelist(data: whitelistMatcherData?.whitelist, negate: self.negate, attribute: self.keySelector?.attribute, type: self.matcherType)
            
        case .Dependency: return DependencyMatcher(splitClient: self.client, negate: self.negate, attribute: self.keySelector?.attribute, type: self.matcherType, dependencyData: self.dependencyMatcherData)
            
        case .ContainsAnyOfSet: return ContainsAnyOfSetMatcher(data: whitelistMatcherData?.whitelist, negate: self.negate, attribute: self.keySelector?.attribute, type: self.matcherType)
            
        case .PartOfSet: return PartOfSetMatcher(data: whitelistMatcherData?.whitelist, negate: self.negate, attribute: self.keySelector?.attribute, type: self.matcherType)
            
        case .LessThanOrEqualTo: return LessThanOrEqualToMatcher(data: self.unaryNumericMatcherData, negate: self.negate, attribute: self.keySelector?.attribute, type: self.matcherType)
            
        case .GreaterThanOrEqualTo: return GreaterThanOrEqualToMatcher(data: self.unaryNumericMatcherData, negate: self.negate, attribute: self.keySelector?.attribute, type: self.matcherType)
            
        case .Between: return BetweenMatcher(data: self.betweenMatcherData, negate: self.negate, attribute: self.keySelector?.attribute, type: self.matcherType)
            
            
        }
        
    }
    //--------------------------------------------------------------------------------------------------
    
}
