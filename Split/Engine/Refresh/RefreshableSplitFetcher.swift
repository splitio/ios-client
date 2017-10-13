//
//  RefreshableSplitFetcher.swift
//  Pods
//
//  Created by Brian Sztamfater on 3/10/17.
//
//

import Foundation

@objc public final class RefreshableSplitFetcher: NSObject, SplitFetcher {
    
    private let splitChangeFetcher: SplitChangeFetcher
    private let interval: Int
    private var featurePollTimer: DispatchSourceTimer?

    internal let splitCache: SplitCacheProtocol

    public weak var dispatchGroup: DispatchGroup?

    public init(splitChangeFetcher: SplitChangeFetcher, splitCache: SplitCacheProtocol, interval: Int, dispatchGroup: DispatchGroup? = nil) {
        self.splitCache = splitCache
        self.splitChangeFetcher = splitChangeFetcher
        self.interval = interval
        self.dispatchGroup = dispatchGroup
    }
    
    public func forceRefresh() {
        pollForSplitChanges()
    }
    
    public func fetch(splitName: String) -> ParsedSplit {
        // TODO: We need to actually save ParsedSplit objects
        return splitCache.getSplit(splitName: splitName) as! ParsedSplit
    }
    
    public func fetchAll() -> [ParsedSplit] {
        // TODO: We need to actually save ParsedSplit objects
        return splitCache.getAllSplits() as! [ParsedSplit]
    }
    
    public func start() {
        startPollingForSplitChanges()
    }
    
    public func stop() {
        stopPollingForSplitChanges()
    }
    
    private func startPollingForSplitChanges() {
        let queue = DispatchQueue(label: "split-polling-queue")
        featurePollTimer = DispatchSource.makeTimerSource(queue: queue)
        featurePollTimer!.scheduleRepeating(deadline: .now(), interval: .seconds(self.interval))
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
                splitChanges.splits?.forEach { split in
                    // TODO: We need to get a ParsedSplit object
                    strongSelf.splitCache.addSplit(splitName: split.name!, split: split)
                }
                strongSelf.splitCache.setChangeNumber(splitChanges.till!)
                strongSelf.dispatchGroup?.leave()
            } catch let error {
                debugPrint("Problem fetching splitChanges: %@", error.localizedDescription)
            }
        }
    }
}
