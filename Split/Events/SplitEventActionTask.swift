//
//  SplitEventActionTask.swift
//  Split
//
//  Created by Javier L. Avrudsky on 7/6/18.
//

import Foundation

class SplitEventActionTask: SplitEventTask {
    
    private var eventHandler: SplitAction?
    private var eventHandlerWithMetadata: SplitActionWithMetadata?
    private var queue: DispatchQueue?
    var event: SplitEventCase
    var runInBackground: Bool = false
    var factory: SplitFactory

    init(action: @escaping SplitActionWithMetadata, event: SplitEventCase, runInBackground: Bool = false, factory: SplitFactory, queue: DispatchQueue? = nil) {
        self.eventHandlerWithMetadata = action
        self.event = event
        self.runInBackground = runInBackground
        self.queue = queue
        self.factory = factory
    }
    
    init(action: @escaping SplitAction, event: SplitEventCase, runInBackground: Bool = false, factory: SplitFactory, queue: DispatchQueue? = nil) {
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

    func run(_ data: NSDictionary?) {
        eventHandler?()
        eventHandlerWithMetadata?(data)
    }
}
