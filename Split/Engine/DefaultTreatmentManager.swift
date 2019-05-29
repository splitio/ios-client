//
//  DefaultTreatmentManager.swift
//  Split
//
//  Created by Javier L. Avrudsky on 27/05/2019.
//  Copyright © 2019 Split. All rights reserved.
//

import Foundation

class DefaultTreatmentManager: TreatmentManager {
    
    private let key: Key
    private let splitConfig: SplitClientConfig
    private let metricsManager: MetricsManager
    private let impressionMananger: ImpressionManager
    private let splitValidator: SplitValidator
    var validationLogger: ValidationMessageLogger
    var keyValidator: KeyValidator
    
    init(key: Key, splitConfig: SplitClientConfig, metricsManager: MetricsManager, impressionManager: ImpressionManager, splitValidator: SplitValidator) {
        self.key = key
        self.splitConfig = splitConfig
        self.metricsManager = metricsManager
        self.impressionMananger = impressionManager
        self.splitValidator = splitValidator
        self.keyValidator = DefaultKeyValidator()
        self.validationLogger = DefaultValidationMessageLogger()
    }
        
        func getTreatmentWithConfig(_ split: String, attributes: [String : Any]?, isSdkReadyEventTriggered: Bool) -> SplitResult {
            let timeMetricStart = Date().unixTimestampInMicroseconds()
            let result = getTreatmentWithConfigNoMetrics(splitName: split, shouldValidate: true, attributes: attributes, validationTag: ValidationTag.getTreatmentWithConfig, isSdkReadyEventTriggered: isSdkReadyEventTriggered)
            metricsManager.time(microseconds: Date().unixTimestampInMicroseconds() - timeMetricStart, for: Metrics.time.getTreatmentWithConfig)
            return result
        }
        
        func getTreatment(_ split: String, attributes: [String : Any]?, isSdkReadyEventTriggered: Bool) -> String {
            let timeMetricStart = Date().unixTimestampInMicroseconds()
            let result = getTreatmentWithConfigNoMetrics(splitName: split, shouldValidate: true, attributes: attributes, validationTag: ValidationTag.getTreatment, isSdkReadyEventTriggered: isSdkReadyEventTriggered).treatment
            metricsManager.time(microseconds: Date().unixTimestampInMicroseconds() - timeMetricStart, for: Metrics.time.getTreatment)
            return result
        }
        
        func getTreatments(splits: [String], attributes:[String:Any]?, isSdkReadyEventTriggered: Bool) ->  [String:String] {
            let timeMetricStart = Date().unixTimestampInMicroseconds()
            let result = getTreatmentsWithConfigNoMetrics(splits: splits, attributes: attributes, validationTag: ValidationTag.getTreatments, isSdkReadyEventTriggered: isSdkReadyEventTriggered).mapValues { $0.treatment }
            metricsManager.time(microseconds: Date().unixTimestampInMicroseconds() - timeMetricStart, for: Metrics.time.getTreatments)
            return result
        }
        
        func getTreatmentsWithConfig(splits: [String], attributes:[String:Any]?, isSdkReadyEventTriggered: Bool) ->  [String:SplitResult] {
            let timeMetricStart = Date().unixTimestampInMicroseconds()
            let result = getTreatmentsWithConfigNoMetrics(splits: splits, attributes: attributes, validationTag: ValidationTag.getTreatmentsWithConfig, isSdkReadyEventTriggered: isSdkReadyEventTriggered)
            metricsManager.time(microseconds: Date().unixTimestampInMicroseconds() - timeMetricStart, for: Metrics.time.getTreatmentsWithConfig)
            return result
        }
        
    private func getTreatmentsWithConfigNoMetrics(splits: [String], attributes:[String:Any]?, validationTag: String, isSdkReadyEventTriggered: Bool) ->  [String:SplitResult] {
            var results = [String:SplitResult]()
            
            if splits.count > 0 {
                let splitsNoDuplicated = Set(splits.filter { !$0.isEmpty() }.map { $0 })
                for splitName in splitsNoDuplicated {
                    results[splitName] = getTreatmentWithConfigNoMetrics(splitName: splitName, shouldValidate: false, attributes: attributes, validationTag: validationTag, isSdkReadyEventTriggered: isSdkReadyEventTriggered)
                }
            } else {
                Logger.d("\(validationTag): split_names is an empty array or has null values")
            }
            return results
        }
        
    private func getTreatmentWithConfigNoMetrics(splitName: String, shouldValidate: Bool = true, attributes:[String:Any]? = nil, validationTag: String, isSdkReadyEventTriggered: Bool) -> SplitResult {
            
            if shouldValidate {
                if !isSdkReadyEventTriggered {
                    Logger.w("No listeners for SDK Readiness detected. Incorrect control treatments could be logged if you call getTreatment while the SDK is not yet ready")
                }
                
                if let errorInfo = keyValidator.validate(matchingKey: key.matchingKey, bucketingKey: key.bucketingKey) {
                    validationLogger.log(errorInfo: errorInfo, tag: validationTag)
                    return SplitResult(treatment: SplitConstants.CONTROL)
                }
            }
            
            if let errorInfo = splitValidator.validate(name: splitName) {
                validationLogger.log(errorInfo: errorInfo, tag: validationTag)
                if errorInfo.isError {
                    return SplitResult(treatment: SplitConstants.CONTROL)
                }
            }
            
            if let errorInfo = splitValidator.validateSplit(name: splitName) {
                validationLogger.log(errorInfo: errorInfo, tag: validationTag)
                if errorInfo.isError {
                    return SplitResult(treatment: SplitConstants.CONTROL)
                }
            }
            
            let trimmedSplitName = splitName.trimmingCharacters(in: .whitespacesAndNewlines)
            let evaluator: Evaluator = Evaluator.shared
            evaluator.splitClient = self
            
            do {
                let result = try Evaluator.shared.evalTreatment(key: self.key.matchingKey, bucketingKey: self.key.bucketingKey, split: trimmedSplitName, attributes: attributes)
                if let splitVersion = result.splitVersion {
                    logImpression(label: result.label, changeNumber: splitVersion, treatment: result.treatment, splitName: trimmedSplitName, attributes: attributes)
                } else {
                    logImpression(label: result.label, treatment: result.treatment, splitName: trimmedSplitName, attributes: attributes)
                }
                return SplitResult(treatment: result.treatment, config: result.configuration)
            }
            catch {
                logImpression(label: ImpressionsConstants.EXCEPTION, treatment: SplitConstants.CONTROL, splitName: trimmedSplitName, attributes: attributes)
                return SplitResult(treatment: SplitConstants.CONTROL)
            }
        }
        
        private func logImpression(label: String, changeNumber: Int64? = nil, treatment: String, splitName: String, attributes:[String:Any]? = nil) {
            let impression: Impression = Impression()
            impression.keyName = self.key.matchingKey
            
            impression.bucketingKey = (self.shouldSendBucketingKey) ? self.key.bucketingKey : nil
            impression.label = label
            impression.changeNumber = changeNumber
            impression.treatment = treatment
            impression.time = Date().unixTimestampInMiliseconds()
            impressionMananger.appendImpression(impression: impression, splitName: splitName)
            
            if let externalImpressionHandler = splitConfig.impressionListener {
                impression.attributes = attributes
                externalImpressionHandler(impression)
            }
        }

}
