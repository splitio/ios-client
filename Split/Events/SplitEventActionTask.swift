//
//  SplitEventActionTask.swift
//  Split
//
//  Created by Javier L. Avrudsky on 7/6/18.
//

import Foundation

class SplitEventActionTask: SplitEventTask {

    private var eventHandler: SplitAction?
    private var eventHandlerWithArguments: SplitActionWithArguments?
    private var queue: DispatchQueue?
    var event: SplitEventWithMetadata
    var runInBackground: Bool = false
    var factory: SplitFactory

    #warning("Should we use two inits here?")
    init(action: @escaping SplitAction, event: SplitEventWithMetadata, runInBackground: Bool = false, factory: SplitFactory, queue: DispatchQueue? = nil) {

        self.eventHandler = action
        self.eventHandlerWithArguments = nil
        self.event = event
        self.runInBackground = runInBackground
        self.queue = queue
        self.factory = factory
    }
    
    init(action: @escaping SplitActionWithArguments, event: SplitEventWithMetadata, runInBackground: Bool = false, factory: SplitFactory, queue: DispatchQueue? = nil) {

        self.eventHandler = nil
        self.eventHandlerWithArguments = action
        self.event = event
        self.runInBackground = runInBackground
        self.queue = queue
        self.factory = factory
    }

    func takeQueue() -> DispatchQueue? {
        defer { queue = nil }
        return queue
    }

    func run(_ data: Any?) -> Void {
        if let data = data {
            eventHandlerWithArguments?(data)
        } else {
            eventHandler?()
        }
    }
}
