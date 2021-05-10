//
//  EventsManager.swift
//  Split
//
//  Created by Sebastian Arrubia on 4/16/18.
//
//  Update: Replacing timer by blocking queue. 05-10-2021

import Foundation

protocol SplitEventsManager {
    var executorResources: SplitEventExecutorResources { get }
    func notifyInternalEvent(_ event: SplitInternalEvent)
    func register(event: SplitEvent, task: SplitEventTask)
    func start()
    func stop()
    func eventAlreadyTriggered(event: SplitEvent) -> Bool
}

class DefaultSplitEventsManager: SplitEventsManager {
    let executorResources: SplitEventExecutorResources
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
        self.dataAccessQueue = DispatchQueue(label: "split-evt-mngr-data", target: .global())
        self.isStarted = false
        self.sdkReadyTimeStart = Date().unixTimestampInMiliseconds()
        self.readingRefreshTime = 300
        self.triggered = [SplitInternalEvent]()
        self.eventsQueue = DefaultInternalEventBlockingQueue()
        self.executorResources = SplitEventExecutorResources()
        self.executionTimes = [String: Int]()
        registerMaxAllowedExecutionTimesPerEvent()

        if config.sdkReadyTimeOut > 0 {
            let readyTimedoutQueue = DispatchQueue(label: "io.Split.Event.TimedOut")
            readyTimedoutQueue.asyncAfter(deadline: .now() + .milliseconds(config.sdkReadyTimeOut), execute: {
                self.notifyInternalEvent(SplitInternalEvent.sdkReadyTimeoutReached)
            })
        }
    }

    func notifyInternalEvent(_ event: SplitInternalEvent) {
        processQueue.async {
            self.eventsQueue.add(event)
        }
    }

    func register(event: SplitEvent, task: SplitEventTask) {
        let eventName = event.toString()
        processQueue.async {
            // If event is already triggered, execute the task
            if let times = self.executionTimes(for: eventName), times == 0 {
                self.executeTask(event: event, task: task)
                return
            }
            self.subscribe(task: task, to: event)
        }
    }

    func start() {
        processQueue.sync {
            if self.isStarted {
                return
            }
            self.isStarted = true
        }
        processQueue.async {
            self.processEvents()
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
        processQueue.sync {
            self.isStarted = false
            self.eventsQueue.interrupt()
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

    private func takeEvent() -> SplitInternalEvent? {
        do {
            return try eventsQueue.take()
        } catch BlockingQueueError.hasBeenInterrupted {
            Logger.d("Events manager stoped")
        } catch {
            Logger.e("Events manager error: \(error.localizedDescription)")
        }
        return nil
    }

    private func processEvents() {
        while isStarted {
            guard let event = takeEvent() else {
                return
            }
            self.triggered.append(event)
            switch event {
            case .splitsUpdated, .mySegmentsUpdated:
                if isTriggered(external: .sdkReady) {
                    trigger(event: .sdkUpdated)
                    return
                }
                self.triggerSdkReadyIfNeeded()

            case .mySegmentsLoadedFromCache, .splitsLoadedFromCache:
                if isTriggered(internal: .splitsLoadedFromCache), isTriggered(internal: .mySegmentsLoadedFromCache) {
                    trigger(event: SplitEvent.sdkReadyFromCache)
                }
            case .splitKilledNotification:
                if isTriggered(external: .sdkReady) {
                    trigger(event: .sdkUpdated)
                    return
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
        if let times = executionTimes[event.toString()] {
            return (times == 0)
        }
        return false
    }

    private func triggerSdkReadyIfNeeded() {
        if isTriggered(internal: .mySegmentsUpdated),
           isTriggered(internal: .splitsUpdated),
           !isTriggered(external: .sdkReady) {
            self.saveMetrics()
            self.trigger(event: SplitEvent.sdkReady)
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

        //If executionTimes is lower than zero, execute it without limitation
        if let subscriptions = getSubscriptions(for: event) {
            for task in subscriptions {
                executeTask(event: event, task: task)
            }
        }
    }

    private func executeTask(event: SplitEvent, task: SplitEventTask) {
        DispatchQueue.main.async {
            let executor: SplitEventExecutorProtocol
                = SplitEventExecutorFactory.factory(event: event,
                                                    task: task,
                                                    resources: self.executorResources)
            executor.execute()
        }
    }

    private func isTriggered(internal event: SplitInternalEvent) -> Bool {
        return triggered.filter { $0 == event }.count > 0
    }

    private func saveMetrics() {
        DefaultMetricsManager.shared.time(microseconds: Date().unixTimestampInMiliseconds()
            - self.sdkReadyTimeStart, for: Metrics.Time.sdkReady)
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
        dataAccessQueue.async {
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
