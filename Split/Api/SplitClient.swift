//
//  SplitClient.swift
//  Split
//
//  Created by Brian Sztamfater on 18/9/17.
//
//

import Foundation

public typealias SplitAction = () -> Void

@objc public protocol SplitClient {

    // MARK: Evaluation feature
    func getTreatment(_ split: String, attributes: [String: Any]?) -> String
    func getTreatment(_ split: String) -> String
    @objc(getTreatmentsForSplits:attributes:) func getTreatments(splits: [String],
                                                                 attributes: [String: Any]?) -> [String: String]

    func getTreatmentWithConfig(_ split: String) -> SplitResult
    func getTreatmentWithConfig(_ split: String, attributes: [String: Any]?) -> SplitResult

    @objc(getTreatmentsWithConfigForSplits:attributes:)
    func getTreatmentsWithConfig(splits: [String], attributes: [String: Any]?) -> [String: SplitResult]

    func on(event: SplitEvent, execute action: @escaping SplitAction)

    // MARK: Track feature
    func track(trafficType: String, eventType: String) -> Bool
    func track(trafficType: String, eventType: String, value: Double) -> Bool
    func track(eventType: String) -> Bool
    func track(eventType: String, value: Double) -> Bool

    // MARK: Persistent attributes feature

    /// Creates or updates the value for the given attribute
    func setAttribute(name: String, value: Any) -> Bool

    /// Retrieves the value of a given attribute so it can be checked by the customer if needed
    func getAttribute(name: String) -> Any?

    /// It will create or update all the given attributes
    func setAttributes(_ values: [String: Any]) -> Bool

    /// Retrieve the full attributes map
    func getAttributes() -> [String: Any]?

    /// Removes a given attribute from the map
    func removeAttribute(name: String) -> Bool

    /// Clears all attributes stored in the SDK.
    func clearAttributes() -> Bool

    // MARK: Client lifecycle
    func flush()
    func destroy()
    func destroy(completion: (() -> Void)?)

    @objc(trackWithTrafficType:eventType:properties:) func track(trafficType: String,
                                                                 eventType: String,
                                                                 properties: [String: Any]?) -> Bool

    @objc(trackWithTrafficType:eventType:value:properties:) func track(trafficType: String,
                                                                       eventType: String,
                                                                       value: Double,
                                                                       properties: [String: Any]?) -> Bool

    @objc(trackWithEventType:properties:) func track(eventType: String,
                                                     properties: [String: Any]?) -> Bool

    @objc(trackWithEventType:value:properties:) func track(eventType: String,
                                                           value: Double,
                                                           properties: [String: Any]?) -> Bool

}
