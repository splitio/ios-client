//
//  EventsManager.swift
//  Split
//
//  Created by Sebastian Arrubia on 4/16/18.
//
//  Update: Replacing timer by blocking queue. 05-10-2021

import Foundation

protocol SplitEventsManager: AnyObject {
    func register(event: SplitEvent, task: SplitEventTask)
    func notifyInternalEvent(_ event: SplitInternalEvent)
    func start()
    func stop()
    func eventAlreadyTriggered(event: SplitEvent) -> Bool
}

class DefaultSplitEventsManager: SplitEventsManager {
    private let readingRefreshTime: Int

    private var sdkReadyTimeStart: Int64

    private var subscriptions = [SplitEvent: [SplitEventTask]]()
    private var executionTimes: [String: Int]
    private var triggered: [SplitInternalEvent]
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
        self.triggered = [SplitInternalEvent]()
        self.eventsQueue = DefaultInternalEventBlockingQueue()
        self.executionTimes = [String: Int]()
        registerMaxAllowedExecutionTimesPerEvent()

        if config.sdkReadyTimeOut > 0 {
            let readyTimedoutQueue = DispatchQueue(label: "split-event-timedout")
            readyTimedoutQueue.asyncAfter(deadline: .now() + .milliseconds(config.sdkReadyTimeOut)) { [weak self] in
                guard let self = self else { return }
                self.notifyInternalEvent(SplitInternalEvent.sdkReadyTimeoutReached)
            }
        }
    }

    func notifyInternalEvent(_ event: SplitInternalEvent) {
        processQueue.async { [weak self] in
            if let self = self {
                Logger.v("Event \(event) notified")
                self.eventsQueue.add(event)
            }
        }
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
        executionTimes = [
            SplitEvent.sdkReady.toString(): 1,
            SplitEvent.sdkUpdated.toString(): -1,
            SplitEvent.sdkReadyFromCache.toString(): 1,
            SplitEvent.sdkReadyTimedOut.toString(): 1,
        ]
    }

    private func isRunning() -> Bool {
        var isRunning = true
        dataAccessQueue.sync {
            isRunning = self.isStarted
        }
        return isRunning
    }

    private func takeEvent() -> SplitInternalEvent? {
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
            triggered.append(event)
            switch event {
            case .myLargeSegmentsUpdated, .mySegmentsUpdated, .splitsUpdated:
                if isTriggered(external: .sdkReady) {
                    trigger(event: .sdkUpdated)
                    continue
                }
                triggerSdkReadyIfNeeded()

            case .attributesLoadedFromCache, .myLargeSegmentsLoadedFromCache,
                 .mySegmentsLoadedFromCache, .splitsLoadedFromCache:
                Logger.v("Event \(event) triggered")
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
                triggered = (times == 0)
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
            if !isTriggered(external: .sdkReadyFromCache) {
                trigger(event: .sdkReadyFromCache)
            }
            trigger(event: .sdkReady)
        }
    }

    private func trigger(event: SplitEvent) {
        let eventName = event.toString()

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
        if let subscriptions = getSubscriptions(for: event) {
            for task in subscriptions {
                executeTask(event: event, task: task)
            }
        }
    }

    private func executeTask(event: SplitEvent, task: SplitEventTask) {
        let eventName = task.event.toString()

        if task.runInBackground {
            TimeChecker.logInterval("Previous to run \(eventName) in Background")

            let queue = task.takeQueue() ?? DispatchQueue.general
            queue.async {
                TimeChecker.logInterval("Running \(eventName) in Background queue \(queue)")
                task.run()
            }
            return
        }

        DispatchQueue.main.async {
            TimeChecker.logInterval("Running event on main: \(eventName)")
            // UI Updates
            task.run()
        }
    }

    private func isTriggered(internal event: SplitInternalEvent) -> Bool {
        return !triggered.filter { $0 == event }.isEmpty
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
