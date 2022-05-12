//
//  DefaultTreatmentManager.swift
//  Split
//
//  Created by Javier L. Avrudsky on 05/07/2019.
//  Copyright © 2019 Split. All rights reserved.
//

import Foundation

class DefaultTreatmentManager: TreatmentManager {

    private let key: Key
    private let telemetryProducer: TelemetryProducer?
    private let impressionLogger: ImpressionLogger
    private let eventsManager: SplitEventsManager
    private let keyValidator: KeyValidator
    private let splitValidator: SplitValidator
    private let validationLogger: ValidationMessageLogger
    private let evaluator: Evaluator
    private let splitConfig: SplitClientConfig
    private let attributesStorage: AttributesStorage
    private var isDestroyed = false

    init(evaluator: Evaluator,
         key: Key,
         splitConfig: SplitClientConfig,
         eventsManager: SplitEventsManager,
         impressionLogger: ImpressionLogger,
         telemetryProducer: TelemetryProducer?,
         attributesStorage: AttributesStorage,
         keyValidator: KeyValidator,
         splitValidator: SplitValidator,
         validationLogger: ValidationMessageLogger) {

        self.key = key
        self.splitConfig = splitConfig
        self.evaluator = evaluator
        self.eventsManager = eventsManager
        self.impressionLogger = impressionLogger
        self.telemetryProducer = telemetryProducer
        self.attributesStorage = attributesStorage
        self.keyValidator = keyValidator
        self.splitValidator = splitValidator
        self.validationLogger = validationLogger
    }

    func getTreatmentWithConfig(_ splitName: String, attributes: [String: Any]?) -> SplitResult {

        let timeStart = startTime()
        let mergedAttributes = mergeAttributes(attributes: attributes)
        let result = getTreatmentWithConfigNoMetrics(splitName: splitName,
                                                     shouldValidate: true,
                                                     attributes: mergedAttributes,
                                                     validationTag: ValidationTag.getTreatmentWithConfig)
        telemetryProducer?.recordLatency(method: .treatmentWithConfig, latency: Stopwatch.interval(from: timeStart))
        return result
    }

    func getTreatment(_ splitName: String, attributes: [String: Any]?) -> String {
        let timeStart = startTime()
        let result = getTreatmentWithConfigNoMetrics(splitName: splitName,
                                                     shouldValidate: true,
                                                     attributes: attributes,
                                                     validationTag: ValidationTag.getTreatment).treatment
        telemetryProducer?.recordLatency(method: .treatment, latency: Stopwatch.interval(from: timeStart))
        return result
    }

    func getTreatments(splits: [String], attributes: [String: Any]?) -> [String: String] {
        let timeStart = startTime()
        let treatments = getTreatmentsWithConfigNoMetrics(splits: splits,
                                                      attributes: attributes,
                                                      validationTag: ValidationTag.getTreatments)
        let result = treatments.mapValues { $0.treatment }
        telemetryProducer?.recordLatency(method: .treatments, latency: Stopwatch.interval(from: timeStart))
        return result
    }

    func getTreatmentsWithConfig(splits: [String], attributes: [String: Any]?) -> [String: SplitResult] {
        let timeStart = startTime()
        let result = getTreatmentsWithConfigNoMetrics(splits: splits,
                                                      attributes: attributes,
                                                      validationTag: ValidationTag.getTreatmentsWithConfig)
        telemetryProducer?.recordLatency(method: .treatmentsWithConfig, latency: Stopwatch.interval(from: timeStart))
        return result
    }

    func destroy() {
        isDestroyed = true
    }

    private func getTreatmentsWithConfigNoMetrics(splits: [String],
                                                  attributes: [String: Any]?,
                                                  validationTag: String) -> [String: SplitResult] {
        var results = [String: SplitResult]()

        let controlResults: () -> [String: SplitResult] = {
            return splits.filter { !$0.isEmpty() }.reduce([String: SplitResult]()) { results, splitName in
                var res = results
                res[splitName] = SplitResult(treatment: SplitConstants.control)
                return res
            }
        }

        if checkAndLogIfDestroyed(logTag: validationTag) {
            return controlResults()
        }

        if let errorInfo = keyValidator.validate(matchingKey: key.matchingKey,
                                                 bucketingKey: key.bucketingKey) {
            validationLogger.log(errorInfo: errorInfo, tag: validationTag)
            return controlResults()
        }

        if splits.count > 0 {
            let mergedAttributes = mergeAttributes(attributes: attributes)
            let splitsNoDuplicated = Set(splits.filter { !$0.isEmpty() }.map { $0 })
            for splitName in splitsNoDuplicated {
                results[splitName] = getTreatmentWithConfigNoMetrics(splitName: splitName,
                                                                     shouldValidate: false,
                                                                     attributes: mergedAttributes,
                                                                     validationTag: validationTag)
            }
        } else {
            Logger.d("\(validationTag): split_names is an empty array or has null values")
        }
        return results
    }

    private func getTreatmentWithConfigNoMetrics(splitName: String,
                                                 shouldValidate: Bool = true,
                                                 attributes: [String: Any]? = nil,
                                                 validationTag: String) -> SplitResult {

        if checkAndLogIfDestroyed(logTag: validationTag) {
            return SplitResult(treatment: SplitConstants.control)
        }

        if shouldValidate, let errorInfo = keyValidator.validate(matchingKey: key.matchingKey,
                                                                 bucketingKey: key.bucketingKey) {
            validationLogger.log(errorInfo: errorInfo, tag: validationTag)
            return SplitResult(treatment: SplitConstants.control)
        }

        if let errorInfo = splitValidator.validate(name: splitName) {
            validationLogger.log(errorInfo: errorInfo, tag: validationTag)
            if errorInfo.isError {
                return SplitResult(treatment: SplitConstants.control)
            }
        }

        if let errorInfo = splitValidator.validateSplit(name: splitName) {
            validationLogger.log(errorInfo: errorInfo, tag: validationTag)
            if errorInfo.isError || errorInfo.hasWarning(.nonExistingSplit) {
                return SplitResult(treatment: SplitConstants.control)
            }
        }

        let trimmedSplitName = splitName.trimmingCharacters(in: .whitespacesAndNewlines)
        let mergedAttributes = mergeAttributes(attributes: attributes)
        do {
            let result = try evaluateIfReady(splitName: trimmedSplitName, attributes: mergedAttributes)
            logImpression(label: result.label, changeNumber: result.changeNumber,
                          treatment: result.treatment, splitName: trimmedSplitName, attributes: mergedAttributes)
            return SplitResult(treatment: result.treatment, config: result.configuration)
        } catch {
            logImpression(label: ImpressionsConstants.exception, treatment: SplitConstants.control,
                          splitName: trimmedSplitName, attributes: mergedAttributes)
            return SplitResult(treatment: SplitConstants.control)
        }
    }

    private func evaluateIfReady(splitName: String, attributes: [String: Any]?) throws -> EvaluationResult {
        if !isSdkReady() {
            telemetryProducer?.recordNonReadyUsage()
            return EvaluationResult(treatment: SplitConstants.control, label: ImpressionsConstants.notReady)
        }
        return try evaluator.evalTreatment(matchingKey: key.matchingKey,
                                           bucketingKey: key.bucketingKey,
                                           splitName: splitName,
                                           attributes: attributes)
    }

    private func logImpression(label: String, changeNumber: Int64? = nil,
                               treatment: String, splitName: String, attributes: [String: Any]? = nil) {

        let keyImpression = KeyImpression(featureName: splitName,
                                          keyName: key.matchingKey,
                                          bucketingKey: key.bucketingKey,
                                          treatment: treatment,
                                          label: (splitConfig.isLabelsEnabled ? label : nil),
                                          time: Date().unixTimestampInMiliseconds(),
                                          changeNumber: changeNumber)
        impressionLogger.pushImpression(impression: keyImpression)

        if let externalImpressionHandler = splitConfig.impressionListener {
            let impression = keyImpression.toImpression()
            impression.attributes = attributes
            externalImpressionHandler(impression)
        }
    }

    private func isSdkReady() -> Bool {
        return eventsManager.eventAlreadyTriggered(event: SplitEvent.sdkReadyFromCache) ||
            eventsManager.eventAlreadyTriggered(event: SplitEvent.sdkReady)
    }

    private func checkAndLogIfDestroyed(logTag: String) -> Bool {
        if isDestroyed {
            validationLogger.e(message: "Client has already been destroyed - no calls possible", tag: logTag)
        }
        return isDestroyed
    }

    private func mergeAttributes(attributes: [String: Any]?) -> [String: Any]? {
        let storedAttributes = attributesStorage.getAll(forKey: key.matchingKey)

        if storedAttributes.count == 0 {
            return attributes
        }

        guard let attributes = attributes else {
            return storedAttributes
        }

        return attributes.merging(storedAttributes) { (current, _) in current }
    }

    private func startTime() -> Int64 {
        if telemetryProducer == nil {
            return 0
        }
        return Stopwatch.now()
    }
}
