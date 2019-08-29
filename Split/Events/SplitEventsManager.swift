//
//  EventsManager.swift
//  Split
//
//  Created by Sebastian Arrubia on 4/16/18.
//

import Foundation

protocol SplitEventsManager {
    func notifyInternalEvent(_ event: SplitInternalEvent)
    func getExecutorResources() -> SplitEventExecutorResources
    func register(event: SplitEvent, task: SplitEventTask)
    func start()
    func eventAlreadyTriggered(event: SplitEvent) -> Bool
    func getExecutionTimes() -> [String: Int]
}

class DefaultSplitEventsManager: SplitEventsManager {
    private let queue: SynchronizedArrayQueue<SplitInternalEvent>
    private var queueReadingTimer: DispatchSourceTimer?
    private let queueReadingRefreshTime: Int

    private var eventMySegmentsAreReady: Bool
    private var eventSplitsAreReady: Bool

    private var sdkReadyTimeStart: Int64

    private var suscriptions = [SplitEvent: [SplitEventTask]]()
    private let executorResources: SplitEventExecutorResources?
    private var executionTimes: [String: Int]

    init(config: SplitClientConfig) {
        sdkReadyTimeStart = Date().unixTimestampInMiliseconds()
        queue = SynchronizedArrayQueue<SplitInternalEvent>()
        queueReadingRefreshTime = 300
        eventMySegmentsAreReady = false
        eventSplitsAreReady = false
        executorResources = SplitEventExecutorResources()
        executionTimes = [String: Int]()
        registerMaxAllowedExecutionTimesPerEvent()

        if config.sdkReadyTimeOut > 0 {
            let readyTimedoutQueue = DispatchQueue(label: "io.Split.Event.TimedOut")
            readyTimedoutQueue.asyncAfter(deadline: .now() + .milliseconds(config.sdkReadyTimeOut), execute: {
                self.notifyInternalEvent(SplitInternalEvent.sdkReadyTimeoutReached)
            })
        }

    }

    func notifyInternalEvent(_ event: SplitInternalEvent) {
        queue.append(event)
    }

    func getExecutorResources() -> SplitEventExecutorResources {
        return executorResources!
    }

    func register(event: SplitEvent, task: SplitEventTask) {
        let queue = DispatchQueue(label: "io.Split.Register.SplitEventTask")
        queue.sync {

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
        let queue = DispatchQueue(label: "io.Split.Reading.Queue")
        queueReadingTimer = DispatchSource.makeTimerSource(queue: queue)
        queueReadingTimer!.schedule(deadline: .now(), repeating: .milliseconds(queueReadingRefreshTime))
        queueReadingTimer!.setEventHandler { [weak self] in
            guard let strongSelf = self else {
                return
            }
            guard strongSelf.queueReadingTimer != nil else {
                strongSelf.stopReadingQueue()
                return
            }
            strongSelf.processEvents()
        }
        queueReadingTimer!.resume()
    }

    func eventAlreadyTriggered(event: SplitEvent) -> Bool {
        if let times = executionTimes[event.toString()] {
            return times == 0
        }
        return false
    }

    func getExecutionTimes() -> [String: Int] {
        return executionTimes
    }

    /**
     * This method should registering the allowed maximum times of event trigger
     * EXAMPLE: SDK_READY should be triggered only once
     */
    private func registerMaxAllowedExecutionTimesPerEvent() {

        executionTimes = [ SplitEvent.sdkReady.toString(): 1,
                           SplitEvent.sdkReadyTimedOut.toString(): 1]
    }

    private func stopReadingQueue() {
        queueReadingTimer?.cancel()
        queueReadingTimer = nil
    }

    private func processEvents() {
        self.queue.take(completion: {(element: SplitInternalEvent) -> Void in
            switch element {
            case .mySegmentsAreReady:
                self.eventMySegmentsAreReady = true
                if self.eventSplitsAreReady {
                    DefaultMetricsManager.shared.time(microseconds: Date().unixTimestampInMiliseconds()
                        - self.sdkReadyTimeStart, for: Metrics.Time.sdkReady)
                    self.trigger(event: SplitEvent.sdkReady)
                }

            case .splitsAreReady:
                self.eventSplitsAreReady = true
                if self.eventMySegmentsAreReady {
                    DefaultMetricsManager.shared.time(microseconds: Date().unixTimestampInMiliseconds()
                        - self.sdkReadyTimeStart, for: Metrics.Time.sdkReady)
                    self.trigger(event: SplitEvent.sdkReady)
                }

            case .sdkReadyTimeoutReached:
                if !self.eventSplitsAreReady || !self.eventMySegmentsAreReady {
                    self.trigger(event: SplitEvent.sdkReadyTimedOut)
                }
            case .splitsAreUpdated:
                Logger.d("splitsAreUpdated event fired")

            case .mySegmentsAreUpdated:
                Logger.d("mySegmentsAreUpdated event fired")
            }
        })
    }

    private func trigger(event: SplitEvent) {

        // If executionTimes is zero, maximum executions has been reached
        if self.executionTimes[event.toString()] == 0 {
            return
            // If executionTimes is grater than zero, maximum executions decrease 1
        } else if self.executionTimes[event.toString()]! > 0 {
            self.executionTimes[event.toString()]! = self.executionTimes[event.toString()]! - 1
        } //If executionTimes is lower than zero, execute it without limitation

        if self.suscriptions[event] != nil {
            for task in self.suscriptions[event]! {
                executeTask(event: event, task: task)
            }
        }
    }

    private func executeTask(event: SplitEvent, task: SplitEventTask) {
        let executor: SplitEventExecutorProtocol = SplitEventExecutorFactory.factory(event: event,
                                                                                     task: task,
                                                                                     resources: self.executorResources!)
        executor.execute()
    }

}
