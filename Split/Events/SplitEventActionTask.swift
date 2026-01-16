//  Created by Javier L. Avrudsky on 7/6/18

import Foundation

class SplitEventActionTask: SplitEventTask, @unchecked Sendable {

    private var eventHandler: SplitAction?
    private var eventHandlerWithMetadata: SplitActionWithMetadata<EventMetadata>?
    private var queue: DispatchQueue?
    var event: SplitEvent
    var runInBackground: Bool = false
    var factory: SplitFactory

    init<T: EventMetadata>(action: @escaping SplitActionWithMetadata<T>, event: SplitEvent, runInBackground: Bool = false, factory: SplitFactory, queue: DispatchQueue? = nil) {
        self.eventHandlerWithMetadata = { metadata in
            guard let typed = metadata as? T else {
                Logger.e("Wrong metadata type for this event (\(event.toString())).")
                return
            }
            action(typed)
        }
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

    func run(_ metadata: EventMetadata?) {
        eventHandler?()
        
        if let metadata = metadata {
            eventHandlerWithMetadata?(metadata)
        }
    }
}
