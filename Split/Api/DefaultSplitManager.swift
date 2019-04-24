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

    private let splitFetcher: SplitFetcher
    private let splitValidator: SplitValidator
    private let validationLogger: ValidationMessageLogger

    init(splitFetcher: SplitFetcher) {
        self.splitFetcher = splitFetcher
        self.splitValidator = DefaultSplitValidator()
        self.validationLogger = DefaultValidationMessageLogger()
        super.init()
    }

    public var splits: [SplitView] {
        guard let splits = splitFetcher.fetchAll() else { return [SplitView]()}

        return splits.filter { $0.status == Status.Active }
            .map { split in
                let splitView = SplitView()
                splitView.name = split.name
                splitView.changeNumber = split.changeNumber
                splitView.trafficType = split.trafficTypeName
                splitView.killed = split.killed
                splitView.configurations = split.configurations ?? [String: String]()

                if let conditions = split.conditions {
                    var treatments = Set<String>()
                    conditions.forEach { condition in
                        if let partitions = condition.partitions {
                            partitions.forEach { partition in
                                if let treatment  = partition.treatment {
                                    treatments.insert(treatment)
                                }
                            }
                        }
                    }
                    if treatments.count > 0 {
                        splitView.treatments = Array(treatments)
                    }
                }
                return splitView
        }
    }

    public var splitNames: [String] {
        return splits.compactMap { return $0.name }
    }

    public func split(featureName: String) -> SplitView? {

        if let errorInfo = splitValidator.validate(name: featureName) {
            validationLogger.log(errorInfo: errorInfo, tag: "split")
            if errorInfo.isError {
                return nil
            }
        }

        let splitName = featureName.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        let filtered = splits.filter { return ( splitName == $0.name?.lowercased() ) }
        return filtered.count > 0 ? filtered[0] : nil
    }
}
