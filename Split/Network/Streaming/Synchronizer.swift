//
//  Synchronizer.swift
//  Split
//
//  Created by Javier L. Avrudsky on 24/08/2020.
//  Copyright © 2020 Split. All rights reserved.
//

import Foundation

protocol Synchronizer {
    func synchronizeSplits()
    func synchronizeSplits(changeNumber: Int64)
    func synchronizeMySegments()
    func loadAndSynchronizeSplits()
    func loadSplitsFromCache()
    func loadMySegmentsFromCache()
    func startPeriodicFetching()
    func stopPeriodicFetching()
    func startPeriodicRecording()
    func stopPeriodicRecording()
    func pushEvent(event: EventDTO)
    func pushImpression(impression: Impression)
    func flush()
    func destroy()
}
