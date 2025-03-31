//
//  InternalSplitClientStub.swift
//  SplitTests
//
//  Created by Javier L. Avrudsky on 27/03/2019.
//  Copyright © 2019 Split. All rights reserved.
//

import Foundation
@testable import Split

class InternalSplitClientStub: InternalSplitClient {

    var splitsStorage: SplitsStorage?
    var mySegmentsStorage: MySegmentsStorage?
    var myLargeSegmentsStorage: MySegmentsStorage?

    init(splitsStorage: SplitsStorage?,
         mySegmentsStorage: MySegmentsStorage?,
         myLargeSegmentsStorage: MySegmentsStorage?) {
        self.splitsStorage = splitsStorage
        self.mySegmentsStorage = mySegmentsStorage
        self.myLargeSegmentsStorage = myLargeSegmentsStorage
    }

    func getTreatment(_ split: String, attributes: [String : Any]?) -> String {
        return ""
    }

    func getTreatment(_ split: String) -> String {
        return ""
    }
    
    func getTreatment(_ split: String, attributes: [String : Any]?, evaluationOptions: EvaluationOptions?) -> String {
        return ""
    }
    
    func getTreatments(splits: [String], attributes: [String : Any]?) -> [String : String] {
        return ["":""]
    }
    
    func getTreatments(splits: [String], attributes: [String : Any]?, evaluationOptions: EvaluationOptions?) -> [String : String] {
        return ["":""]
    }

    func getTreatmentWithConfig(_ split: String) -> SplitResult {
        return SplitResult(treatment: SplitConstants.control)
    }

    func getTreatmentWithConfig(_ split: String, attributes: [String : Any]?) -> SplitResult {
        return getTreatmentWithConfig(split)
    }
    
    func getTreatmentWithConfig(_ split: String, attributes: [String : Any]?, evaluationOptions: EvaluationOptions?) -> SplitResult {
        return getTreatmentWithConfig(split)
    }
    
    func getTreatmentsWithConfig(splits: [String], attributes: [String : Any]?) -> [String : SplitResult] {
        return ["": SplitResult(treatment: SplitConstants.control)]
    }
    
    func getTreatmentsWithConfig(splits: [String], attributes: [String : Any]?, evaluationOptions: EvaluationOptions?) -> [String : SplitResult] {
        return ["": SplitResult(treatment: SplitConstants.control)]
    }

    func getTreatmentsByFlagSet(_ flagSet: String, attributes: [String : Any]?) -> [String : String] {
        return ["":""]
    }

    func getTreatmentsByFlagSet(_ flagSet: String, attributes: [String : Any]?, evaluationOptions: EvaluationOptions?) -> [String : String] {
        return ["":""]
    }

    func getTreatmentsByFlagSets(_ flagSets: [String], attributes: [String : Any]?) -> [String : String] {
        return ["":""]
    }

    func getTreatmentsByFlagSets(_ flagSets: [String], attributes: [String : Any]?, evaluationOptions: EvaluationOptions?) -> [String : String] {
        return ["":""]
    }

    func getTreatmentsWithConfigByFlagSet(_ flagSet: String, attributes: [String : Any]?) -> [String : SplitResult] {
        return ["": SplitResult(treatment: SplitConstants.control)]
    }

    func getTreatmentsWithConfigByFlagSet(_ flagSet: String, attributes: [String : Any]?, evaluationOptions: EvaluationOptions?) -> [String : SplitResult] {
        return ["": SplitResult(treatment: SplitConstants.control)]
    }

    func getTreatmentsWithConfigByFlagSets(_ flagSets: [String], attributes: [String : Any]?) -> [String : SplitResult] {
        return ["": SplitResult(treatment: SplitConstants.control)]
    }

    func getTreatmentsWithConfigByFlagSets(_ flagSets: [String], attributes: [String : Any]?, evaluationOptions: EvaluationOptions?) -> [String : SplitResult] {
        return ["": SplitResult(treatment: SplitConstants.control)]
    }

    func on(event: SplitEvent, queue: DispatchQueue, execute action: @escaping SplitAction) {
    }

    func on(event: SplitEvent, runInBackground: Bool, execute action: @escaping SplitAction) {
    }

    func on(event: SplitEvent, execute action: @escaping SplitAction) {
    }

    func track(trafficType: String, eventType: String) -> Bool {
        return true
    }

    func track(trafficType: String, eventType: String, value: Double) -> Bool {
        return true
    }

    func track(eventType: String) -> Bool {
        return true
    }

    func track(eventType: String, value: Double) -> Bool {
        return true
    }

    func track(trafficType: String, eventType: String, properties: [String: Any]?) -> Bool {
        return true
    }

    func track(trafficType: String, eventType: String, value: Double, properties: [String: Any]?) -> Bool {
        return true
    }

    func track(eventType: String, properties: [String: Any]?) -> Bool {
        return true
    }

    func track(eventType: String, value: Double, properties: [String: Any]?) -> Bool {
        return true
    }

    func setAttribute(name: String, value: Any) -> Bool {
        return true
    }

    func getAttribute(name: String) -> Any? {
        return nil
    }

    func setAttributes(_ values: [String: Any]) -> Bool {
        return true
    }

    func getAttributes() -> [String: Any]? {
        return nil
    }

    func removeAttribute(name: String) -> Bool {
        return true
    }

    func clearAttributes() -> Bool {
        return true
    }
    
    func flush() {
    }

    func destroy() {
    }

    func destroy(completion: (() -> Void)?) {
    }

    func on(event: SplitEvent, executeTask: SplitEventTask) {

    }
}
