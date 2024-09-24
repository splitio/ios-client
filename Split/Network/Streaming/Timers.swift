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
    case syncSegments
}

protocol TimersManager {
    /// Adds a task. If a task of the same name exists
    /// it is replaced
    func add(timer: TimerName, task: CancellableTask)

    /// Adds the task when not task having the same name is
    /// scheduled
    /// Returns true if the task was scheduled.
    func addNoReplace(timer: TimerName, task: CancellableTask) -> Bool

    /// Cancels the task
    func cancel(timer: TimerName)

    /// If a timer by name is scheduled
    func isScheduled(timer: TimerName) -> Bool

    /// Destroy the manager
    func destroy()
}

class DefaultTimersManager: TimersManager {
    private let timers = ConcurrentDictionary<TimerName, CancellableTask>()
    private let taskExecutor = TaskExecutor()

    func add(timer: TimerName, task: CancellableTask) {
        timers.setValue(task, forKey: timer)
        taskExecutor.run(task)
    }

    func addNoReplace(timer: TimerName, task: CancellableTask) -> Bool {
        if timers.addWithoutReplacing(task, forKey: timer) {
            taskExecutor.run(task)
            return true
        }
        return false
    }

    func cancel(timer: TimerName) {
        if let task = timers.takeValue(forKey: timer) {
            task.cancel()
        }
    }

    func isScheduled(timer: TimerName) -> Bool {
        return timers.value(forKey: timer) != nil
    }

    func destroy() {
        let all = timers.takeAll()
        all.forEach {
            $1.cancel()
        }
    }
}
