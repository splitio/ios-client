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
