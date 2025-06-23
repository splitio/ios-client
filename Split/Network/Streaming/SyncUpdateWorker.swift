//
//  SplitsUpdateWorker.swift
//  Split
//
//  Created by Javier L. Avrudsky on 24/08/2020.
//  Copyright © 2020 Split. All rights reserved.
//

import Foundation

///
/// Swift doesn't allow dynamic dispatch
/// when using protocols. So, using this implementation to allow easy UT creation
///
class UpdateWorker<T: NotificationTypeField> {
    let processQueue: DispatchQueue

    init(queueName: String) {
        self.processQueue = DispatchQueue(label: queueName)
    }

    func process(notification: T) throws {
        Logger.i("Method has to be overrided by child")
    }
}

class SplitsUpdateWorker: UpdateWorker<TargetingRuleUpdateNotification> {

    private let synchronizer: Synchronizer
    private let splitsStorage: SplitsStorage
    private let ruleBasedSegmentsStorage: RuleBasedSegmentsStorage
    private let splitChangeProcessor: SplitChangeProcessor
    private let ruleBasedSegmentsChangeProcessor: RuleBasedSegmentChangeProcessor
    private let payloadDecoder: DefaultFeatureFlagsPayloadDecoder
    private let ruleBasedSegmentsPayloadDecoder: DefaultRuleBasedSegmentsPayloadDecoder
    private let telemetryProducer: TelemetryRuntimeProducer?
    var decomProvider: CompressionProvider = DefaultDecompressionProvider()

    init(synchronizer: Synchronizer,
         splitsStorage: SplitsStorage,
         ruleBasedSegmentsStorage: RuleBasedSegmentsStorage,
         splitChangeProcessor: SplitChangeProcessor,
         ruleBasedSegmentsChangeProcessor: RuleBasedSegmentChangeProcessor,
         featureFlagsPayloadDecoder: DefaultFeatureFlagsPayloadDecoder,
         ruleBasedSegmentsPayloadDecoder: DefaultRuleBasedSegmentsPayloadDecoder,
         telemetryProducer: TelemetryRuntimeProducer?) {
        self.synchronizer = synchronizer
        self.splitsStorage = splitsStorage
        self.ruleBasedSegmentsStorage = ruleBasedSegmentsStorage
        self.splitChangeProcessor = splitChangeProcessor
        self.ruleBasedSegmentsChangeProcessor = ruleBasedSegmentsChangeProcessor
        self.payloadDecoder = featureFlagsPayloadDecoder
        self.ruleBasedSegmentsPayloadDecoder = ruleBasedSegmentsPayloadDecoder
        self.telemetryProducer = telemetryProducer
        super.init(queueName: "SplitsUpdateWorker")
    }

    override func process(notification: TargetingRuleUpdateNotification) throws {
        processQueue.async { [weak self] in

            guard let self = self else { return }
            let storedChangeNumber = getChangeNumber(notification.type)
            if storedChangeNumber >= notification.changeNumber {
                return
            }

            if let previousChangeNumber = notification.previousChangeNumber,
                previousChangeNumber == storedChangeNumber,
                let payload = notification.definition,
                let compressionType = notification.compressionType {

                if processTargetingRuleUpdate(notification: notification,
                                             payload: payload,
                                             compressionType: compressionType,
                                             previousChangeNumber: previousChangeNumber) {
                    return
                }
            }
            // If processing failed or there's no payload
            fetchChanges(notificationType: notification.type, changeNumber: notification.changeNumber)
        }
    }

    private func getChangeNumber(_ notificationType: NotificationType) -> Int64 {
        if notificationType == .splitUpdate {
            return splitsStorage.changeNumber
        } else if notificationType == .ruleBasedSegmentUpdate {
            return ruleBasedSegmentsStorage.changeNumber
        } else {
            return -1
        }
    }

    private func fetchChanges(notificationType: NotificationType, changeNumber: Int64) {
        if notificationType == .ruleBasedSegmentUpdate {
            synchronizer.synchronizeRuleBasedSegments(changeNumber: changeNumber)
        } else {
            synchronizer.synchronizeSplits(changeNumber: changeNumber)
        }
    }

    /// Process a targeting rule update notification and return true if successful
    private func processTargetingRuleUpdate(notification: TargetingRuleUpdateNotification,
                                           payload: String,
                                           compressionType: CompressionType,
                                           previousChangeNumber: Int64) -> Bool {

        switch notification.type {
        case .splitUpdate:
            return processSplitUpdate(payload: payload,
                                     compressionType: compressionType,
                                     previousChangeNumber: previousChangeNumber,
                                     changeNumber: notification.changeNumber)

        case .ruleBasedSegmentUpdate:
            return processRuleBasedSegmentUpdate(payload: payload,
                                               compressionType: compressionType,
                                               previousChangeNumber: previousChangeNumber,
                                               changeNumber: notification.changeNumber)

        default:
            return false
        }
    }

    /// Process a split update notification
    private func processSplitUpdate(payload: String,
                                   compressionType: CompressionType,
                                   previousChangeNumber: Int64,
                                   changeNumber: Int64) -> Bool {
        do {
            let split = try self.payloadDecoder.decode(
                payload: payload,
                compressionUtil: self.decomProvider.decompressor(for: compressionType))

            if !allRuleBasedSegmentsExist(in: split) {
                return false
            }

            let change = SplitChange(splits: [split],
                                     since: previousChangeNumber,
                                     till: changeNumber)

            Logger.v("Split update received: \(change)")

            let processedFlags = self.splitChangeProcessor.process(change)

           if self.splitsStorage.update(splitChange: processedFlags) {
               var updatedFlags: [String] = processedFlags.activeSplits.compactMap(\.name)
               updatedFlags += processedFlags.archivedSplits.compactMap(\.name)
               self.synchronizer.notifyFeatureFlagsUpdated(flagsList: updatedFlags)

            }

            self.telemetryProducer?.recordUpdatesFromSse(type: .splits)
            return true
        } catch {
            Logger.e("Error decoding feature flags payload from notification: \(error)")
            return false
        }
    }

    /// Process a rule-based segment update notification
    private func processRuleBasedSegmentUpdate(payload: String,
                                             compressionType: CompressionType,
                                             previousChangeNumber: Int64,
                                             changeNumber: Int64) -> Bool {
        do {
            let rbs = try self.ruleBasedSegmentsPayloadDecoder.decode(
                payload: payload,
                compressionUtil: self.decomProvider.decompressor(for: compressionType))

            let change = RuleBasedSegmentChange(segments: [rbs],
                                             since: previousChangeNumber,
                                             till: changeNumber)

            Logger.v("RBS update received: \(change)")

            let processedChange = ruleBasedSegmentsChangeProcessor.process(change)

            if self.ruleBasedSegmentsStorage.update(toAdd: processedChange.toAdd,
                                                  toRemove: processedChange.toRemove,
                                                  changeNumber: processedChange.changeNumber) {
                self.synchronizer.notifyFeatureFlagsUpdated(flagsList: []) //TODO: RBS Update
            }

            self.telemetryProducer?.recordUpdatesFromSse(type: .splits)
            return true
        } catch {
            Logger.e("Error decoding rule based segments payload from notification: \(error)")
            return false
        }
    }

    /// Checks if the split contains a rule-based segment matcher whose segment does not exist in storage
    private func allRuleBasedSegmentsExist(in split: Split) -> Bool {
        guard let conditions = split.conditions else { return true }
        let segmentNames = conditions
            .compactMap { $0.matcherGroup?.matchers }
            .flatMap { $0 }
            .filter { $0.matcherType == .inRuleBasedSegment }
            .compactMap { $0.userDefinedSegmentMatcherData?.segmentName }

        guard !segmentNames.isEmpty else {
            return true
        }
        return segmentNames.allSatisfy {
            self.ruleBasedSegmentsStorage.get(segmentName: $0) != nil
        }
    }
}

class SplitKillWorker: UpdateWorker<SplitKillNotification> {

    private let synchronizer: Synchronizer
    private let splitsStorage: SplitsStorage

    init(synchronizer: Synchronizer, splitsStorage: SplitsStorage) {
        self.synchronizer = synchronizer
        self.splitsStorage = splitsStorage
        super.init(queueName: "SplitKillWorker")
    }

    override func process(notification: SplitKillNotification) throws {
        processQueue.async {
            self.process(notification)
        }
    }

    private func process(_ notification: SplitKillNotification) {
        if let splitToKill = splitsStorage.get(name: notification.splitName) {
            if splitToKill.changeNumber ?? -1 < notification.changeNumber {
                splitToKill.defaultTreatment = notification.defaultTreatment
                splitToKill.changeNumber = notification.changeNumber
                splitToKill.killed = true
                splitsStorage.updateWithoutChecks(split: splitToKill)
                synchronizer.notifySplitKilled()
            }
        }
        synchronizer.synchronizeSplits(changeNumber: notification.changeNumber)
    }
}

protocol CompressionProvider {
    func decompressor(for type: CompressionType) -> CompressionUtil
}

struct DefaultDecompressionProvider: CompressionProvider {
    private let zlib: CompressionUtil = Zlib()
    private let gzip: CompressionUtil = Gzip()
    private let compressionNone: CompressionUtil = CompressionNone()

    func decompressor(for type: CompressionType) -> CompressionUtil {
        switch type {
        case .gzip:
            return gzip
        case.zlib:
            return zlib
        default:
            return compressionNone
        }
    }
}
