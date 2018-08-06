//
//  RefreshableMySegmentsFetcher.swift
//  Pods
//
//  Created by Brian Sztamfater on 5/10/17.
//
//

import Foundation

@objc public final class RefreshableMySegmentsFetcher: NSObject, MySegmentsFetcher {
    
    private let mySegmentsChangeFetcher: MySegmentsChangeFetcher
    private let interval: Int
    private let matchingKey: String
    internal let mySegmentsCache: MySegmentsCacheProtocol
    
    private var pollTimer: DispatchSourceTimer?

    public weak var dispatchGroup: DispatchGroup?
    
    private var _eventsManager: SplitEventsManager
    
    private var firstMySegmentsFetch = true
    
    public init(matchingKey: String, mySegmentsChangeFetcher: MySegmentsChangeFetcher, mySegmentsCache: MySegmentsCacheProtocol, interval: Int, dispatchGroup: DispatchGroup? = nil, eventsManager:SplitEventsManager) {
        self.matchingKey = matchingKey
        self.mySegmentsCache = mySegmentsCache
        self.mySegmentsChangeFetcher = mySegmentsChangeFetcher
        self.interval = interval
        self.dispatchGroup = dispatchGroup
        
        self._eventsManager = eventsManager
    }
    
    public func forceRefresh() {
        pollForMySegmentsChanges()
    }
    
    public func fetchAll() -> [String] {
        return mySegmentsCache.getSegments() ?? []
    }
    
    public func start() {
        
        do {
            let mySegments = try self.mySegmentsChangeFetcher.fetch(user: self.matchingKey, policy: .cacheOnly)
            if let _ = mySegments {
                Logger.d("Segments Changes fetched from CACHE successfully")
                self._eventsManager.notifyInternalEvent(SplitInternalEvent.mySegmentsAreReady)
                firstMySegmentsFetch = false
            } else {
                Logger.d("Segments CACHE not found")
            }
        } catch {
            Logger.e("Error trying to fetch MySegmentsChanges from CACHE")
        }
        startPollingForMySegmentsChanges()
    }
    
    public func stop() {
        stopPollingForMySegmentsChanges()
    }
    
    private func startPollingForMySegmentsChanges() {
        let queue = DispatchQueue(label: "split-polling-queue")
        pollTimer = DispatchSource.makeTimerSource(queue: queue)
        pollTimer!.schedule(deadline: .now(), repeating: .seconds(self.interval))
        pollTimer!.setEventHandler { [weak self] in
            guard let strongSelf = self else {
                return
            }
            guard strongSelf.pollTimer != nil else {
                strongSelf.stopPollingForMySegmentsChanges()
                return
            }
            strongSelf.pollForMySegmentsChanges()
        }
        pollTimer!.resume()
    }
    
    private func stopPollingForMySegmentsChanges() {
        pollTimer?.cancel()
        pollTimer = nil
    }
    
    private func pollForMySegmentsChanges() {
        dispatchGroup?.enter()
        let queue = DispatchQueue(label: "split-segments-queue")
        queue.async { [weak self] in
            guard let strongSelf = self else {
                return
            }
            do {
                
                let segments = try strongSelf.mySegmentsChangeFetcher.fetch(user: strongSelf.matchingKey)
                Logger.d(segments.debugDescription)
                strongSelf.dispatchGroup?.leave()
                
                if strongSelf.firstMySegmentsFetch {
                    strongSelf.firstMySegmentsFetch = false
                    strongSelf._eventsManager.notifyInternalEvent(SplitInternalEvent.mySegmentsAreReady)
                } else {
                    strongSelf._eventsManager.notifyInternalEvent(SplitInternalEvent.mySegmentsAreUpdated)
                }
                
            } catch let error {
                Logger.e("Problem fetching mySegments: %@", error.localizedDescription)
            }
        }
    }
}
