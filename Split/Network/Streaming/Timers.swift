//
//  Timers.swift
//  Split
//
//  Created by Javier L. Avrudsky on 14/08/2020.
//  Copyright © 2020 Split. All rights reserved.
//

import Foundation

enum TimerName {
    case refreshAuthToken
    case appHostBgDisconnect
}

protocol TimersManager {
    typealias TimerHandler = (TimerName) -> Void
    var triggerHandler: TimerHandler? { get set }
    func add(timer: TimerName, delayInSeconds: Int)
    func cancel(timer: TimerName)
}

class DefaultTimersManager: TimersManager {
    private let timersQueue = DispatchQueue.global()
    private let timers = SyncDictionarySingleWrapper<TimerName, DispatchWorkItem>()

    var triggerHandler: TimerHandler?

    func add(timer: TimerName, delayInSeconds: Int) {
        let workItem = DispatchWorkItem(block: {
            self.fireHandler(timer: timer)
        })
        timers.setValue(workItem, forKey: timer)
        timersQueue.asyncAfter(deadline: DispatchTime.now() + Double(delayInSeconds), execute: workItem)
    }

    func cancel(timer: TimerName) {
        let workItem = timers.takeValue(forKey: timer)
        workItem?.cancel()
    }

    private func fireHandler(timer: TimerName) {
        if let handler = triggerHandler {
            handler(timer)
        }
    }
}

protocol DelayTimer {
    func delay(seconds: Int64) -> Bool
    func cancel()
}

class DefaultTimer: DelayTimer {

    private let timersQueue = DispatchQueue.global()
    private let queue = DispatchQueue(label: "delay-timer-queue", target: .global())
    private var timer: DispatchSourceTimer?
    private let kSseConnDelayCheckTime: Double = 0.5 // 1/2 second
    private var isCancelled = false

    func cancel() {
        queue.sync {
            timer?.cancel()
            isCancelled = true
        }
    }

    // This implementation is to allow checking
    // when the component is stopped or paused easily
    // without creating a module scoped component
    // Using sleep will involve block the whole thread
    // and is not a good idea
    // Returns false if delay was cancelled. Else returns true.
    func delay(seconds: Int64) -> Bool {
        let semaphore = DispatchSemaphore(value: 0)
        queue.sync {
            isCancelled = false
            let limit = Date().unixTimestamp() + seconds
            timer = DispatchSource.makeTimerSource(flags: .strict, queue: DispatchQueue.global())
            timer?.setEventHandler { [weak self] in
                guard let self = self else { return }
                if self.isCancelled || Date().unixTimestamp() >=  limit {
                    self.timer?.cancel()
                    semaphore.signal()
                }
            }
            timer?.schedule(deadline: .now(), repeating: kSseConnDelayCheckTime)
            timer?.resume()
        }
        semaphore.wait()
        return !isCancelled
    }
}
