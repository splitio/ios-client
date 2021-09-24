//
//  PeriodicTaskExecutor.swift
//  Split
//
//  Created by Javier L. Avrudsky on 6/18/18.
//

import Foundation

struct PeriodicTaskExecutorConfig {
    var firstExecutionWindow: Int = 0
    var rate: Int = 10
}

typealias PeriodicTaskAction = () -> Void

protocol PeriodicTask {
    func start()
    func stop()
}

class PeriodicTaskExecutor: PeriodicTask {

    private var dispatchGroup: DispatchGroup?
    private var firstExecutionWindow: Int = 0
    private var rate: Int
    private var triggerAction: PeriodicTaskAction
    private var taskTimer: DispatchSourceTimer?

    init(dispatchGroup: DispatchGroup?,
         config: PeriodicTaskExecutorConfig,
         triggerAction: @escaping PeriodicTaskAction) {
        self.dispatchGroup = dispatchGroup
        self.rate = config.rate
        self.firstExecutionWindow = config.firstExecutionWindow
        self.triggerAction = triggerAction
    }

    func start() {
        startTask()
    }

    func stop() {
        stopTask()
    }

    private func startTask() {
        let queue = DispatchQueue(label: "split-polling-queue")
        taskTimer = DispatchSource.makeTimerSource(queue: queue)
        taskTimer?.schedule(deadline: .now() + .seconds(self.firstExecutionWindow), repeating: .seconds(self.rate))
        taskTimer?.setEventHandler { [weak self] in
            guard let strongSelf = self else {
                return
            }
            guard strongSelf.taskTimer != nil else {
                strongSelf.stopTask()
                return
            }
            strongSelf.executeTask()
        }
        taskTimer?.resume()
    }

    private func stopTask() {
        taskTimer?.cancel()
        taskTimer = nil
    }

    private func executeTask() {
        dispatchGroup?.enter()
        let queue = DispatchQueue(label: "split-event-queue")
        queue.async { [weak self] in
            guard let strongSelf = self else {
                return
            }
            strongSelf.triggerAction()
            strongSelf.dispatchGroup?.leave()
        }
    }
}
