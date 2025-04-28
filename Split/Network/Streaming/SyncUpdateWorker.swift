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

class SplitsUpdateWorker: UpdateWorker<SplitsUpdateNotification> {

    private let synchronizer: Synchronizer
    private let splitsStorage: SplitsStorage
    private let splitChangeProcessor: SplitChangeProcessor
    private let payloadDecoder: FeatureFlagsPayloadDecoder
    private let telemetryProducer: TelemetryRuntimeProducer?
    var decomProvider: CompressionProvider = DefaultDecompressionProvider()

    init(synchronizer: Synchronizer,
         splitsStorage: SplitsStorage,
         splitChangeProcessor: SplitChangeProcessor,
         featureFlagsPayloadDecoder: FeatureFlagsPayloadDecoder,
         telemetryProducer: TelemetryRuntimeProducer?) {
        self.synchronizer = synchronizer
        self.splitsStorage = splitsStorage
        self.splitChangeProcessor = splitChangeProcessor
        self.payloadDecoder = featureFlagsPayloadDecoder
        self.telemetryProducer = telemetryProducer
        super.init(queueName: "SplitsUpdateWorker")
    }

    override func process(notification: SplitsUpdateNotification) throws {
        processQueue.async { [weak self] in

            guard let self = self else { return }
            let storedChangeNumber = self.splitsStorage.changeNumber
            if storedChangeNumber >= notification.changeNumber {
                return
            }

            if let previousChangeNumber = notification.previousChangeNumber,
                previousChangeNumber == storedChangeNumber {
                if let payload = notification.definition, let compressionType = notification.compressionType {
                    do {
                        let split = try self.payloadDecoder.decode(
                            payload: payload,
                            compressionUtil: self.decomProvider.decompressor(for: compressionType))
                        let change = SplitChange(splits: [split],
                                                 since: previousChangeNumber,
                                                 till: notification.changeNumber)
                        Logger.v("Split update received: \(change)")
                        if self.splitsStorage.update(splitChange: self.splitChangeProcessor.process(change)) {
                            self.synchronizer.notifyFeatureFlagsUpdated()
                        }
                        self.telemetryProducer?.recordUpdatesFromSse(type: .splits)
                        return

                    } catch {
                        Logger.e("Error decoding feature flags payload from notification: \(error)")
                    }
                }
            }
            self.synchronizer.synchronizeSplits(changeNumber: notification.changeNumber)
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
