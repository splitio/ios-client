//
//  SplitEventExecutorWithClient.swift
//  Split
//
//  Created by Sebastian Arrubia on 4/17/18.
//

import Foundation

class SplitEventExecutorWithClient: SplitEventExecutorProtocol {

    private var task: SplitEventTask
    private var runQueue: DispatchQueue?
    private weak var client: SplitClient?

    init(task: SplitEventTask, client: SplitClient?) {
        self.task = task
        self.runQueue = task.takeQueue()
        self.client = client
    }

    func execute() {
        guard let splitClient = client else {
            return
        }
        let eventName = task.event.toString()

        if task.runInBackground {
            let queue = self.runQueue ?? DispatchQueue.general
            queue.async { [weak self] in
                guard let self = self else { return }
                TimeChecker.logInterval("Running event on general: \(eventName)")
                self.task.run()
            }
            return
        }

        DispatchQueue.main.async {
            TimeChecker.logInterval("Running event on main: \(eventName)")
            // UI Updates
            self.task.run()
        }
    }

}
