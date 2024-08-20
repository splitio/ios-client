//
//  SplitEventsManagerWrapper.swift
//  Split
//
//  Created by Javier Avrudsky on 07/08/2024.
//  Copyright © 2024 Split. All rights reserved.
//

import Foundation

//protocol SplitEventsManagerWrapper {
//    var isSdkReady: Bool { get }
//    func notifyLoadedFromCache()
//    func notifyUpdate()
//}
//
//class BaseEventsManagerWrapper: SplitEventsManagerWrapper {
//    fileprivate weak var eventsManager: SplitEventsManager?
//    var isSdkReady: Bool {
//        return eventsManager?.eventAlreadyTriggered(event: .sdkReady) ?? false
//    }
//
//    init(_ eventsManager: SplitEventsManager) {
//        self.eventsManager = eventsManager
//    }
//
//    func notifyLoadedFromCache() {
//        Logger.e("Notify load not implementation missing")
//        fatalError()
//
//    }
//
//    func notifyUpdate() {
//        Logger.e("Notify update not implementation missing")
//        fatalError()
//    }
//}

//class SplitsEventsManagerWrapper: BaseEventsManagerWrapper {
//
//    override func notifyLoadedFromCache() {
//        eventsManager?.notifyInternalEvent(.splitsLoadedFromCache)
//    }
//
//    override func notifyUpdate() {
//        eventsManager?.notifyInternalEvent(.splitsUpdated)
//    }
//}
//
//class MySegmentsEventsManagerWrapper: BaseEventsManagerWrapper {
//
//    override func notifyLoadedFromCache() {
//        eventsManager?.notifyInternalEvent(.mySegmentsLoadedFromCache)
//    }
//
//
//    override func notifyUpdate() {
//        eventsManager?.notifyInternalEvent(.mySegmentsUpdated)
//    }
//}
//
//class MyLargeSegmentsEventsManagerWrapper: BaseEventsManagerWrapper {
//
//    override func notifyLoadedFromCache() {
//        eventsManager?.notifyInternalEvent(.myLargeSegmentsLoadedFromCache)
//    }
//
//    override func notifyUpdate() {
//        eventsManager?.notifyInternalEvent(.myLargeSegmentsUpdated)
//    }
//}
