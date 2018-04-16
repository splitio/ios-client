//
//  EventsManager.swift
//  Split
//
//  Created by Sebastian Arrubia on 4/16/18.
//

import Foundation

public class SplitEventsManager {
    private let _queue:SynchronizedArrayQueue<SplitInternalEvent>
    private var _queueReadingPollTimer: DispatchSourceTimer?
    private let _queueReadingRefreshTime: Int
    
    private var _eventMySegmentsAreReady:Bool
    private var _eventSplitsAreReady:Bool
    
    public init(){
        _queue = SynchronizedArrayQueue<SplitInternalEvent>()
        _queueReadingRefreshTime = 300
        _eventMySegmentsAreReady = false
        _eventSplitsAreReady = false
    }
    
    public func notifyInternalEvent(_ event:SplitInternalEvent){
        _queue.append(event)
    }
    
    public func start(){
        let queue = DispatchQueue(label: "io.Split.Reading.Queue")
        _queueReadingPollTimer = DispatchSource.makeTimerSource(queue: queue)
        _queueReadingPollTimer!.schedule(deadline: .now(), repeating: .milliseconds(_queueReadingRefreshTime))
        _queueReadingPollTimer!.setEventHandler { [weak self] in
            guard let strongSelf = self else {
                return
            }
            guard strongSelf._queueReadingPollTimer != nil else {
                //strongSelf.stopPollingForSplitChanges()
                return
            }
            //strongSelf.pollForSplitChanges()
            //TAKE FROM QUEUE
            strongSelf._queue.take(completion: {(element:SplitInternalEvent) -> Void in
                switch element {
                case .mySegmentsAreReady:
                    print("****----->>>>> .mySegmentsAreReady")
                case .splitsAreReady:
                    print("****----->>>>> .splitsAreReady")
                case .sdkReadyTimeoutReached:
                    print("****----->>>>> .sdkReadyTimeoutReached")
                case .mySegmentsAreUpdated:
                    print("****----->>>>> .mySegmentsAreUpdated")
                case .splitsAreUpdated:
                    print("****----->>>>> .splitAreUpdated")
                }
            })
        }
        _queueReadingPollTimer!.resume()
    }
    
}
