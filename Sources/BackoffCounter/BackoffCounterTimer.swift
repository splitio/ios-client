//
//  BackoffCounterTimer.swift
//  Split
//
//  Created by Javier L. Avrudsky on 20/10/2020.
//  Copyright © 2020 Split. All rights reserved.
//

import Foundation
#if !COCOAPODS
import Logging
#endif

public protocol BackoffCounterTimer {
    func schedule(handler: @escaping @Sendable () -> Void)
    func cancel()
}

public class DefaultBackoffCounterTimer: BackoffCounterTimer, @unchecked Sendable {
    private let backoffCounter: BackoffCounter
    private let queue = DispatchQueue(label: "split-backoff-timer")
    private let timersQueue = DispatchQueue.global(qos: .default)
    private var workItem: DispatchWorkItem?
    private var isScheduled: Bool = false
    private let scheduleLock = NSLock()

    public init(backoffCounter: BackoffCounter) {
        self.backoffCounter = backoffCounter
    }

    public func schedule(handler: @escaping @Sendable () -> Void) {
        queue.async {
            self.schedule(handler)
        }
    }

    public func cancel() {
        queue.async {
            self.workItem?.cancel()
            self.workItem = nil
            self.backoffCounter.resetCounter()
        }
    }

    private func schedule(_ handler: @escaping () -> Void) {
        scheduleLock.lock()
        if workItem != nil, isScheduled { scheduleLock.unlock(); return }
        isScheduled = true
        scheduleLock.unlock()

        let workItem = DispatchWorkItem(block: {
            self.scheduleLock.lock(); self.isScheduled = false; self.scheduleLock.unlock()
            handler()
        })
        let delayInSeconds = backoffCounter.getNextRetryTime()
        Logger.d("Retrying reconnection in \(delayInSeconds) seconds")
        timersQueue.asyncAfter(deadline: DispatchTime.now() + Double(delayInSeconds), execute: workItem)
        self.workItem = workItem
    }
}
