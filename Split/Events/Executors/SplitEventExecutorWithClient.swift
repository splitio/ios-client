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
            // Background thread
            self.task.onPostExecute(client: splitClient)
            DispatchQueue.main.async { [weak self] in
                // UI Updates
                guard let self = self else { return }
                let startTime = Date().unixTimestampInMiliseconds()
                self.task.onPostExecuteView(client: splitClient)
                self.logInterval(for: self.event.toString(), from: startTime)
            }
        }
    }

}
