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
        return SplitEventExecutorWithClient(task: task, client: resources.client)
    }
}
