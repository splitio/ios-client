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
    case streamingDelay
}

protocol TimersManager {
    func add(timer: TimerName, task: CancellableTask)
    func cancel(timer: TimerName)
    func destroy()
}

class DefaultTimersManager: TimersManager {
    private let timers = ConcurrentDictionary<TimerName, CancellableTask>()
    private let taskExecutor = TaskExecutor()

    func add(timer: TimerName, task: CancellableTask) {
        timers.setValue(task, forKey: timer)
        taskExecutor.run(task)
    }

    func cancel(timer: TimerName) {
        if let task = timers.takeValue(forKey: timer) {
            task.cancel()
        }
    }

    func destroy() {
        let all = timers.takeAll()
        all.forEach {
            $1.cancel()
        }
    }
}
