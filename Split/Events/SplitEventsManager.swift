//
//  EventsManager.swift
//  Split
//
//  Created by Sebastian Arrubia on 4/16/18.
//
//  Update: Replacing timer by blocking queue. 05-10-2021

import Foundation

protocol SplitEventsManager: AnyObject {
    func register(event: SplitEventWithMetadata, task: SplitEventActionTask)
    func notifyInternalEvent(_ event: SplitInternalEvent, _ metadata: [String: Any]?)
    func notifyInternalEventWithMetadata(_ event: SplitInternalEventWithMetadata)
    func start()
    func stop()
    func eventAlreadyTriggered(event: SplitEvent) -> Bool
}

/* This overload is intentionally kept for backwards compatibility.
   It allows calling `notifyInternalEvent(.event)` without needing to pass `nil` as metadata.
   Do not remove unless all usages have migrated to the new signature. */
extension SplitEventsManager {
    func notifyInternalEvent(_ event: SplitInternalEvent) {
        notifyInternalEvent(event, nil)
    }
}

class DefaultSplitEventsManager: SplitEventsManager {
    private let readingRefreshTime: Int

    private var sdkReadyTimeStart: Int64

    private var subscriptions = [SplitEvent: [SplitEventTask]]()
    private var executionTimes: [String: Int]
    private var triggered: [SplitInternalEventWithMetadata]
    private let processQueue: DispatchQueue
    private let dataAccessQueue: DispatchQueue
    private var isStarted: Bool
    private var eventsQueue: InternalEventBlockingQueue

    init(config: SplitClientConfig) {
        self.processQueue = DispatchQueue(label: "split-evt-mngr-process", attributes: .concurrent)
        self.dataAccessQueue = DispatchQueue(label: "split-evt-mngr-data", target: DispatchQueue.general)
        self.isStarted = false
        self.sdkReadyTimeStart = Date().unixTimestampInMiliseconds()
        self.readingRefreshTime = 300
        self.triggered = [SplitInternalEventWithMetadata]()
        self.eventsQueue = DefaultInternalEventBlockingQueue()
        self.executionTimes = [String: Int]()
        registerMaxAllowedExecutionTimesPerEvent()

        if config.sdkReadyTimeOut > 0 {
            let readyTimedoutQueue = DispatchQueue(label: "split-event-timedout")
            readyTimedoutQueue.asyncAfter(deadline: .now() + .milliseconds(config.sdkReadyTimeOut)) {  [weak self] in
                guard let self = self else { return }
                self.notifyInternalEvent(SplitInternalEvent.sdkReadyTimeoutReached)
            }
        }
    }
    
    func notifyInternalEvent(_ event: SplitInternalEvent, _ metadata: [String: Any]? = nil) {
        notifyInternalEventWithMetadata(SplitInternalEventWithMetadata(type: event, metadata: metadata))
    }
    
    func notifyInternalEventWithMetadata(_ event: SplitInternalEventWithMetadata) {
        processQueue.async { [weak self] in
            if let self = self {
                Logger.i("Event \(event.type) notified - Details: \(event.metadata ?? [:])")
                self.eventsQueue.add(event)
            }
        }
    }

    func register (event: SplitEventWithMetadata, task: SplitEventActionTask) {
        let eventName = event.type.toString()
        processQueue.async { [weak self] in
            guard let self = self else { return }
            // If event is already triggered, execute the task
            if let times = self.executionTimes(for: eventName), times == 0 {
                self.executeTask(eventWithMetadata: event, task: task)
                return
            }
            self.subscribe(task: task, to: event.type)
        }
    }

    func start() {
        dataAccessQueue.sync {
            if self.isStarted {
                return
            }
            self.isStarted = true
        }
        processQueue.async { [weak self] in
            if let self = self {
                self.processEvents()
            }
        }
    }

    func eventAlreadyTriggered(event: SplitEvent) -> Bool {
        var isTriggered = false
        processQueue.sync {
            isTriggered = self.isTriggered(external: event)
        }
        return isTriggered
    }

    func stop() {
        dataAccessQueue.async { [weak self] in
            guard let self = self else { return }
            self.isStarted = false
            self.subscriptions.removeAll()
            self.processQueue.sync {
                self.eventsQueue.stop()
                self.eventsQueue.stop()
            }

        }
    }

    // MARK: Private

    /**
     * This method should registering the allowed maximum times of event trigger
     * EXAMPLE: SDK_READY should be triggered only once
     */
    private func registerMaxAllowedExecutionTimesPerEvent() {

        executionTimes = [ SplitEvent.sdkReady.toString(): 1,
                           SplitEvent.sdkUpdated.toString(): -1,
                           SplitEvent.sdkReadyFromCache.toString(): 1,
                           SplitEvent.sdkReadyTimedOut.toString(): 1]
    }

    private func isRunning() -> Bool {
        var isRunning = true
        dataAccessQueue.sync {
            isRunning = self.isStarted
        }
        return isRunning
    }

    private func takeEvent() -> SplitInternalEventWithMetadata? {
        do {
            return try eventsQueue.take()
        } catch BlockingQueueError.hasBeenStopped {
            Logger.d("Events manager stoped")
        } catch {
            Logger.d("Events manager take event has exit because \(error.localizedDescription)")
        }
        return nil
    }

    private func processEvents() {
        while isRunning() {
            guard let event = takeEvent() else {
                return
            }
            self.triggered.append(event)
            switch event.type {
                case .splitsUpdated, .mySegmentsUpdated, .myLargeSegmentsUpdated:
                    if isTriggered(external: .sdkReady) {
                        trigger(event: SplitEventWithMetadata(type: .sdkUpdated, metadata: event.metadata))
                        continue
                    }
                    self.triggerSdkReadyIfNeeded()

                case .mySegmentsLoadedFromCache, .myLargeSegmentsLoadedFromCache, .splitsLoadedFromCache, .attributesLoadedFromCache:
                    Logger.v("Event \(event.type) triggered")
                    if isTriggered(internal: .splitsLoadedFromCache),
                       isTriggered(internal: .mySegmentsLoadedFromCache),
                       isTriggered(internal: .myLargeSegmentsLoadedFromCache),
                       isTriggered(internal: .attributesLoadedFromCache) {
                        trigger(event: SplitEvent.sdkReadyFromCache)
                    }
                case .splitKilledNotification:
                    if isTriggered(external: .sdkReady) {
                        trigger(event: .sdkUpdated)
                        continue
                    }
                case .sdkReadyTimeoutReached:
                    if !isTriggered(external: .sdkReady) {
                        trigger(event: SplitEvent.sdkReadyTimedOut)
                    }
                }
        }
    }

    // MARK: Helper functions.
    func isTriggered(external event: SplitEvent) -> Bool {
        var triggered = false
        dataAccessQueue.sync {
            if let times = executionTimes[event.toString()] {
                triggered =  (times == 0)
            } else {
                triggered = false
            }
        }
        return triggered
    }

    private func triggerSdkReadyIfNeeded() {
        if isTriggered(internal: .mySegmentsUpdated),
           isTriggered(internal: .splitsUpdated),
           isTriggered(internal: .myLargeSegmentsUpdated),
           !isTriggered(external: .sdkReady) {
            self.trigger(event: .sdkReady)
        }
    }
    
    private func trigger(event: SplitEvent) {
        trigger(event: SplitEventWithMetadata(type: event, metadata: nil))
    }

    private func trigger(event: SplitEventWithMetadata) {
        let eventName = event.type.toString()
        let eventMetadata = event.metadata?.debugDescription

        // If executionTimes is zero, maximum executions has been reached
        if executionTimes(for: eventName) == 0 {
            return
        }

        // If executionTimes is grater than zero, maximum executions decrease 1
        if let times = executionTimes(for: eventName), times > 0 {
            updateExecutionTimes(for: eventName, count: times - 1)
        }

        Logger.d("Triggering SDK event \(eventName)")
        // If executionTimes is lower than zero, execute it without limitation
        if let subscriptions = getSubscriptions(for: event.type) {
            for task in subscriptions {
                executeTask(eventWithMetadata: event, task: task)
            }
        }
    }

    private func executeTask(eventWithMetadata event: SplitEventWithMetadata, task: SplitEventTask) {

        let eventName = task.event.type.toString()

        if task.runInBackground {
            TimeChecker.logInterval("Previous to run \(eventName) in Background")

            let queue = task.takeQueue() ?? DispatchQueue.general
            queue.async {
                TimeChecker.logInterval("Running \(eventName) in Background queue \(queue)")
                let taskResult = task.run(event.metadata)
            }
        }

        DispatchQueue.main.async {
            TimeChecker.logInterval("Running event on main: \(eventName)")
            // UI Updates
            let taskResult = task.run(event.metadata)
        }
    }

    private func isTriggered(internal event: SplitInternalEventWithMetadata) -> Bool {
        return triggered.filter { $0 == event }.count > 0
    }
    
    private func isTriggered(internal event: SplitInternalEvent) -> Bool {
        return isTriggered(internal: SplitInternalEventWithMetadata(type: event, metadata: nil))
    }

    // MARK: Safe Data Access
    func executionTimes(for eventName: String) -> Int? {
        var times: Int?
        dataAccessQueue.sync {
            times = executionTimes[eventName]
        }
        return times
    }

    func subscribe(task: SplitEventTask, to event: SplitEvent) {
        dataAccessQueue.async { [weak self] in
            guard let self = self else { return }
            var subscriptions = self.subscriptions[event] ?? [SplitEventTask]()
            subscriptions.append(task)
            self.subscriptions[event] = subscriptions
        }
    }

    private func getSubscriptions(for event: SplitEvent) -> [SplitEventTask]? {
        var subscriptions: [SplitEventTask]?
        dataAccessQueue.sync {
            subscriptions = self.subscriptions[event]
        }
        return subscriptions
    }

    private func updateExecutionTimes(for eventName: String, count: Int) {
        dataAccessQueue.sync {
            self.executionTimes[eventName] = count
        }
    }
}
