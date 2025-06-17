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
    private let flagSetsCache: FlagSetsCache
    private let flagSetsValidator: FlagSetsValidator
    private let propertyValidator: PropertyValidator

    private var isDestroyed = false

    init(evaluator: Evaluator,
         key: Key,
         splitConfig: SplitClientConfig,
         eventsManager: SplitEventsManager,
         impressionLogger: ImpressionLogger,
         telemetryProducer: TelemetryProducer?,
         storageContainer: SplitStorageContainer,
         flagSetsValidator: FlagSetsValidator,
         keyValidator: KeyValidator,
         splitValidator: SplitValidator,
         validationLogger: ValidationMessageLogger,
         propertyValidator: PropertyValidator) {

        self.key = key
        self.splitConfig = splitConfig
        self.evaluator = evaluator
        self.eventsManager = eventsManager
        self.impressionLogger = impressionLogger
        self.telemetryProducer = telemetryProducer
        self.attributesStorage = storageContainer.attributesStorage
        self.flagSetsCache = storageContainer.flagSetsCache
        self.flagSetsValidator = flagSetsValidator
        self.keyValidator = keyValidator
        self.splitValidator = splitValidator
        self.validationLogger = validationLogger
        self.propertyValidator = propertyValidator
    }

    func getTreatmentWithConfig(_ splitName: String, attributes: [String: Any]?, evaluationOptions: EvaluationOptions? = nil) -> SplitResult {

        let timeStart = startTime()
        let mergedAttributes = mergeAttributes(attributes: attributes)
        let result = getTreatmentWithConfigNoMetrics(splitName: splitName,
                                                     shouldValidate: true,
                                                     attributes: mergedAttributes,
                                                     evaluationOptions: evaluationOptions,
                                                     validationTag: ValidationTag.getTreatmentWithConfig)
        telemetryProducer?.recordLatency(method: .treatmentWithConfig, latency: Stopwatch.interval(from: timeStart))
        return result
    }

    func getTreatment(_ splitName: String, attributes: [String: Any]?, evaluationOptions: EvaluationOptions? = nil) -> String {
        let timeStart = startTime()
        let result = getTreatmentWithConfigNoMetrics(splitName: splitName,
                                                     shouldValidate: true,
                                                     attributes: attributes,
                                                     evaluationOptions: evaluationOptions,
                                                     validationTag: ValidationTag.getTreatment).treatment
        telemetryProducer?.recordLatency(method: .treatment, latency: Stopwatch.interval(from: timeStart))
        return result
    }

    func getTreatments(splits: [String], attributes: [String: Any]?, evaluationOptions: EvaluationOptions? = nil) -> [String: String] {
        let timeStart = startTime()
        let treatments = getTreatmentsWithConfigNoMetrics(splits: splits,
                                                          attributes: attributes,
                                                          evaluationOptions: evaluationOptions,
                                                          validationTag: ValidationTag.getTreatments)
        let result = treatments.mapValues { $0.treatment }
        telemetryProducer?.recordLatency(method: .treatments, latency: Stopwatch.interval(from: timeStart))
        return result
    }

    func getTreatmentsWithConfig(splits: [String], attributes: [String: Any]?, evaluationOptions: EvaluationOptions? = nil) -> [String: SplitResult] {
        let timeStart = startTime()
        let result = getTreatmentsWithConfigNoMetrics(splits: splits,
                                                      attributes: attributes,
                                                      evaluationOptions: evaluationOptions,
                                                      validationTag: ValidationTag.getTreatmentsWithConfig)
        telemetryProducer?.recordLatency(method: .treatmentsWithConfig, latency: Stopwatch.interval(from: timeStart))
        return result
    }
}

// MARK: FlagSets evaluation
extension DefaultTreatmentManager {
    func getTreatmentsByFlagSet(flagSet: String, attributes: [String: Any]?, evaluationOptions: EvaluationOptions? = nil) -> [String: String] {
        let featureFlags = featureFlagsFromSets([flagSet], validationTag: ValidationTag.getTreatmentsByFlagSet)
        let timeStart = startTime()
        let treatments = getTreatmentsWithConfigNoMetrics(splits: featureFlags,
                                                          attributes: attributes,
                                                          evaluationOptions: evaluationOptions,
                                                          validationTag: ValidationTag.getTreatmentsByFlagSet)
        let result = treatments.mapValues { $0.treatment }
        telemetryProducer?.recordLatency(method: .treatmentsByFlagSet, latency: Stopwatch.interval(from: timeStart))
        return result
    }

    func getTreatmentsByFlagSets(flagSets: [String], attributes: [String: Any]?, evaluationOptions: EvaluationOptions? = nil) -> [String: String] {
        let timeStart = startTime()
        let featureFlags = featureFlagsFromSets(flagSets, validationTag: ValidationTag.getTreatmentsByFlagSets)
        let treatments = getTreatmentsWithConfigNoMetrics(splits: featureFlags,
                                                          attributes: attributes,
                                                          evaluationOptions: evaluationOptions,
                                                          validationTag: ValidationTag.getTreatmentsByFlagSets)
        let result = treatments.mapValues { $0.treatment }
        telemetryProducer?.recordLatency(method: .treatmentsByFlagSets, latency: Stopwatch.interval(from: timeStart))
        return result
    }

    func getTreatmentsWithConfigByFlagSet(flagSet: String, attributes: [String: Any]?, evaluationOptions: EvaluationOptions? = nil) -> [String: SplitResult] {
        let timeStart = startTime()
        let featureFlags = featureFlagsFromSets([flagSet],
                                                validationTag: ValidationTag.getTreatmentsWithConfigByFlagSet)
        let result = getTreatmentsWithConfigNoMetrics(splits: featureFlags,
                                                      attributes: attributes,
                                                      evaluationOptions: evaluationOptions,
                                                      validationTag: ValidationTag.getTreatmentsWithConfigByFlagSet)
        telemetryProducer?.recordLatency(method: .treatmentsWithConfigByFlagSet,
                                         latency: Stopwatch.interval(from: timeStart))
        return result
    }

    func getTreatmentsWithConfigByFlagSets(flagSets: [String], attributes: [String: Any]?, evaluationOptions: EvaluationOptions? = nil) -> [String: SplitResult] {
        let timeStart = startTime()
        let featureFlags = featureFlagsFromSets(flagSets,
                                                validationTag: ValidationTag.getTreatmentsWithConfigByFlagSets)
        let result = getTreatmentsWithConfigNoMetrics(splits: featureFlags,
                                                      attributes: attributes,
                                                      evaluationOptions: evaluationOptions,
                                                      validationTag: ValidationTag.getTreatmentsWithConfigByFlagSets)
        telemetryProducer?.recordLatency(method: .treatmentsWithConfigByFlagSets,
                                         latency: Stopwatch.interval(from: timeStart))
        return result
    }
}

// MARK: Destroyable
extension DefaultTreatmentManager {
    func destroy() {
        isDestroyed = true
    }
}

// MARK: Treatment manager
extension DefaultTreatmentManager {

    private func featureFlagsFromSets(_ sets: [String], validationTag: String) -> [String] {
        let validatedSets = flagSetsValidator.validateOnEvaluation(
            sets,
            calledFrom: validationTag,
            setsInFilter: splitConfig.bySetsFilter()?.values ?? [])
        return flagSetsCache.getFeatureFlagNames(forFlagSets: validatedSets)
    }

    private func getTreatmentsWithConfigNoMetrics(splits: [String],
                                                  attributes: [String: Any]?,
                                                  evaluationOptions: EvaluationOptions? = nil,
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
                                                                     evaluationOptions: evaluationOptions,
                                                                     validationTag: validationTag)
            }
        } else {
            Logger.d("\(validationTag): feature flag names is an empty array or has null values")
        }
        return results
    }

    private func getTreatmentWithConfigNoMetrics(splitName: String,
                                                 shouldValidate: Bool = true,
                                                 attributes: [String: Any]?,
                                                 evaluationOptions: EvaluationOptions? = nil,
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
            let result = try evaluateIfReady(splitName: trimmedSplitName,
                                             attributes: mergedAttributes,
                                             validationTag: validationTag)
            logImpression(label: result.label, changeNumber: result.changeNumber,
                          treatment: result.treatment, splitName: trimmedSplitName, attributes: mergedAttributes,
                          impressionsDisabled: result.impressionsDisabled, validationTag: validationTag,
                          evaluationOptions: evaluationOptions)
            return SplitResult(treatment: result.treatment, config: result.configuration)
        } catch {
            logImpression(label: ImpressionsConstants.exception, treatment: SplitConstants.control,
                          splitName: trimmedSplitName, attributes: mergedAttributes, impressionsDisabled: false,
                          validationTag: validationTag, evaluationOptions: evaluationOptions)
            return SplitResult(treatment: SplitConstants.control)
        }
    }

    private func sdkNoReadyMessage(splitName: String) -> String {
        return "The SDK is not ready, results may be incorrect for feature flag \(splitName)."
                           + "Make sure to wait for SDK readiness before using this method"
    }

    private func evaluateIfReady(splitName: String,
                                 attributes: [String: Any]?,
                                 validationTag: String) throws -> EvaluationResult {
        if !isSdkReady() {
            validationLogger.w(message: sdkNoReadyMessage(splitName: splitName), tag: validationTag)
            telemetryProducer?.recordNonReadyUsage()
            return EvaluationResult(treatment: SplitConstants.control, label: ImpressionsConstants.notReady)
        }
        return try evaluator.evalTreatment(matchingKey: key.matchingKey,
                                           bucketingKey: key.bucketingKey,
                                           splitName: splitName,
                                           attributes: attributes)
    }

    private func logImpression(label: String, changeNumber: Int64? = nil,
                               treatment: String, splitName: String, attributes: [String: Any]? = nil,
                               impressionsDisabled: Bool,
                               validationTag: String,
                               evaluationOptions: EvaluationOptions? = nil) {

        let propertiesJson = serializeProperties(evaluationOptions?.properties, validationTag: validationTag)

        let keyImpression = KeyImpression(featureName: splitName,
                                          keyName: key.matchingKey,
                                          bucketingKey: key.bucketingKey,
                                          treatment: treatment,
                                          label: (splitConfig.isLabelsEnabled ? label : nil),
                                          time: Date().unixTimestampInMiliseconds(),
                                          changeNumber: changeNumber,
                                          properties: propertiesJson)
        impressionLogger.pushImpression(
            impression: DecoratedImpression(impression: keyImpression, impressionsDisabled: impressionsDisabled))

        if let externalImpressionHandler = splitConfig.impressionListener {
            let impression = keyImpression.toImpression()
            impression.attributes = attributes
            externalImpressionHandler(impression)
        }
    }

    private func serializeProperties(_ properties: [String: Any]?, validationTag: String) -> String? {
        // nil or empty properties are skipped
        guard let properties = properties, !properties.isEmpty else {
            return nil
        }

        // Validate properties using PropertyValidator
        let validationResult = propertyValidator.validate(
            properties: properties,
            initialSizeInBytes: 0,
            validationTag: validationTag
        )

        if !validationResult.isValid {
            validationLogger.e(message: "Properties validation failed: \(validationResult.errorMessage ?? "Unknown error")", tag: validationTag)
            return nil
        }

        if validationResult.validatedProperties == nil || validationResult.validatedProperties?.isEmpty == true {
            return nil
        }

        do {
            let data = try JSONSerialization.data(withJSONObject: validationResult.validatedProperties ?? [:], options: [])
            return String(data: data, encoding: .utf8)
        } catch {
            validationLogger.e(message: "Failed to serialize properties to JSON", tag: validationTag)
            return nil
        }
    }

    private func isSdkReady() -> Bool {
        return eventsManager.eventAlreadyTriggered(event: .sdkReadyFromCache) ||
            eventsManager.eventAlreadyTriggered(event: .sdkReady)
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
