//
//  SplitEventExecutorWithClient.swift
//  Split
//
//  Created by Sebastian Arrubia on 4/17/18.
//

import Foundation

class SplitEventExecutorWithClient: SplitEventExecutorProtocol {

    private var task: SplitEventTask
    private weak var client: SplitClient?

    init(task: SplitEventTask, client: SplitClient?) {
        self.task = task
        self.client = client
    }

    func execute() {
        guard let splitClient = client else {
            return
        }
        let eventName = task.event?.toString() ?? "No name provided"
        DispatchQueue.global().async {
            TimeChecker.logInterval("Running event on global: \(eventName)")
            self.task.onPostExecute(client: splitClient)
        }

        DispatchQueue.main.async(execute: {
            TimeChecker.logInterval("Running event on main: \(eventName)")
            // UI Updates
            self.task.onPostExecuteView(client: splitClient)
        })
    }

}
