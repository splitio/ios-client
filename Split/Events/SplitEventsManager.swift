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
    private let _config:SplitClientConfig
    
    public init(config: SplitClientConfig){
        _queue = SynchronizedArrayQueue<SplitInternalEvent>()
        _queueReadingRefreshTime = 300
        _eventMySegmentsAreReady = false
        _eventSplitsAreReady = false
        _executorResources = SplitEventExecutorResources()
        _config = config
        
        if config.getReadyTimeOut() > 0 {
            let readyTimedoutQueue = DispatchQueue(label: "io.Split.Event.TimedOut")
            readyTimedoutQueue.asyncAfter(deadline: .now() + .milliseconds(config.getReadyTimeOut()), execute: {
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
    
    public func register(event:SplitEvent, task:SplitEventTask) {
        let queue = DispatchQueue(label: "io.Split.Register.SplitEventTask")
        queue.sync {
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
                //strongSelf.stopPollingForSplitChanges()
                return
            }
            strongSelf.processEvents()
        }
        _queueReadingTimer!.resume()
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
    
    private func trigger(event:SplitEvent) {
        //TODO: Add max execution per events
        if self._suscriptions[event] != nil {
            for task in self._suscriptions[event]! {
                let executor: SplitEventExecutorProtocol = SplitEventExecutorFactory.factory(event: event, task: task, resources: self._executorResources! )
                executor.execute()
            }
        }
    }
    
}
