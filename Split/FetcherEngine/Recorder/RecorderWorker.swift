//
//  RecorderWorker.swift
//  Split
//
//  Created by Javier Avrudsky on 18/12/2020.
//  Copyright © 2020 Split. All rights reserved.
//

import Foundation

protocol RecorderWorker {
    func flush()
}

protocol RecorderSyncHelper {
    associatedtype Item
    // Push an item and checks if max queue size is reached
    func pushAndCheckFlush(_ item: Item) -> Bool
    func updateAccumulator(count: Int, bytes: Int)
}

class EventsRecorderSyncHelper: RecorderSyncHelper {

    private let eventsStorage: PersistentEventsStorage
    private let accumulator: RecorderFlushChecker

    init(eventsStorage: PersistentEventsStorage,
         accumulator: RecorderFlushChecker) {
        self.eventsStorage = eventsStorage
        self.accumulator = accumulator
    }

    func pushAndCheckFlush(_ item: EventDTO) -> Bool {

        DispatchQueue.global().async {
            self.eventsStorage.push(event: item)
        }
        return accumulator.checkIfFlushIsNeeded(sizeInBytes: item.sizeInBytes)
    }

    func updateAccumulator(count: Int, bytes: Int) {
        accumulator.update(count: count, bytes: bytes)
    }
}

class ImpressionsRecorderSyncHelper: RecorderSyncHelper {

    private let impressionsStorage: PersistentImpressionsStorage
    private let accumulator: RecorderFlushChecker

    init(impressionsStorage: PersistentImpressionsStorage,
         accumulator: RecorderFlushChecker) {
        self.impressionsStorage = impressionsStorage
        self.accumulator = accumulator
    }

    func pushAndCheckFlush(_ item: Impression) -> Bool {

        DispatchQueue.global().async {
            self.impressionsStorage.push(impression: item)
        }
        return accumulator.checkIfFlushIsNeeded(sizeInBytes: ServiceConstants.estimatedImpressionSizeInBytes)
    }

    func updateAccumulator(count: Int, bytes: Int) {
        accumulator.update(count: count, bytes: bytes)
    }
}

protocol RecorderFlushChecker {
    func checkIfFlushIsNeeded(sizeInBytes: Int) -> Bool
    func update(count: Int, bytes: Int)
}

class DefaultRecorderFlushChecker: RecorderFlushChecker {

    private let maxQueueSize: Int
    private let maxQueueSizeInBytes: Int
    private var pushedCount = 0
    private var totalPushedSizeInBytes = 0
    private var queue = DispatchQueue(label: "test", target: DispatchQueue.global())

    init(maxQueueSize: Int,
         maxQueueSizeInBytes: Int) {
        self.maxQueueSize = maxQueueSize
        self.maxQueueSizeInBytes = maxQueueSizeInBytes
    }

    func checkIfFlushIsNeeded(sizeInBytes: Int) -> Bool {

        var pushCount = 0
        var pushBytes = 0
        queue.sync {
            pushCount = pushedCount
            pushBytes = totalPushedSizeInBytes
        }

        if pushCount >= maxQueueSize || pushBytes >= maxQueueSizeInBytes {
            return true
        }
        return false
    }

    func update(count: Int, bytes: Int) {
        pushedCount = count
        totalPushedSizeInBytes = bytes
    }

    private func incrementCounters() {
        queue.async {
            self.pushedCount+=1
            self.totalPushedSizeInBytes+=1
        }
    }
}
