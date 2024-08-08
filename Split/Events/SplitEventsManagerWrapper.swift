//
//  SplitEventsManagerWrapper.swift
//  Split
//
//  Created by Javier Avrudsky on 07/08/2024.
//  Copyright © 2024 Split. All rights reserved.
//

import Foundation

protocol SplitEventsManagerWrapper {
    var isSdkReady: Bool { get }
    func notifyUpdate()
}

class BaseEventsManagerWrapper: SplitEventsManagerWrapper {
    fileprivate weak var eventsManager: SplitEventsManager?
    var isSdkReady: Bool {
        return eventsManager?.eventAlreadyTriggered(event: .sdkReady) ?? false
    }

    init(_ eventsManager: SplitEventsManager) {
        self.eventsManager = eventsManager
    }

    func notifyUpdate() {
        Logger.e("Notify update not implementation missing")
        fatalError()
    }
}

class SplitsEventsManagerWrapper: BaseEventsManagerWrapper {

    override func notifyUpdate() {
        eventsManager?.notifyInternalEvent(.splitsUpdated)
    }
}

class MySegmentsEventsManagerWrapper: BaseEventsManagerWrapper {

    override func notifyUpdate() {
        eventsManager?.notifyInternalEvent(.mySegmentsUpdated)
    }
}

class MyLargeSegmentsEventsManagerWrapper: BaseEventsManagerWrapper {

    override func notifyUpdate() {
        eventsManager?.notifyInternalEvent(.myLargeSegmentsUpdated)
    }
}
