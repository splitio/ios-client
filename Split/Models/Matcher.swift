//
//  Matcher.swift
//  Split
//
//  Created by Brian Sztamfater on 28/9/17.
//
//

import Foundation

// swiftlint:disable cyclomatic_complexity function_body_length inclusive_language
class Matcher: NSObject, Codable {
    var keySelector: KeySelector?
    var matcherType: MatcherType?
    var negate: Bool?
    var userDefinedSegmentMatcherData: UserDefinedSegmentMatcherData?
    var userDefinedLargeSegmentMatcherData: UserDefinedLargeSegmentMatcherData?
    var whitelistMatcherData: WhitelistMatcherData?
    var unaryNumericMatcherData: UnaryNumericMatcherData?
    var betweenMatcherData: BetweenMatcherData?
    var dependencyMatcherData: DependencyMatcherData?
    var booleanMatcherData: Bool?
    var stringMatcherData: String?
    var betweenStringMatcherData: BetweenStringMatcherData?

    enum CodingKeys: String, CodingKey {
        case keySelector
        case matcherType
        case negate
        case userDefinedSegmentMatcherData
        case userDefinedLargeSegmentMatcherData
        case whitelistMatcherData
        case unaryNumericMatcherData
        case betweenMatcherData
        case dependencyMatcherData
        case booleanMatcherData
        case stringMatcherData
        case betweenStringMatcherData
    }

    override init() {
        super.init()
    }

    required init(from decoder: Decoder) throws {
        if let values = try? decoder.container(keyedBy: CodingKeys.self) {
            self.keySelector = try? values.decode(KeySelector.self, forKey: .keySelector)
            self.matcherType = try? values.decode(MatcherType.self, forKey: .matcherType)
            self.negate = (try? values.decode(Bool.self, forKey: .negate)) ?? false
            self.userDefinedSegmentMatcherData = try? values.decode(
                UserDefinedSegmentMatcherData.self,
                forKey: .userDefinedSegmentMatcherData)
            self.userDefinedLargeSegmentMatcherData = try? values.decode(
                UserDefinedLargeSegmentMatcherData.self,
                forKey: .userDefinedLargeSegmentMatcherData)
            self.whitelistMatcherData = try? values.decode(WhitelistMatcherData.self, forKey: .whitelistMatcherData)
            self.unaryNumericMatcherData = try? values.decode(
                UnaryNumericMatcherData.self,
                forKey: .unaryNumericMatcherData)
            self.betweenMatcherData = try? values.decode(BetweenMatcherData.self, forKey: .betweenMatcherData)
            self.dependencyMatcherData = try? values.decode(DependencyMatcherData.self, forKey: .dependencyMatcherData)
            self.booleanMatcherData = try? values.decode(Bool.self, forKey: .booleanMatcherData)
            self.stringMatcherData = try? values.decode(String.self, forKey: .stringMatcherData)
            self.betweenStringMatcherData = try? values.decode(
                BetweenStringMatcherData.self,
                forKey: .betweenStringMatcherData)
        }
    }

    func getMatcher() throws -> MatcherProtocol {
        if matcherType == nil {
            throw EvaluatorError.matcherNotFound
        }

        switch matcherType! {
        case .allKeys: return AllKeysMatcher()

        case .containsAllOfSet: return ContainsAllOfSetMatcher(
                data: whitelistMatcherData?.whitelist, negate: negate, attribute: keySelector?.attribute,
                type: matcherType)

        case .containsString: return ContainsStringMatcher(
                data: whitelistMatcherData?.whitelist, negate: negate, attribute: keySelector?.attribute,
                type: matcherType)

        case .endsWith: return EndsWithMatcher(
                data: whitelistMatcherData?.whitelist, negate: negate, attribute: keySelector?.attribute,
                type: matcherType)

        case .startsWith: return StartWithMatcher(
                data: whitelistMatcherData?.whitelist, negate: negate, attribute: keySelector?.attribute,
                type: matcherType)

        case .equalTo: return EqualToMatcher(
                data: unaryNumericMatcherData, negate: negate, attribute: keySelector?.attribute,
                type: matcherType)

        case .equalToBoolean: return EqualToBooleanMatcher(
                data: booleanMatcherData, negate: negate, attribute: keySelector?.attribute,
                type: matcherType)

        case .equalToSet: return EqualToSetMatcher(
                data: whitelistMatcherData?.whitelist, negate: negate, attribute: keySelector?.attribute,
                type: matcherType)

        case .inSegment: return InSegmentMatcher(
                data: userDefinedSegmentMatcherData, negate: negate,
                attribute: keySelector?.attribute, type: matcherType)

        case .inLargeSegment: return InLargeSegmentMatcher(
                data: userDefinedLargeSegmentMatcherData, negate: negate,
                attribute: keySelector?.attribute, type: matcherType)

        case .inRuleBasedSegment: return InRuleBasedSegmentMatcher(
                data: userDefinedSegmentMatcherData, negate: negate,
                attribute: keySelector?.attribute, type: matcherType)

        case .matchesString: return MatchesStringMatcher(
                data: stringMatcherData, negate: negate, attribute: keySelector?.attribute,
                type: matcherType)

        case .whitelist: return Whitelist(
                data: whitelistMatcherData?.whitelist, negate: negate, attribute: keySelector?.attribute,
                type: matcherType)

        case .dependency: return DependencyMatcher(
                negate: negate, attribute: keySelector?.attribute,
                type: matcherType, dependencyData: dependencyMatcherData)

        case .containsAnyOfSet: return ContainsAnyOfSetMatcher(
                data: whitelistMatcherData?.whitelist, negate: negate, attribute: keySelector?.attribute,
                type: matcherType)

        case .partOfSet: return PartOfSetMatcher(
                data: whitelistMatcherData?.whitelist, negate: negate, attribute: keySelector?.attribute,
                type: matcherType)

        case .lessThanOrEqualTo: return LessThanOrEqualToMatcher(
                data: unaryNumericMatcherData, negate: negate, attribute: keySelector?.attribute,
                type: matcherType)

        case .greaterThanOrEqualTo: return GreaterThanOrEqualToMatcher(
                data: unaryNumericMatcherData, negate: negate, attribute: keySelector?.attribute,
                type: matcherType)

        case .between: return BetweenMatcher(
                data: betweenMatcherData, negate: negate, attribute: keySelector?.attribute,
                type: matcherType)

        case .equalToSemver: return EqualToSemverMatcher(
                data: stringMatcherData, negate: negate, attribute: keySelector?.attribute,
                type: matcherType)

        case .greaterThanOrEqualToSemver: return GreaterThanOrEqualToSemverMatcher(
                data: stringMatcherData, negate: negate, attribute: keySelector?.attribute,
                type: matcherType)

        case .lessThanOrEqualToSemver: return LessThanOrEqualToSemverMatcher(
                data: stringMatcherData,
                negate: negate,
                attribute: keySelector?.attribute,
                type: matcherType)

        case .betweenSemver: return BetweenSemverMatcher(
                data: betweenStringMatcherData, negate: negate, attribute: keySelector?.attribute,
                type: matcherType)

        case .inListSemver: return InListSemverMatcher(
                data: whitelistMatcherData?.whitelist, negate: negate, attribute: keySelector?.attribute,
                type: matcherType)
        }
    }
}
