//
//  EventsManager.swift
//  Split
//
//  Created by Sebastian Arrubia on 4/16/18.
//

import Foundation

public class SplitEventsManager {
    private let _queue:SynchronizedArrayQueue<SplitInternalEvent>
    private var _queueReadingTimer: DispatchSourceTimer?
    private let _queueReadingRefreshTime: Int
    
    private var _eventMySegmentsAreReady:Bool
    private var _eventSplitsAreReady:Bool
    
    private var _suscriptions = [SplitEvent:[SplitEventTask]]()
    private let _executorResources: SplitEventExecutorResources?
    private var _executionTimes: [String: Int]
    private let _config:SplitClientConfig
    
    public init(config: SplitClientConfig){
        _queue = SynchronizedArrayQueue<SplitInternalEvent>()
        _queueReadingRefreshTime = 300
        _eventMySegmentsAreReady = false
        _eventSplitsAreReady = false
        _executorResources = SplitEventExecutorResources()
        _config = config
        _executionTimes = [String: Int]()
        registerMaxAllowebExecutionTimesPerEvent()
        
        if config.sdkReadyTimeOut > 0 {
            let readyTimedoutQueue = DispatchQueue(label: "io.Split.Event.TimedOut")
            readyTimedoutQueue.asyncAfter(deadline: .now() + .milliseconds(config.sdkReadyTimeOut), execute: {
                self.notifyInternalEvent(SplitInternalEvent.sdkReadyTimeoutReached)
            })
        }
        
    }
    
    public func notifyInternalEvent(_ event:SplitInternalEvent) {
        _queue.append(event)
    }
    
    public func getExecutorResources() -> SplitEventExecutorResources {
        return _executorResources!
    }
    
    /**
     * This method should registering the allowed maximum times of event trigger
     * EXAMPLE: SDK_READY should be triggered only once
     */
    private func registerMaxAllowebExecutionTimesPerEvent() {
        
        _executionTimes = [SplitEvent.sdkReady.toString():1,
                                SplitEvent.sdkReadyTimedOut.toString():1]
    }
    
    public func register(event:SplitEvent, task:SplitEventTask) {
        let queue = DispatchQueue(label: "io.Split.Register.SplitEventTask")
        queue.sync {
            
            // If event is already triggered, execute the task
            if self._executionTimes[event.toString()] != nil && self._executionTimes[event.toString()] == 0 {
                executeTask(event: event, task: task);
                return;
            }
            
            if self._suscriptions[event] != nil {
                self._suscriptions[event]?.append(task)
            } else {
                self._suscriptions[event] = [task]
            }
        }
    }
    
    public func start(){
        let queue = DispatchQueue(label: "io.Split.Reading.Queue")
        _queueReadingTimer = DispatchSource.makeTimerSource(queue: queue)
        _queueReadingTimer!.schedule(deadline: .now(), repeating: .milliseconds(_queueReadingRefreshTime))
        _queueReadingTimer!.setEventHandler { [weak self] in
            guard let strongSelf = self else {
                return
            }
            guard strongSelf._queueReadingTimer != nil else {
                strongSelf.stopReadingQueue()
                return
            }
            strongSelf.processEvents()
        }
        _queueReadingTimer!.resume()
    }
    
    private func stopReadingQueue() {
        _queueReadingTimer?.cancel()
        _queueReadingTimer = nil
    }
    
    private func processEvents(){
        self._queue.take(completion: {(element:SplitInternalEvent) -> Void in
            switch element {
            case .mySegmentsAreReady:
                self._eventMySegmentsAreReady = true
                if self._eventSplitsAreReady {
                    self.trigger(event: SplitEvent.sdkReady)
                }
                break
            case .splitsAreReady:
                self._eventSplitsAreReady = true
                if self._eventMySegmentsAreReady {
                    self.trigger(event: SplitEvent.sdkReady)
                }
                break
            case .sdkReadyTimeoutReached:
                if !self._eventSplitsAreReady || !self._eventMySegmentsAreReady {
                    self.trigger(event: SplitEvent.sdkReadyTimedOut)
                }
                break
                
            /*
            Update events will be added soon
            */
            case .mySegmentsAreUpdated:
                break
            case .splitsAreUpdated:
                break
            }
        })
    }
    
    public func getExecutionTimes() -> [String: Int] {
        return _executionTimes
    }
    
    private func trigger(event:SplitEvent) {
        
        // If executionTimes is zero, maximum executions has been reached
        if (self._executionTimes[event.toString()] == 0){
            return;
            // If executionTimes is grater than zero, maximum executions decrease 1
        } else if (self._executionTimes[event.toString()]! > 0) {
            self._executionTimes[event.toString()]! = self._executionTimes[event.toString()]! - 1
        } //If executionTimes is lower than zero, execute it without limitation

        if self._suscriptions[event] != nil {
            for task in self._suscriptions[event]! {
                executeTask(event: event, task: task)
            }
        }
    }
    
    private func executeTask(event:SplitEvent, task:SplitEventTask) {
        let executor: SplitEventExecutorProtocol = SplitEventExecutorFactory.factory(event: event, task: task, resources: self._executorResources! )
        executor.execute()
    }
    
}
