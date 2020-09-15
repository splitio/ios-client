//
//  RefreshableMySegmentsFetcher.swift
//  Pods
//
//  Created by Brian Sztamfater on 5/10/17.
//
//

import Foundation

final class DefaultRefreshableMySegmentsFetcher: NSObject, RefreshableMySegmentsFetcher, QueryableMySegmentsFetcher {

    private let mySegmentsChangeFetcher: MySegmentsChangeFetcher
    private let interval: Int
    private let matchingKey: String
    internal let mySegmentsCache: MySegmentsCacheProtocol

    private var pollTimer: DispatchSourceTimer?

    weak var dispatchGroup: DispatchGroup?

    private var _eventsManager: SplitEventsManager

    private var firstMySegmentsFetch = true

    init(matchingKey: String, mySegmentsChangeFetcher: MySegmentsChangeFetcher,
         mySegmentsCache: MySegmentsCacheProtocol,
         interval: Int,
         dispatchGroup: DispatchGroup? = nil,
         eventsManager: SplitEventsManager) {

        self.matchingKey = matchingKey
        self.mySegmentsCache = mySegmentsCache
        self.mySegmentsChangeFetcher = mySegmentsChangeFetcher
        self.interval = interval
        self.dispatchGroup = dispatchGroup
        self._eventsManager = eventsManager
    }

    func forceRefresh() {
        pollForMySegmentsChanges()
    }

    func fetchAll() -> [String] {
        return mySegmentsCache.getSegments()
    }

    func start() {
        startPollingForMySegmentsChanges()
    }

    func runInitialFetch() {
        do {
            let mySegments = try self.mySegmentsChangeFetcher.fetch(user: self.matchingKey, policy: .cacheOnly)
            if mySegments != nil {
                Logger.d("Segments Changes fetched from CACHE successfully")
                self._eventsManager.notifyInternalEvent(SplitInternalEvent.mySegmentsAreReady)
                firstMySegmentsFetch = false
                return
            }
            fetchFromRemote()
        } catch {
            Logger.e("Error trying to fetch MySegmentsChanges from CACHE")
        }
    }

    func stop() {
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
            guard let self = self else {
                return
            }
            self.fetchFromRemote()
        }
    }

    private func fetchFromRemote() {
        do {
            let segments = try self.mySegmentsChangeFetcher.fetch(user: self.matchingKey)
            Logger.d(segments.debugDescription)
            self.dispatchGroup?.leave()
            fireMySegmentsEvent()
        } catch let error {
            DefaultMetricsManager.shared.count(delta: 1, for: Metrics.Counter.mySegmentsFetcherException)
            Logger.e("Problem fetching mySegments: %@", error.localizedDescription)
        }
    }

    func isInSegments(name: String) -> Bool {
        return mySegmentsCache.isInSegments(name: name)
    }

    private func fireMySegmentsEvent() {
        if self.firstMySegmentsFetch {
            self.firstMySegmentsFetch = false
            self._eventsManager.notifyInternalEvent(SplitInternalEvent.mySegmentsAreReady)
        } else {
            self._eventsManager.notifyInternalEvent(SplitInternalEvent.mySegmentsAreUpdated)
        }
    }
}
