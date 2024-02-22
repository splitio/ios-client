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

        DispatchQueue.global().async {
            TimeChecker.logTime("Running event on global: \(self.task.event?.toString())")
            self.task.onPostExecute(client: splitClient)
        }

        DispatchQueue.main.async(execute: {
            TimeChecker.logTime("Running event on main: \(self.task.event?.toString())")
            // UI Updates
            self.task.onPostExecuteView(client: splitClient)
        })
    }

}
