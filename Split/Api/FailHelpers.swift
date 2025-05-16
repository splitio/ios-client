//
//  FailHelpers.swift
//  Split
//
//  Created by Javier Avrudsky on 24-Apr-2022.
//  Copyright © 2022 Split. All rights reserved.
//

import Foundation

/// To avoid crashing host app this dummy components will be returned
/// on Failed init

class FailedClient: SplitClient {

    // MARK: Treatments
    func getTreatment(_ split: String) -> String {
        return SplitConstants.control
    }

    func getTreatment(_ split: String, attributes: [String: Any]?) -> String {
        return getTreatment("")
    }
    
    func getTreatment(_ split: String, attributes: [String: Any]?, evaluationOptions: EvaluationOptions?) -> String {
        return getTreatment("")
    }

    func getTreatments(splits: [String], attributes: [String: Any]?) -> [String: String] {
        return [:]
    }

    func getTreatments(splits: [String], attributes: [String: Any]?, evaluationOptions: EvaluationOptions?) -> [String: String] {
        return [:]
    }

    func getTreatmentWithConfig(_ split: String) -> SplitResult {
        return SplitResult(treatment: SplitConstants.control)
    }

    func getTreatmentWithConfig(_ split: String, attributes: [String: Any]?) -> SplitResult {
        return getTreatmentWithConfig("")
    }

    func getTreatmentWithConfig(_ split: String, attributes: [String: Any]?, evaluationOptions: EvaluationOptions?) -> SplitResult {
        return getTreatmentWithConfig("")
    }

    func getTreatmentsWithConfig(splits: [String], attributes: [String: Any]?) -> [String: SplitResult] {
        return [:]
    }
    
    func getTreatmentsWithConfig(splits: [String], attributes: [String: Any]?, evaluationOptions: EvaluationOptions?) -> [String: SplitResult] {
        return [:]
    }

    // MARK: Events Listeners
    func on(event: SplitEvent, execute action: @escaping SplitAction) {}

    func on(event: SplitEvent, runInBackground: Bool, execute action: @escaping SplitAction) {}

    func on(event: SplitEvent, queue: DispatchQueue, execute action: @escaping SplitAction) {}
    
    func on(event: SplitEvent, executeWithMetadata: SplitActionWithMetadata) {}

    // MARK: Tracking
    func track(trafficType: String, eventType: String) -> Bool {
        return false
    }

    func track(trafficType: String, eventType: String, value: Double) -> Bool {
        return false
    }

    func track(eventType: String) -> Bool {
        return false
    }

    func track(eventType: String, value: Double) -> Bool {
        return false
    }

    func setAttribute(name: String, value: Any) -> Bool {
        return false
    }

    func getAttribute(name: String) -> Any? {
        return false
    }

    func setAttributes(_ values: [String: Any]) -> Bool {
        return false
    }

    func getAttributes() -> [String: Any]? {
        return [:]
    }

    func removeAttribute(name: String) -> Bool {
        return false
    }

    func clearAttributes() -> Bool {
        return false
    }
    
    // MARK: By FlagSets
    func getTreatmentsByFlagSet(_ flagSet: String, attributes: [String: Any]?) -> [String: String] {
        return [:]
    }
    
    func getTreatmentsByFlagSets(_ flagSets: [String], attributes: [String: Any]?) -> [String: String] {
        return [:]
    }
    
    func getTreatmentsWithConfigByFlagSet(_ flagSet: String, attributes: [String: Any]?) -> [String: SplitResult] {
        return [:]
    }
    
    func getTreatmentsWithConfigByFlagSets(_ flagSets: [String], attributes: [String: Any]?) -> [String: SplitResult] {
        return [:]
    }

    func getTreatmentsByFlagSet(_ flagSet: String, attributes: [String: Any]?, evaluationOptions: EvaluationOptions?) -> [String: String] {
        return [:]
    }
    
    func getTreatmentsByFlagSets(_ flagSets: [String], attributes: [String: Any]?, evaluationOptions: EvaluationOptions?) -> [String: String] {
        return [:]
    }
    
    func getTreatmentsWithConfigByFlagSet(_ flagSet: String, attributes: [String: Any]?, evaluationOptions: EvaluationOptions?) -> [String: SplitResult] {
        return [:]
    }
    
    func getTreatmentsWithConfigByFlagSets(_ flagSets: [String], attributes: [String: Any]?, evaluationOptions: EvaluationOptions?) -> [String: SplitResult] {
        return [:]
    }

    func setUserConsent(enabled: Bool) {}

    // MARK: Lifeycle
    func flush() {}

    func destroy() {}

    func destroy(completion: (() -> Void)?) {
        completion?()
    }

    // MARK: Tracking
    func track(trafficType: String, eventType: String, properties: [String: Any]?) -> Bool {
        return false
    }

    func track(trafficType: String, eventType: String, value: Double, properties: [String: Any]?) -> Bool {
        return false
    }

    func track(eventType: String, properties: [String: Any]?) -> Bool {
        return false
    }

    func track(eventType: String, value: Double, properties: [String: Any]?) -> Bool {
        return false
    }
}

class FailedManager: SplitManager {
    var splits: [SplitView] = []

    var splitNames: [String] = []

    func split(featureName: String) -> SplitView? {
        return nil
    }
}
