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
    var whitelistMatcherData: WhitelistMatcherData?
    var unaryNumericMatcherData: UnaryNumericMatcherData?
    var betweenMatcherData: BetweenMatcherData?
    var dependencyMatcherData: DependencyMatcherData?
    var booleanMatcherData: Bool?
    var stringMatcherData: String?

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

    override init() {
        super.init()
    }

    required init(from decoder: Decoder) throws {
        if let values = try? decoder.container(keyedBy: CodingKeys.self) {
            keySelector = try? values.decode(KeySelector.self, forKey: .keySelector)
            matcherType = try? values.decode(MatcherType.self, forKey: .matcherType)
            negate = (try? values.decode(Bool.self, forKey: .negate)) ?? false
            userDefinedSegmentMatcherData = try? values.decode(UserDefinedSegmentMatcherData.self,
                                                               forKey: .userDefinedSegmentMatcherData)
            whitelistMatcherData = try? values.decode(WhitelistMatcherData.self, forKey: .whitelistMatcherData)
            unaryNumericMatcherData = try? values.decode(UnaryNumericMatcherData.self, forKey: .unaryNumericMatcherData)
            betweenMatcherData = try? values.decode(BetweenMatcherData.self, forKey: .betweenMatcherData)
            dependencyMatcherData = try? values.decode(DependencyMatcherData.self, forKey: .dependencyMatcherData)
            booleanMatcherData = try? values.decode(Bool.self, forKey: .booleanMatcherData)
            stringMatcherData = try? values.decode(String.self, forKey: .stringMatcherData)
        }
    }

    func getMatcher() throws -> MatcherProtocol {

        if self.matcherType == nil {
            throw EvaluatorError.matcherNotFound
        }

        switch self.matcherType! {

        case .allKeys: return AllKeysMatcher()

        case .containsAllOfSet: return ContainsAllOfSetMatcher(
            data: whitelistMatcherData?.whitelist, negate: self.negate, attribute: self.keySelector?.attribute,
                                                               type: self.matcherType)

        case .containsString: return ContainsStringMatcher(
            data: whitelistMatcherData?.whitelist, negate: self.negate, attribute: self.keySelector?.attribute,
                                                           type: self.matcherType)

        case .endsWith: return EndsWithMatcher(
            data: whitelistMatcherData?.whitelist, negate: self.negate, attribute: self.keySelector?.attribute,
                                               type: self.matcherType)

        case .startsWith: return StartWithMatcher(
            data: whitelistMatcherData?.whitelist, negate: self.negate, attribute: self.keySelector?.attribute,
                                                  type: self.matcherType)

        case .equalTo: return EqualToMatcher(
            data: self.unaryNumericMatcherData, negate: self.negate, attribute: self.keySelector?.attribute,
                                             type: self.matcherType)

        case .equalToBoolean: return EqualToBooleanMatcher(
            data: self.booleanMatcherData, negate: self.negate, attribute: self.keySelector?.attribute,
                                                           type: self.matcherType)

        case .equalToSet: return EqualToSetMatcher(
            data: whitelistMatcherData?.whitelist, negate: self.negate, attribute: self.keySelector?.attribute,
                                                   type: self.matcherType)

        case .inSegment: return InSegmentMatcher(
            data: self.userDefinedSegmentMatcherData, negate: self.negate,
            attribute: self.keySelector?.attribute, type: self.matcherType)

        case .matchesString: return MatchesStringMatcher(
            data: self.stringMatcherData, negate: self.negate, attribute: self.keySelector?.attribute,
            type: self.matcherType)

        case .whitelist: return Whitelist(
            data: whitelistMatcherData?.whitelist, negate: self.negate, attribute: self.keySelector?.attribute,
                                          type: self.matcherType)

        case .dependency: return DependencyMatcher(
            negate: self.negate, attribute: self.keySelector?.attribute,
            type: self.matcherType, dependencyData: self.dependencyMatcherData)

        case .containsAnyOfSet: return ContainsAnyOfSetMatcher(
            data: whitelistMatcherData?.whitelist, negate: self.negate, attribute: self.keySelector?.attribute,
            type: self.matcherType)

        case .partOfSet: return PartOfSetMatcher(
            data: whitelistMatcherData?.whitelist, negate: self.negate, attribute: self.keySelector?.attribute,
            type: self.matcherType)

        case .lessThanOrEqualTo: return LessThanOrEqualToMatcher(
            data: self.unaryNumericMatcherData, negate: self.negate, attribute: self.keySelector?.attribute,
            type: self.matcherType)

        case .greaterThanOrEqualTo: return GreaterThanOrEqualToMatcher(
            data: self.unaryNumericMatcherData, negate: self.negate, attribute: self.keySelector?.attribute,
            type: self.matcherType)

        case .between: return BetweenMatcher(
            data: self.betweenMatcherData, negate: self.negate, attribute: self.keySelector?.attribute,
            type: self.matcherType)
        }
    }
 }
