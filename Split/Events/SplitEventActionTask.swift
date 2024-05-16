//
//  SplitEventActionTask.swift
//  Split
//
//  Created by Javier L. Avrudsky on 7/6/18.
//

import Foundation

class SplitEventActionTask: SplitEventTask {

    private var eventHandler: SplitAction?
    private var queue: DispatchQueue?
    var event: SplitEvent
    var runInBackground: Bool = false
    var factory: SplitFactory

    init(action: @escaping SplitAction,
         event: SplitEvent,
         runInBackground: Bool = false,
         factory: SplitFactory,
         queue: DispatchQueue? = nil) {

        self.eventHandler = action
        self.event = event
        self.runInBackground = runInBackground
        self.queue = queue
        self.factory = factory
    }

    func takeQueue() -> DispatchQueue? {
        defer { queue = nil }
        return queue
    }

    func run() {
        eventHandler?()
    }
}
