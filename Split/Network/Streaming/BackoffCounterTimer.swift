//
//  BackoffCounterTimer.swift
//  Split
//
//  Created by Javier L. Avrudsky on 20/10/2020.
//  Copyright © 2020 Split. All rights reserved.
//

import Foundation

protocol BackoffCounterTimer {
    func schedule(handler: @escaping () -> Void)
    func cancel()
}

class DefaultBackoffCounterTimer: BackoffCounterTimer {
    private let reconnectBackoffCounter: ReconnectBackoffCounter
    private let timersQueue = DispatchQueue.global()
    private var workItem: DispatchWorkItem?
    private var isScheduled: Atomic<Bool> = Atomic(false)

    init(reconnectBackoffCounter: ReconnectBackoffCounter) {
        self.reconnectBackoffCounter = reconnectBackoffCounter
    }

    func schedule(handler: @escaping () -> Void) {
        if workItem != nil, isScheduled.getAndSet(true) {
            return
        }

        let workItem = DispatchWorkItem(block: {
            handler()
            self.isScheduled.set(false)
        })
        let delayInSeconds = reconnectBackoffCounter.getNextRetryTime()
        Logger.d("Retrying reconnection in \(delayInSeconds) seconds")
        timersQueue.asyncAfter(deadline: DispatchTime.now() + Double(delayInSeconds), execute: workItem)
        self.workItem = workItem
    }

    func cancel() {
        workItem?.cancel()
        workItem = nil
        reconnectBackoffCounter.resetCounter()
    }
}
