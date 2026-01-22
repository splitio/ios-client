//  Created by Javier L. Avrudsky on 7/6/18

import Foundation

internal typealias SplitActionWithMetadata<T: EventMetadata> = @Sendable (T) -> ()

class SplitEventActionTask: SplitEventTask, @unchecked Sendable {

    private var eventHandler: SplitAction?
    private var eventHandlerWithMetadata: EventMetadataHandler?
    private var queue: DispatchQueue?
    var event: SplitEvent
    var runInBackground: Bool = false
    var factory: SplitFactory

    init<T: EventMetadata>(action: @escaping SplitActionWithMetadata<T>, event: SplitEvent, runInBackground: Bool = false, factory: SplitFactory, queue: DispatchQueue? = nil) {
        
        self.event = event
        self.runInBackground = runInBackground
        self.queue = queue
        self.factory = factory
        
        // Preserve the concrete type using type erasure container
        self.eventHandlerWithMetadata = TypedEventMetadataHandler(action: action)
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
            eventHandlerWithMetadata?.execute(metadata)
        }
    }
}

// MARK: This below is used to preserve the concrete type of the event, since the pipeline uses the erased type.
// Type erasure container to preserve concrete type information
private protocol EventMetadataHandler: Sendable {
    func execute(_ metadata: EventMetadata)
}

private struct TypedEventMetadataHandler<T: EventMetadata>: EventMetadataHandler {
    let action: SplitActionWithMetadata<T>
    
    func execute(_ metadata: EventMetadata) {
        guard let typed = metadata as? T else {
            Logger.e("Wrong metadata type for event handler. Expected \(T.self), got \(type(of: metadata)).")
            return
        }
        action(typed)
    }
}
