//
//  RefreshableSplitFetcher.swift
//  Pods
//
//  Created by Brian Sztamfater on 3/10/17.
//
//

import Foundation

public final class RefreshableSplitFetcher: SplitFetcher {
    
    private let splitChangeFetcher: SplitChangeFetcher
    private let interval: Int
    private var featurePollTimer: DispatchSourceTimer?

    internal let splitCache: SplitCacheProtocol

    public weak var dispatchGroup: DispatchGroup?

    private var _eventsManager: SplitEventsManager
    private var firstSplitFetchs: Bool = true
    
    public init(splitChangeFetcher: SplitChangeFetcher, splitCache: SplitCacheProtocol, interval: Int, dispatchGroup: DispatchGroup? = nil, eventsManager:SplitEventsManager) {
        self.splitCache = splitCache
        self.splitChangeFetcher = splitChangeFetcher
        self.interval = interval
        self.dispatchGroup = dispatchGroup
        self._eventsManager = eventsManager
    }
    
    public func forceRefresh() {
        _ = self.splitCache.setChangeNumber(-1)
        pollForSplitChanges()
    }
    
    public func fetch(splitName: String) -> Split? {
        return splitCache.getSplit(splitName: splitName)
    }
    
    public func fetchAll() -> [Split]? {
        return splitCache.getAllSplits()
    }
    
    public func start() {
        do {
            let splitChange = try self.splitChangeFetcher.fetch(since: -1, policy: .cacheOnly)
            if let _ = splitChange {
                self._eventsManager.notifyInternalEvent(SplitInternalEvent.splitsAreReady)
                firstSplitFetchs = false
                Logger.d("SplitChanges fetched from CACHE successfully")
            } else {
                Logger.d("Split CACHE not found")
            }
        } catch {
            Logger.e("Error trying to fetch SplitChanges from CACHE")
        }
        startPollingForSplitChanges()
    }
    
    public func stop() {
        stopPollingForSplitChanges()
    }
    
    private func startPollingForSplitChanges() {
        let queue = DispatchQueue(label: "split-polling-queue")
        featurePollTimer = DispatchSource.makeTimerSource(queue: queue)
        featurePollTimer!.schedule(deadline: .now(), repeating: .seconds(self.interval))
        featurePollTimer!.setEventHandler { [weak self] in
            guard let strongSelf = self else {
                return
            }
            guard strongSelf.featurePollTimer != nil else {
                strongSelf.stopPollingForSplitChanges()
                return
            }
            strongSelf.pollForSplitChanges()
        }
        featurePollTimer!.resume()
    }
    
    private func stopPollingForSplitChanges() {
        featurePollTimer?.cancel()
        featurePollTimer = nil
    }
    
    private func pollForSplitChanges() {
        dispatchGroup?.enter()
        let queue = DispatchQueue(label: "split-changes-queue")
        queue.async { [weak self] in
            guard let strongSelf = self else {
                return
            }
            do {
                
                let splitChanges = try strongSelf.splitChangeFetcher.fetch(since: strongSelf.splitCache.getChangeNumber())
                Logger.d(splitChanges.debugDescription)

                strongSelf.dispatchGroup?.leave()
                
                if strongSelf.firstSplitFetchs {
                    strongSelf.firstSplitFetchs = false
                    strongSelf._eventsManager.notifyInternalEvent(SplitInternalEvent.splitsAreReady)
                } else {
                    strongSelf._eventsManager.notifyInternalEvent(SplitInternalEvent.splitsAreUpdated)
                }
                
                
            } catch let error {
                Logger.e("Problem fetching splitChanges: %@", error.localizedDescription)
            }
        }
    }
}
