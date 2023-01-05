//
//  SplitEventExecutorWithClient.swift
//  Split
//
//  Created by Sebastian Arrubia on 4/17/18.
//

import Foundation

class SplitEventExecutorWithClient: SplitEventExecutorProtocol {

    private var task: SplitEventTask
    private var eventName: String
    private weak var client: SplitClient?

    init(task: SplitEventTask, client: SplitClient?, eventName: String = "") {
        self.task = task
        self.client = client
        self.eventName = eventName
    }

    func execute() {
        guard let splitClient = client else {
            return
        }

        DispatchQueue.global().async {
            // Background thread
            self.task.onPostExecute(client: splitClient)
            DispatchQueue.main.async {
                // UI Updates
                let startTime = Date().unixTimestampInMiliseconds()
                self.task.onPostExecuteView(client: splitClient)
                self.logInterval(from: startTime)
            }
        }
    }

    private func logInterval(from: Int64) {
        Logger.v("Time to run handler for \(eventName) event: \(Date().unixTimestampInMiliseconds() - from) ms")
    }

}
