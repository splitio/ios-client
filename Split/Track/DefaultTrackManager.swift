//
//  DefaultTrackManager.swift
//  Split
//
//  Created by Javier Avrudsky on 06/14/2018.
//

import Foundation

struct TrackManagerConfig {
    var firstPushWindow: Int!
    var pushRate: Int!
    var queueSize: Int64!
    var eventsPerPush: Int!
    var maxHitsSizeInBytes: Int!
}

class DefaultTrackManager {

    private let kEventsFileName: String = "SPLITIO.events_track"
    private let kMaxHitAttempts = 3

    private var eventsFileStorage: FileStorageProtocol

    private var currentEventsHit = SynchronizedArrayWrapper<EventDTO>()
    private var eventsHits = SyncDictionarySingleWrapper<String, EventsHit>()

    private let restClient: RestClientTrackEvents
    private var taskExecutor: PeriodicTaskExecutor!

    private let eventsFirstPushWindow: Int
    private let eventsPushRate: Int
    private let eventsQueueSize: Int64
    private let eventsPerPush: Int
    private let maxHitsSizeInBytes: Int
    private var eventCount: Int = 0
    private var eventBytesCount: Int = 0

    init(dispatchGroup: DispatchGroup? = nil, config: TrackManagerConfig, fileStorage: FileStorageProtocol,
         restClient: RestClientTrackEvents? = nil) {
        self.eventsFileStorage = fileStorage
        self.eventsFirstPushWindow = config.firstPushWindow
        self.eventsPushRate = config.pushRate
        self.eventsQueueSize = config.queueSize
        self.eventsPerPush = config.eventsPerPush
        self.maxHitsSizeInBytes = config.maxHitsSizeInBytes
        self.restClient = restClient ?? RestClient()
        self.createTaskExecutor(dispatchGroup: dispatchGroup)
        subscribeNotifications()
    }
}

// MARK: Public
extension DefaultTrackManager: TrackManager {
    func start() {
        taskExecutor.start()
    }

    func stop() {
        taskExecutor.stop()
    }

    func flush() {
        appendHitAndSendAll()
    }

    func appendEvent(event: EventDTO) {
        currentEventsHit.append(event)
        increaseToEventCount()
        addToBytesCount(event.sizeInBytes)

        if (getEventCount() >= eventsQueueSize) || (getBytesCount() >= maxHitsSizeInBytes) {
            appendHitAndSendAll()
        } else if currentEventsHit.count == eventsPerPush {
            appendHit()
        }
    }

    func appendHitAndSendAll() {
        appendHit()
        sendEvents()
        clearBytesCount()
        clearEventCount()
    }

    func addToBytesCount(_ count: Int) {
        DispatchQueue.global().sync { [weak self] in
            if let self = self {
                self.eventBytesCount += count
            }
        }
    }

    func clearBytesCount() {
        DispatchQueue.global().sync { [weak self] in
            if let self = self {
                self.eventBytesCount = 0
            }
        }
    }

    func getBytesCount() -> Int {
        var count = 0
        DispatchQueue.global().sync { [weak self] in
            if let self = self {
                count = self.eventBytesCount
            }
        }
        return count
    }

    func increaseToEventCount() {
        DispatchQueue.global().sync { [weak self] in
            if let self = self {
                self.eventCount += 1
            }
        }
    }

    func clearEventCount() {
        DispatchQueue.global().sync { [weak self] in
            if let self = self {
                self.eventCount = 0
            }
        }
    }

    func getEventCount() -> Int {
        var count = 0
        DispatchQueue.global().sync { [weak self] in
            if let self = self {
                count = self.eventCount
            }
        }
        return count
    }
}

// MARK: Private
extension DefaultTrackManager {

    private func appendHit() {
        if currentEventsHit.count == 0 { return }
        let newHit = EventsHit(identifier: UUID().uuidString, events: currentEventsHit.takeAll())
        eventsHits.setValue(newHit, forKey: newHit.identifier)
    }

    private func createTaskExecutor(dispatchGroup: DispatchGroup?) {
        var config = PeriodicTaskExecutorConfig()
        config.firstExecutionWindow = self.eventsFirstPushWindow
        config.rate = self.eventsPushRate

        taskExecutor = PeriodicTaskExecutor(
            dispatchGroup: dispatchGroup,
            config: config,
            triggerAction: {[weak self] in
                if let strongSelf = self {
                    strongSelf.appendHitAndSendAll()
                }
            }
        )
    }

    private func sendEvents() {
        let hits = eventsHits.takeAll()
        for (_, eventsHit) in hits {
            sendEvents(eventsHit: eventsHit)
        }
    }

    private func sendEvents(eventsHit: EventsHit) {
        if eventsHit.events.count == 0 { return }
        if restClient.isEventsServerAvailable() {
            eventsHit.addAttempt()
            restClient.sendTrackEvents(events: eventsHit.events, completion: { result in
                do {
                    _ = try result.unwrap()
                    Logger.d("Event posted successfully")
                } catch {
                    Logger.e("Event error: \(String(describing: error))")
                    if eventsHit.attempts < self.kMaxHitAttempts {
                        self.eventsHits.setValue(eventsHit, forKey: eventsHit.identifier)
                    }
                }
            })
        } else {
            Logger.d("Server is not reachable. Sending track events will be delayed until host is reachable")
        }
    }

    func saveEventsToDisk() {
        let eventsFile = EventsFile()
        eventsFile.oldHits = eventsHits.all

        if currentEventsHit.count > 0 {
            let newHit = EventsHit(identifier: UUID().uuidString, events: currentEventsHit.all)
            eventsFile.currentHit = newHit
        }

        do {
            let json = try Json.dynamicEncodeToJson(eventsFile)
            eventsFileStorage.write(fileName: kEventsFileName, content: json)
        } catch {
            Logger.e("Could not save events hits)")
        }
    }

    func loadEventsFromDisk() {
        guard let hitsJson = eventsFileStorage.read(fileName: kEventsFileName) else {
            return
        }
        if hitsJson.count == 0 { return }
        eventsFileStorage.delete(fileName: kEventsFileName)
        do {
            let hitsFile = try Json.dynamicEncodeFrom(json: hitsJson, to: EventsFile.self)
            if let oldHits = hitsFile.oldHits {
                for hit in oldHits {
                    eventsHits.setValue(hit.value, forKey: hit.key)
                }
            }
            currentEventsHit.fill(with: hitsFile.currentHit?.events ?? [EventDTO]())
        } catch {
            Logger.e("Error while loading track events from disk")
            return
        }
    }
}

// MARK: Background / Foreground
extension DefaultTrackManager {
    func subscribeNotifications() {
        NotificationHelper.instance.addObserver(for: AppNotification.didBecomeActive) { [weak self] in
            if let self = self {
                self.loadEventsFromDisk()
            }
        }

        NotificationHelper.instance.addObserver(for: AppNotification.didEnterBackground) { [weak self] in

            if let self = self {
                self.saveEventsToDisk()
            }
        }
    }
}
