//
//  SplitManager.swift
//  Split
//
//  Created by Brian Sztamfater on 27/9/17.
//
//

import Foundation

///
/// Default implementation of SplitManager protocol
///
@objc public class DefaultSplitManager: NSObject, SplitManager {
    private let splitsStorage: SplitsStorage
    private let splitValidator: SplitValidator
    private let validationLogger: ValidationMessageLogger
    private var isManagerDestroyed = Atomic(false)

    init(splitsStorage: SplitsStorage) {
        self.splitsStorage = splitsStorage
        self.splitValidator = DefaultSplitValidator(splitsStorage: splitsStorage)
        self.validationLogger = DefaultValidationMessageLogger()
        super.init()
    }

    public var splits: [SplitView] {
        if checkAndLogIfDestroyed(logTag: "splits") {
            return [SplitView]()
        }

        let splits = splitsStorage.getAll().values

        return splits.filter { $0.status == .active }
            .map { split in
                let splitView = SplitView()
                splitView.name = split.name
                splitView.changeNumber = split.changeNumber
                splitView.trafficType = split.trafficTypeName
                splitView.defaultTreatment = split.defaultTreatment
                splitView.killed = split.killed
                splitView.sets = Array(split.sets ?? [])
                splitView.configs = split.configurations ?? [String: String]()
                splitView.impressionsDisabled = split.impressionsDisabled ?? false

                if let conditions = split.conditions {
                    var treatments = Set<String>()
                    conditions.forEach { condition in
                        if let partitions = condition.partitions {
                            partitions.forEach { partition in
                                if let treatment = partition.treatment {
                                    treatments.insert(treatment)
                                }
                            }
                        }
                    }
                    if !treatments.isEmpty {
                        splitView.treatments = Array(treatments)
                    }
                }
                return splitView
            }
    }

    public var splitNames: [String] {
        if checkAndLogIfDestroyed(logTag: "splitNames") {
            return [String]()
        }

        return splits.compactMap { $0.name }
    }

    public func split(featureName: String) -> SplitView? {
        let logTag = "split"

        if checkAndLogIfDestroyed(logTag: logTag) {
            return nil
        }

        if let errorInfo = splitValidator.validate(name: featureName) {
            validationLogger.log(errorInfo: errorInfo, tag: logTag)
            if errorInfo.isError {
                return nil
            }
        }

        if let errorInfo = splitValidator.validateSplit(name: featureName) {
            validationLogger.log(errorInfo: errorInfo, tag: logTag)
            if errorInfo.isError || errorInfo.hasWarning(.nonExistingSplit) {
                return nil
            }
        }

        let splitName = featureName.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        let filtered = splits.filter { (splitName == $0.name?.lowercased()) }
        return !filtered.isEmpty ? filtered[0] : nil
    }
}

extension DefaultSplitManager: Destroyable {
    func checkAndLogIfDestroyed(logTag: String) -> Bool {
        if isManagerDestroyed.value {
            validationLogger.e(message: "Manager has already been destroyed - no calls possible", tag: logTag)
        }
        return isManagerDestroyed.value
    }

    func destroy() {
        isManagerDestroyed.set(true)
    }
}
