//
//  EventsManager.swift
//  Split
//
//  Created by Sebastian Arrubia on 4/16/18.
//
//  Update: Replacing timer by blocking queue. 05-10-2021
//
import Foundation
import Logging

protocol SplitEventsManager: AnyObject, Sendable {
    func register(event: SplitEvent, task: SplitEventTask)
    func notifyInternalEvent(_ event: SplitInternalEvent)
    func notifyInternalEvent(_ event: SplitInternalEventWithMetadata)
    func start()
    func stop()
    func eventAlreadyTriggered(event: SplitEvent) -> Bool
}

class DefaultSplitEventsManager: SplitEventsManager, @unchecked Sendable {
    private let readingRefreshTime: Int

    private var sdkReadyTimeStart: Int64

    private var subscriptions = [SplitEvent: [SplitEventTask]]()
    private var executionTimes: [String: Int]
    private var triggered: [SplitInternalEventWithMetadata]
    private let processQueue: DispatchQueue
    private let dataAccessQueue: DispatchQueue
    private var isStarted: Bool

    init(config: SplitClientConfig) {
        self.processQueue = DispatchQueue(label: "split-evt-mngr-process")
        self.dataAccessQueue = DispatchQueue(label: "split-evt-mngr-data", target: DispatchQueue.general)
        self.isStarted = false
        self.sdkReadyTimeStart = Date().unixTimestampInMiliseconds()
        self.readingRefreshTime = 300
        self.triggered = [SplitInternalEventWithMetadata]()
        self.executionTimes = [String: Int]()
        registerMaxAllowedExecutionTimesPerEvent()

        if config.sdkReadyTimeOut > 0 {
            let readyTimedoutQueue = DispatchQueue(label: "split-event-timedout")
            readyTimedoutQueue.asyncAfter(deadline: .now() + .milliseconds(config.sdkReadyTimeOut)) {  [weak self] in
                guard let self = self else { return }
                self.notifyInternalEvent(.sdkReadyTimeoutReached)
            }
        }
    }

    func notifyInternalEvent(_ event: SplitInternalEventWithMetadata) {
        processQueue.async { [weak self] in
            guard let self = self else { return }
            Logger.v("Event \(event) notified")
            self.processEvent(event)
        }
    }
    
    func notifyInternalEvent(_ event: SplitInternalEvent) {
        notifyInternalEvent(SplitInternalEventWithMetadata(event, metadata: nil))
    }

    func register(event: SplitEvent, task: SplitEventTask) {
        let eventName = event.toString()
        processQueue.async { [weak self] in
            guard let self = self else { return }
            // If event is already triggered, execute the task
            if let times = self.executionTimes(for: eventName), times == 0 {
                self.executeTask(event: event, task: task)
                return
            }
            self.subscribe(task: task, to: event)
        }
    }

    func start() {
        dataAccessQueue.sync {
            if self.isStarted {
                return
            }
            self.isStarted = true
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

    // MARK: Here we map InternalEvents to external Events
    private func processEvent(_ event: SplitInternalEventWithMetadata) {
        guard isRunning() else { return }

        triggered.append(event)
        switch event.type {
            case .splitsUpdated, .mySegmentsUpdated, .myLargeSegmentsUpdated:
            
                // MARK: NORMAL SDK UPDATE
                if isTriggered(external: .sdkReady) {
                    trigger(event: SplitEventWithMetadata(type: .sdkUpdated, metadata: event.metadata))
                    return
                }
                
                // MARK: SDK READY
                var lastUpdateTimestamp: Int64?
                if event.type == .splitsUpdated, let timestamp = event.extra as? Int64 { // Get timestamp from splitsUpdated metadata
                    lastUpdateTimestamp = timestamp == 0 ? nil : timestamp
                }
                triggerSdkReadyIfNeeded(SdkReadyMetadata(lastUpdateTimestamp: lastUpdateTimestamp, isInitialCacheLoad: lastUpdateTimestamp == nil))

            case .mySegmentsLoadedFromCache, .myLargeSegmentsLoadedFromCache, .splitsLoadedFromCache, .attributesLoadedFromCache:
            
                Logger.v("Event \(event) triggered")
                if isTriggered(internal: .splitsLoadedFromCache),
                   isTriggered(internal: .mySegmentsLoadedFromCache),
                   isTriggered(internal: .myLargeSegmentsLoadedFromCache),
                   isTriggered(internal: .attributesLoadedFromCache) {
                    
                    // MARK: READY FROM CACHE - NOT FRESH INSTALL
                    var lastUpdateTimestamp: Int64?
                    if event.type == .splitsLoadedFromCache, let timestamp = event.extra as? Int64 { // Get timestamp from splitsLoaded metadata
                        lastUpdateTimestamp = timestamp
                    }
                    
                    trigger(event: SplitEventWithMetadata(type: .sdkReadyFromCache, metadata: SdkReadyFromCacheMetadata(lastUpdateTimestamp: lastUpdateTimestamp, isInitialCacheLoad: false)))
                }
            case .splitKilledNotification:
                // MARK: KILLED NOTIF (SDK UPDATE)
                if isTriggered(external: .sdkReady) {
                    trigger(event: SplitEventWithMetadata(type: .sdkUpdated, metadata: event.metadata))
                    return
                }
            case .sdkReadyTimeoutReached:
                // MARK: TIMEOUT
                if !isTriggered(external: .sdkReady) {
                    trigger(event: SplitEvent.sdkReadyTimedOut)
                }
            }
    }

    // MARK: Helper functions
    func isTriggered(external event: SplitEvent) -> Bool {
        var triggered = false
        dataAccessQueue.sync {
            if let times = executionTimes[event.toString()] {
                triggered = (times == 0)
            } else {
                triggered = false
            }
        }
        return triggered
    }

    private func triggerSdkReadyIfNeeded(_ metadata: SdkReadyMetadata) {
        if isTriggered(internal: .mySegmentsUpdated),
           isTriggered(internal: .splitsUpdated),
           isTriggered(internal: .myLargeSegmentsUpdated),
           !isTriggered(external: .sdkReady) {
            if !isTriggered(external: .sdkReadyFromCache) {
                
                // MARK: READY FROM CACHE - FRESH INSTALL
                trigger(event: SplitEventWithMetadata(type: .sdkReadyFromCache, metadata: SdkReadyFromCacheMetadata(lastUpdateTimestamp: nil, isInitialCacheLoad: true)))
            }
            
            self.trigger(event: SplitEventWithMetadata(type: .sdkReady, metadata: metadata))
        }
    }

    private func trigger(event: SplitEvent) {
        trigger(event: SplitEventWithMetadata(type: event, metadata: nil))
    }
    
    private func trigger(event: SplitEventWithMetadata) {
        let eventName = event.type.toString()

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
                executeTask(event: event, task: task)
            }
        }
    }

    private func executeTask(event: SplitEvent, task: SplitEventTask) {
        executeTask(event: SplitEventWithMetadata(type: event, metadata: nil), task: task)
    }

    private func executeTask(event: SplitEventWithMetadata, task: SplitEventTask) {

        let eventName = task.event.toString()

        if task.runInBackground {
            TimeChecker.logInterval("Previous to run \(eventName) in Background")

            let queue = task.takeQueue() ?? DispatchQueue.general
            queue.async {
                TimeChecker.logInterval("Running \(eventName) in Background queue \(queue)")
                task.run(event.metadata)
            }
            return
        }

        DispatchQueue.main.async {
            TimeChecker.logInterval("Running event on main: \(eventName)")
            // UI Updates
            task.run(event.metadata)
        }
    }
    
    private func isTriggered(internal event: SplitInternalEventWithMetadata) -> Bool {
        triggered.filter { $0.type == event.type }.count > 0
    }

    private func isTriggered(internal event: SplitInternalEvent) -> Bool {
        isTriggered(internal: SplitInternalEventWithMetadata(event, metadata: nil))
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
