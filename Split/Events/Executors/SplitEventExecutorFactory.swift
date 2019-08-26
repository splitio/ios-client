//
//  SplitEventExecutorFactory.swift
//  Split
//
//  Created by Sebastian Arrubia on 4/17/18.
//

import Foundation

class SplitEventExecutorFactory {
    static func factory(event: SplitEvent,
                        task: SplitEventTask,
                        resources: SplitEventExecutorResources) -> SplitEventExecutorProtocol {

        switch event {
        case .sdkReady:
            return SplitEventExecutorWithClient(task: task, client: resources.getClient())

        case .sdkReadyTimedOut:
            return SplitEventExecutorWithClient(task: task, client: resources.getClient())
        }
    }
}
