//
//  FailHelpers.swift
//  Split
//
//  Created by Javier Avrudsky on 24-Apr-2022.
//  Copyright © 2022 Split. All rights reserved.

import Foundation

/// To avoid crashing host app this dummy components will be returned
/// on Failed init
///

class FailedClient: SplitClient {

    func getTreatment(_ split: String) -> String {
        SplitConstants.control
    }

    func getTreatment(_ split: String, attributes: [String: Any]?) -> String {
        getTreatment("")
    }
    
    func getTreatment(_ split: String, attributes: [String: Any]?, evaluationOptions: EvaluationOptions?) -> String {
        getTreatment("")
    }

    func getTreatments(splits: [String], attributes: [String: Any]?) -> [String: String] {
        [:]
    }

    func getTreatments(splits: [String], attributes: [String: Any]?, evaluationOptions: EvaluationOptions?) -> [String: String] {
        [:]
    }

    func getTreatmentWithConfig(_ split: String) -> SplitResult {
        SplitResult(treatment: SplitConstants.control)
    }

    func getTreatmentWithConfig(_ split: String, attributes: [String: Any]?) -> SplitResult {
        getTreatmentWithConfig("")
    }

    func getTreatmentWithConfig(_ split: String, attributes: [String: Any]?, evaluationOptions: EvaluationOptions?) -> SplitResult {
        getTreatmentWithConfig("")
    }

    func getTreatmentsWithConfig(splits: [String], attributes: [String: Any]?) -> [String: SplitResult] {
        [:]
    }
    
    func getTreatmentsWithConfig(splits: [String], attributes: [String: Any]?, evaluationOptions: EvaluationOptions?) -> [String: SplitResult] {
        [:]
    }

    // MARK: Events
    func on(event: SplitEvent, execute action: @escaping SplitAction) {}

    func on(event: SplitEvent, runInBackground: Bool, execute action: @escaping SplitAction) {}

    func on(event: SplitEvent, queue: DispatchQueue, execute action: @escaping SplitAction) {}
    
    // MARK: Events Listeners with Medatadata
    var listener: (any SplitClientEventListener)?
    @objc public func addEventsListener(listener: SplitClientEventListener) {}

    // MARK: Track
    func track(trafficType: String, eventType: String) -> Bool {
        false
    }

    func track(trafficType: String, eventType: String, value: Double) -> Bool {
        false
    }

    func track(eventType: String) -> Bool {
        false
    }

    func track(eventType: String, value: Double) -> Bool {
        false
    }

    func setAttribute(name: String, value: Any) -> Bool {
        false
    }

    func getAttribute(name: String) -> Any? {
        false
    }

    func setAttributes(_ values: [String: Any]) -> Bool {
        false
    }

    func getAttributes() -> [String: Any]? {
        [:]
    }

    func removeAttribute(name: String) -> Bool {
        false
    }

    func clearAttributes() -> Bool {
        false
    }
    
    func getTreatmentsByFlagSet(_ flagSet: String, attributes: [String: Any]?) -> [String: String] {
        [:]
    }
    
    func getTreatmentsByFlagSets(_ flagSets: [String], attributes: [String: Any]?) -> [String: String] {
        [:]
    }
    
    func getTreatmentsWithConfigByFlagSet(_ flagSet: String, attributes: [String: Any]?) -> [String: SplitResult] {
        [:]
    }
    
    func getTreatmentsWithConfigByFlagSets(_ flagSets: [String], attributes: [String: Any]?) -> [String: SplitResult] {
        [:]
    }

    func getTreatmentsByFlagSet(_ flagSet: String, attributes: [String: Any]?, evaluationOptions: EvaluationOptions?) -> [String: String] {
        [:]
    }
    
    func getTreatmentsByFlagSets(_ flagSets: [String], attributes: [String: Any]?, evaluationOptions: EvaluationOptions?) -> [String: String] {
        [:]
    }
    
    func getTreatmentsWithConfigByFlagSet(_ flagSet: String, attributes: [String: Any]?, evaluationOptions: EvaluationOptions?) -> [String: SplitResult] {
        [:]
    }
    
    func getTreatmentsWithConfigByFlagSets(_ flagSets: [String], attributes: [String: Any]?, evaluationOptions: EvaluationOptions?) -> [String: SplitResult] {
        [:]
    }

    func setUserConsent(enabled: Bool) {}

    func flush() {}

    func destroy() {}

    func destroy(completion: (() -> Void)?) {
        completion?()
    }

    func track(trafficType: String, eventType: String, properties: [String: Any]?) -> Bool {
        false
    }

    func track(trafficType: String, eventType: String, value: Double, properties: [String: Any]?) -> Bool {
        false
    }

    func track(eventType: String, properties: [String: Any]?) -> Bool {
        false
    }

    func track(eventType: String, value: Double, properties: [String: Any]?) -> Bool {
        false
    }
}

class FailedManager: SplitManager {
    var splits: [SplitView] = []

    var splitNames: [String] = []

    func split(featureName: String) -> SplitView? {
        nil
    }
}
