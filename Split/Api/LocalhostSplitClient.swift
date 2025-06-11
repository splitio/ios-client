//
//  LocalhostSplitClient.swift
//  Split
//
//  Created by Javier L. Avrudsky on 14/02/2019.
//  Copyright © 2019 Split. All rights reserved.
//

import Foundation

///
/// Split Client protocol implementation for Locahost mode
/// This mode is intended to use for development purposes.
///
/// This implementation loads a local file called localhost.splits
/// which has the follwing line format: SPLIT TREATMENT
/// Also you can include comments to the file starting a line with the # character
///
/// - Example: A simple `localhost.splits` file
/// `# This line is a comment`\
/// `# Following line has split = FEATURE_ONE and treatment = ON`\
/// `FEATURE_ONE ON`\
/// `FEATURE_TWO OFF`\
/// `# Previous line has split = FEATURE_TWO, treatment = OFF`\
///
///
/// If a file called **localhost.splits** is included into the project bundle,
/// it will be used as initial file. It will be copied to the cache folder, then
/// it can be edited while app is running to simulate split changes.
/// When no `localhost.splits` is added to the app bundle, an empty file will be
/// created in cache folder.
/// Enable debug mode, the **localhost.splits** file location will be logged
/// to the console so that is possible to open it with a text editor when working
/// on the simulator.
/// When using the device to run the app, the file can be modified by
/// overwritting the app's bundle from the **Device and Simulators** tool.
///
///
/// For more information
///  - see also:
/// [Split iOS SDK](https://docs.split.io/docs/ios-sdk-overview#section-localhost)
///

public final class LocalhostSplitClient: NSObject, SplitClient {

    private let splitsStorage: SplitsStorage
    private let mySegmentsStorage = EmptyMySegmentsStorage()

    private let eventsManager: SplitEventsManager?
    private var evaluator: Evaluator
    private let key: Key
    weak var clientManger: SplitClientManager?

    init(key: Key, splitsStorage: SplitsStorage,
         clientManager: SplitClientManager?,
         eventsManager: SplitEventsManager? = nil,
         evaluator: Evaluator) {
        self.eventsManager = eventsManager
        self.key = key
        self.splitsStorage = splitsStorage
        self.clientManger = clientManager

        self.evaluator = evaluator
        super.init()
    }

    public func getTreatment(_ split: String, attributes: [String: Any]?) -> String {
        return getTreatmentWithConfig(split).treatment
    }

    public func getTreatment(_ split: String) -> String {
        return getTreatment(split, attributes: nil)
    }
    
    public func getTreatment(_ split: String, attributes: [String: Any]?, evaluationOptions: EvaluationOptions?) -> String {
        return getTreatmentWithConfig(split, attributes: attributes, evaluationOptions: evaluationOptions).treatment
    }

    public func getTreatments(splits: [String], attributes: [String: Any]?) -> [String: String] {
        return getTreatmentsWithConfig(splits: splits, attributes: nil).mapValues({ $0.treatment })
    }
    
    public func getTreatments(splits: [String], attributes: [String: Any]?, evaluationOptions: EvaluationOptions?) -> [String: String] {
        return getTreatmentsWithConfig(splits: splits, attributes: attributes, evaluationOptions: evaluationOptions).mapValues({ $0.treatment })
    }

    public func getTreatmentWithConfig(_ split: String) -> SplitResult {
        return getTreatmentWithConfig(split, attributes: nil)
    }

    public func getTreatmentWithConfig(_ split: String, attributes: [String: Any]?) -> SplitResult {
        var result: EvaluationResult?
        do {
            result = try evaluator.evalTreatment(matchingKey: key.matchingKey,
                                                 bucketingKey: key.bucketingKey,
                                                 splitName: split,
                                                 attributes: nil)
        } catch {
            return SplitResult(treatment: SplitConstants.control)
        }
        return SplitResult(treatment: result!.treatment, config: result!.configuration)
    }
    
    public func getTreatmentWithConfig(_ split: String, attributes: [String: Any]?, evaluationOptions: EvaluationOptions?) -> SplitResult {
        return getTreatmentWithConfig(split, attributes: attributes)
    }

    public func getTreatmentsWithConfig(splits: [String], attributes: [String: Any]?) -> [String: SplitResult] {
        var results = [String: SplitResult]()
        for split in splits {
            results[split] = getTreatmentWithConfig(split, attributes: attributes)
        }
        return results
    }
    
    public func getTreatmentsWithConfig(splits: [String], attributes: [String: Any]?, evaluationOptions: EvaluationOptions?) -> [String: SplitResult] {
        var results = [String: SplitResult]()
        for split in splits {
            results[split] = getTreatmentWithConfig(split, attributes: attributes, evaluationOptions: evaluationOptions)
        }
        return results
    }

    public func on(event: SplitEvent, execute action: @escaping SplitAction) {
        on(event: event, runInBackground: false, queue: nil, execute: action)
    }

    public func on(event: SplitEvent, executeWithMetadata: @escaping SplitActionWithMetadata) {
        on(eventWithMetadata: SplitEventWithMetadata(type: event, metadata: nil), runInBackground: false, queue: nil, execute: executeWithMetadata)
    }

    public func on(event: SplitEvent, runInBackground: Bool, execute action: @escaping SplitAction) {
        on(event: event, runInBackground: runInBackground, queue: nil, execute: action)
    }
    
    private func on(event: SplitEvent, runInBackground: Bool, queue: DispatchQueue?, execute action: @escaping SplitAction) {
        on(eventWithMetadata: SplitEventWithMetadata(type: event, metadata: nil), runInBackground: runInBackground, queue: queue, execute: action)
    }

    public func on(event: SplitEvent, queue: DispatchQueue, execute action: @escaping SplitAction) {
        on(event: event, runInBackground: true, queue: queue, execute: action)
    }

    private func on(eventWithMetadata event: SplitEventWithMetadata, runInBackground: Bool, queue: DispatchQueue?, execute action: @escaping SplitAction) {

        guard let factory = clientManger?.splitFactory else { return }
        if let eventsManager = self.eventsManager {
            let task = SplitEventActionTask(action: action, event: event.type,
                                            runInBackground: runInBackground,
                                            factory: factory,
                                            queue: queue)
            eventsManager.register(event: event, task: task)
        }
    }

    private func on(eventWithMetadata event: SplitEventWithMetadata, runInBackground: Bool, queue: DispatchQueue?, execute action: @escaping SplitActionWithMetadata) {

        guard let factory = clientManger?.splitFactory else { return }
        if let eventsManager = self.eventsManager {
            let task = SplitEventActionTask(action: action, event: event.type,
                                            runInBackground: runInBackground,
                                            factory: factory,
                                            queue: queue)
            eventsManager.register(event: event, task: task)
        }
    }

    public func track(trafficType: String, eventType: String) -> Bool {
        return true
    }

    public func track(trafficType: String, eventType: String, value: Double) -> Bool {
        return true
    }

    public func track(eventType: String) -> Bool {
        return true
    }

    public func track(eventType: String, value: Double) -> Bool {
        return true
    }

    public func track(trafficType: String, eventType: String, properties: [String: Any]?) -> Bool {
        return true
    }

    public func track(trafficType: String, eventType: String, value: Double, properties: [String: Any]?) -> Bool {
        return true
    }

    public func track(eventType: String, properties: [String: Any]?) -> Bool {
        return true
    }

    public func track(eventType: String, value: Double, properties: [String: Any]?) -> Bool {
        return true
    }

    public func setUserConsent(enabled: Bool) {
    }

    public func flush() {
    }

    public func destroy() {
        splitsStorage.destroy()
        mySegmentsStorage.destroy()
    }

    public func destroy(completion: (() -> Void)?) {
        completion?()
    }
}

// MARK: Persistent attributes feature
extension LocalhostSplitClient {

    public func setAttribute(name: String, value: Any) -> Bool {
        return true
    }

    public func getAttribute(name: String) -> Any? {
        return nil
    }

    public func setAttributes(_ values: [String: Any]) -> Bool {
        return true
    }

    public func getAttributes() -> [String: Any]? {
        return nil
    }

    public func removeAttribute(name: String) -> Bool {
        return true
    }

    public func clearAttributes() -> Bool {
        return true
    }
}

// MARK: TreatmentBySets Feature
extension LocalhostSplitClient {
    public func getTreatmentsByFlagSet(_ flagSet: String, attributes: [String: Any]?) -> [String: String] {
        return [String: String]()
    }

    public func getTreatmentsByFlagSets(_ flagSets: [String], attributes: [String: Any]?) -> [String: String] {
        return [String: String]()
    }

    public func getTreatmentsWithConfigByFlagSet(_ flagSet: String, attributes: [String: Any]?) -> [String: SplitResult] {
        return [String: SplitResult]()
    }

    public func getTreatmentsWithConfigByFlagSets(_ flagSets: [String], attributes: [String: Any]?) -> [String: SplitResult] {
        return [String: SplitResult]()
    }

    public func getTreatmentsByFlagSet(_ flagSet: String, attributes: [String: Any]?, evaluationOptions: EvaluationOptions?) -> [String: String] {
        return [String: String]()
    }

    public func getTreatmentsByFlagSets(_ flagSets: [String], attributes: [String: Any]?, evaluationOptions: EvaluationOptions?) -> [String: String] {
        return [String: String]()
    }

    public func getTreatmentsWithConfigByFlagSet(_ flagSet: String,
                                                 attributes: [String: Any]?, evaluationOptions: EvaluationOptions?) -> [String: SplitResult] {
        return [String: SplitResult]()
    }

    public func getTreatmentsWithConfigByFlagSets(_ flagSets: [String],
                                                  attributes: [String: Any]?, evaluationOptions: EvaluationOptions?) -> [String: SplitResult] {
        return [String: SplitResult]()
    }
}
