//
//  StorageMigrator.swift
//  Split
//
//  Created by Javier Avrudsky on 11/02/2021.
//  Copyright © 2021 Split. All rights reserved.
//

import Foundation

class ImpressionsHit: Codable {
    var identifier: String
    var impressions: [ImpressionsTest]
    var attempts: Int = 0

    init(identifier: String, impressions: [ImpressionsTest]) {
        self.identifier = identifier
        self.impressions = impressions
    }

    func addAttempt() {
        attempts += 1
    }
}

class ImpressionsFile: Codable {
    var oldHits: [String: ImpressionsHit]?
    var currentHit: ImpressionsHit?
}

class EventsFile: DynamicCodable {

    var oldHits: [String: EventsHit]?
    var currentHit: EventsHit?

    init() {
    }

    required init(jsonObject: Any) throws {
        if let jsonObj = jsonObject as? [String: Any] {
            if let jsonOldHits = jsonObj["oldHits"] {
                oldHits = try [String: EventsHit](jsonObject: jsonOldHits)
            }

            if let jsonCurrentHit = jsonObj["currentHit"] {
                currentHit = try? EventsHit(jsonObject: jsonCurrentHit)
            }
        }
    }

    func toJsonObject() -> Any {
        var jsonObject = [String: Any]()
        jsonObject["oldHits"] = oldHits?.toJsonObject()
        jsonObject["currentHit"] = currentHit?.toJsonObject()
        return jsonObject
    }
}

class EventsHit: DynamicCodable {

    var identifier: String
    var events: [EventDTO]
    var attempts: Int = 0

    init(identifier: String, events: [EventDTO]) {
        self.identifier = identifier
        self.events = events
    }

    func addAttempt() {
        attempts += 1
    }

    required init(jsonObject: Any) throws {
        guard let data = jsonObject as? [String: Any] else {
            throw SplitEncodingError.unknown
        }

        identifier = data["identifier"] as? String ?? ""
        attempts = data["attempts"] as? Int ?? 0

        guard let eventsData = data["events"] else {
            throw SplitEncodingError.unknown
        }
        events = try [EventDTO](jsonObject: eventsData)
    }

    func toJsonObject() -> Any {
        var jsonObject = [String: Any]()
        jsonObject["identifier"] = identifier
        jsonObject["attempts"] = attempts
        jsonObject["events"] = events.toJsonObject()
        return jsonObject
    }
}

protocol StorageMigrator {
    func runMigrationIfNeeded() -> Bool
}

class DefaultStorageMigrator: StorageMigrator {

    let queue = DispatchQueue(label: "Split storage migration", target: .global())

    private let fileStorage: FileStorageProtocol
    private let splitDatabase: SplitDatabase
    private let kImpressionsFileName: String = "SPLITIO.impressions"
    private let kEventsFileName: String = "SPLITIO.events_track"
    private let kSplitsFileName: String = "SPLITIO.splits"
    private let kMySegmentsFileNamePrefix  = "SPLITIO.mySegments"
    private let mySegmentsFileName: String

    init(fileStorage: FileStorageProtocol, splitDatabase: SplitDatabase, userKey: String) {
        self.fileStorage = fileStorage
        self.splitDatabase = splitDatabase
        self.mySegmentsFileName = "\(kMySegmentsFileNamePrefix)_\(userKey)"
    }

    func runMigrationIfNeeded() -> Bool {
        var wasRun = false
        let semaphore = DispatchSemaphore(value: 0)
        queue.async {
            wasRun = self.checkAndRun()
            semaphore.signal()
        }
        _ = semaphore.wait(timeout: .now() + 1.0)
        return wasRun
    }

    private func checkAndRun() -> Bool {
        let generalInfoDao = self.splitDatabase.generalInfoDao
        if (generalInfoDao.longValue(info: .databaseMigrationStatus) ?? 0) == 1
            || fileStorage.getAllIds()?.count ?? 0 == 0
            || (isOutdated(fileStorage.lastModifiedDate(fileName: kImpressionsFileName))
            && isOutdated(fileStorage.lastModifiedDate(fileName: kEventsFileName))) {
            deleteFiles()
            return false
        }
        generalInfoDao.update(info: .databaseMigrationStatus, longValue: 1)
        migrateEvents()
        migrateImpressions()
        deleteFiles()
        return true
    }

    private func migrateImpressions() {

        guard let hitsJson = fileStorage.read(fileName: kImpressionsFileName) else {
            return
        }
        if hitsJson.count == 0 { return }
        do {
            let hitsFile = try Json.encodeFrom(json: hitsJson, to: ImpressionsFile.self)
            let tests: [ImpressionsTest] = hitsFile.oldHits?.compactMap { $0.value.impressions }.flatMap { $0 } ?? []
            insertImpressions(tests)

            let currentTests = hitsFile.currentHit?.impressions.compactMap { $0 } ?? []
            insertImpressions(currentTests)

        } catch {
            Logger.w("Avoiding impressions migration")
            return
        }
    }

    private func insertImpressions(_ tests: [ImpressionsTest]) {
        let impressionDao = splitDatabase.impressionDao
        for test in tests {
            for impression in test.keyImpressions {
                if !isOutdated(impression.time ?? 0) {
                    impression.feature = test.testName
                    impressionDao.insert(impression)
                }
            }
        }
    }

    private func migrateEvents() {
        let eventDao = splitDatabase.eventDao
        guard let hitsJson = fileStorage.read(fileName: kEventsFileName) else {
            return
        }
        if hitsJson.count == 0 { return }
        do {
            let hitsFile = try Json.dynamicEncodeFrom(json: hitsJson, to: EventsFile.self)
            var events: [EventDTO] = hitsFile.oldHits?.flatMap { $0.value.events } ?? []
            events += hitsFile.currentHit?.events ?? []

            events.forEach { event in
                if !isOutdated(event.timestamp ?? 0) {
                    eventDao.insert(event)
                }
            }

        } catch {
            Logger.w("Avoiding events migration")
            return
        }
    }

    private func deleteFiles() {
        fileStorage.delete(fileName: kImpressionsFileName)
        fileStorage.delete(fileName: kEventsFileName)
        fileStorage.delete(fileName: kSplitsFileName)
        fileStorage.delete(fileName: mySegmentsFileName)
    }

    private func isOutdated(_ timestamp: Int64) -> Bool {
        return Date().unixTimestamp() - ServiceConstants.recordedDataExpirationPeriodInSeconds > timestamp
    }
}
