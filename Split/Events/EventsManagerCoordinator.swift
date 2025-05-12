//
//  EventsManagerCoordinator.swift
//  Split
//
//  Created by Javier Avrudsky on 28-Mar-2022.
//  Copyright © 2022 Split. All rights reserved.
//

import Foundation

protocol SplitEventsManagerCoordinator: SplitEventsManager {
    func add(_ manager: SplitEventsManager, forKey key: Key)
    func remove(forKey key: Key)
}

class MainSplitEventsManager: SplitEventsManagerCoordinator {
    
    private var defaultManager: SplitEventsManager?
    private var managers = [Key: SplitEventsManager]()
    private var triggered = Set<SplitEventCase>()
    private let queue = DispatchQueue(label: "split-event-manager-coordinator")
    private let eventsToHandle: Set<SplitEventCase> = Set(
        [.splitsLoadedFromCache,
        .splitsUpdated,
        .splitKilledNotification]
    )

    func notifyEvent(_ event: SplitEventCase, _ metadata: SplitKeyValue? = nil) {
        if !eventsToHandle.contains(event) {
            return
        }
        queue.async { [weak self] in
            guard let self = self else { return }

            self.triggered.insert(event)
            self.managers.forEach { _, manager in
                manager.notifyEvent(event, metadata)
            }
        }
    }

    func start() {}

    func stop() {
        queue.async { [weak self] in
            guard let self = self else { return }
            self.managers.forEach { _, manager in
                manager.stop()
            }
            self.managers.removeAll()
        }
    }

    func eventAlreadyTriggered(event: SplitEvent) -> Bool {
        return defaultManager?.eventAlreadyTriggered(event: event) ?? false
    }

    func add(_ manager: SplitEventsManager, forKey key: Key) {
        queue.sync {
            if managers.isEmpty {
                defaultManager = manager
            }
            manager.start()
            managers[key] = manager
            triggered.forEach {
                manager.notifyInternalEvent($0)
            }
        }
    }

    func remove(forKey key: Key) {
        queue.async { [weak self] in
            guard let self = self else { return }
            if let manager = self.managers.removeValue(forKey: key) {
                manager.stop()
            }
        }
    }

    func register(event: SplitEventWithMetadata, task: SplitEventActionTask) {}
}
