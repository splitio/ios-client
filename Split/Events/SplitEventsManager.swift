//
//  EventsManager.swift
//  Split
//
//  Created by Sebastian Arrubia on 4/16/18.
//

import Foundation

protocol SplitEventsManager {
    var executorResources: SplitEventExecutorResources { get }
    func notifyInternalEvent(_ event: SplitInternalEvent)
    func register(event: SplitEvent, task: SplitEventTask)
    func start()
    func stop()
    func eventAlreadyTriggered(event: SplitEvent) -> Bool
    func getExecutionTimes() -> [String: Int]
}

class DefaultSplitEventsManager: SplitEventsManager {
    let executorResources: SplitEventExecutorResources
    private let eventsQueue: SynchronizedArrayQueue<SplitInternalEvent>
    private var eventsReadingTimer: DispatchSourceTimer
    private let readingRefreshTime: Int

    private var sdkReadyTimeStart: Int64

    private var suscriptions = [SplitEvent: [SplitEventTask]]()
    private var executionTimes: [String: Int]
    private var triggered: [SplitInternalEvent]
    private let processQueue = DispatchQueue(label: "splits-sdk-events-queue")
    private var isStarted: Bool

    init(config: SplitClientConfig) {
        self.isStarted = false
        self.eventsReadingTimer = DispatchSource.makeTimerSource(queue: processQueue)
        self.sdkReadyTimeStart = Date().unixTimestampInMiliseconds()
        self.eventsQueue = SynchronizedArrayQueue<SplitInternalEvent>()
        self.readingRefreshTime = 300
        self.triggered = [SplitInternalEvent]()

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
            self.eventsQueue.append(event)
        }
    }

    func register(event: SplitEvent, task: SplitEventTask) {
        processQueue.sync {
            // If event is already triggered, execute the task
            if self.executionTimes[event.toString()] != nil && self.executionTimes[event.toString()] == 0 {
                executeTask(event: event, task: task)
                return
            }

            if self.suscriptions[event] != nil {
                self.suscriptions[event]?.append(task)
            } else {
                self.suscriptions[event] = [task]
            }
        }
    }

    func start() {
        let timer = self.eventsReadingTimer
        processQueue.sync {
            if self.isStarted {
                return
            }
            self.isStarted = true

            timer.schedule(deadline: .now(), repeating: .milliseconds(readingRefreshTime))
            timer.setEventHandler { [weak self] in
                guard let self = self else {
                    return
                }
                self.processEvents()
            }
            eventsReadingTimer.resume()
        }
    }

    func eventAlreadyTriggered(event: SplitEvent) -> Bool {
        var isTriggered = false
        processQueue.sync {
            isTriggered = self.isTriggered(external: event)
        }
        return isTriggered
    }

    func getExecutionTimes() -> [String: Int] {
        var times: [String: Int]?
        processQueue.sync {
            times = executionTimes
        }
        return times ?? [String: Int]()
    }

    func stop() {
        processQueue.sync {
            eventsReadingTimer.cancel()
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

    private func processEvents() {
        // This function has to run on processQueue, set when creating the dispatch source
        guard let event = eventsQueue.take() else {

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

        case .sdkReadyTimeoutReached:
            if !isTriggered(external: .sdkReady) {
                trigger(event: SplitEvent.sdkReadyTimedOut)
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
        // If executionTimes is zero, maximum executions has been reached
        if executionTimes[event.toString()] == 0 {
            return
        }

        // If executionTimes is grater than zero, maximum executions decrease 1
        if let times = executionTimes[event.toString()], times > 0 {
            self.executionTimes[event.toString()] = times - 1
        }

        //If executionTimes is lower than zero, execute it without limitation
        if let subscriptions = self.suscriptions[event] {
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
}
