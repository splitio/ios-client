//
//  SplitEventActionTask.swift
//  Split
//
//  Created by Javier L. Avrudsky on 7/6/18.
//

import Foundation

public typealias SplitAction = () -> Void
public typealias SplitActionWithMetadata = (_ metadata: SplitMetadata?) -> Void

class SplitEventActionTask: SplitEventTask {

    // Private
    private var eventHandler: SplitAction?
    private var eventHandlerWithMetadata: SplitActionWithMetadata?
    private var queue: DispatchQueue?
    
    // Public
    var event: SplitEvent
    var runInBackground: Bool = false
    var factory: SplitFactory
    
    init(action: @escaping SplitActionWithMetadata, event: SplitEvent, runInBackground: Bool = false, factory: SplitFactory, queue: DispatchQueue? = nil) {
        self.eventHandlerWithMetadata = action
        self.event = event
        self.runInBackground = runInBackground
        self.queue = queue
        self.factory = factory
    }

    init(action: @escaping SplitAction, event: SplitEvent, runInBackground: Bool = false, factory: SplitFactory, queue: DispatchQueue? = nil) {
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

    func run(_ metadata: SplitMetadata?) {
        eventHandler?()
        
        if let metadata = metadata {
            eventHandlerWithMetadata?(metadata)
        }
    }
}
