//
//  SplitEventActionTask.swift
//  Split
//
//  Created by Javier L. Avrudsky on 7/6/18.
//

import Foundation

class SplitEventActionTask: SplitEventTask {

    private var eventHandler: SplitAction?
    var event: SplitEvent
    var runInBackground: Bool = false
    var queue: DispatchQueue? = nil

    init(action: @escaping SplitAction,
         event: SplitEvent,
         runInBackground: Bool = false,
         queue: DispatchQueue? = nil) {

        self.eventHandler = action
        self.event = event
        self.runInBackground = runInBackground
        self.queue = queue
    }

    func run() {
        eventHandler?()
    }
}
