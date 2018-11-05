//
//  EventsManager.swift
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
}

class TrackManager {
    
    private let kEventsPrefix: String = "events_"
    private let kEventsFileName: String = "events_track"
    private let kMaxHitAttempts = 3
    
    private var fileStorage = FileStorage()
    private var eventsFileStorage: FileStorageManager?
    
    private var currentEventsHit = SynchronizedArrayWrapper<EventDTO>()
    private var eventsHits = [String: EventsHit]()
    
    private let restClient = RestClient()
    private var pollingManager: PollingManager!
    
    private var eventsFirstPushWindow: Int!
    private var eventsPushRate: Int!
    private var eventsQueueSize: Int64!
    private var eventsPerPush: Int!
    
    init(dispatchGroup: DispatchGroup? = nil, config: TrackManagerConfig) {
        
        self.eventsFileStorage = FileStorageManager(storage: self.fileStorage, filePrefix: kEventsPrefix)
        self.eventsFileStorage?.limitAttempts = false
        self.eventsFirstPushWindow = config.firstPushWindow
        self.eventsPushRate = config.pushRate
        self.eventsQueueSize = config.queueSize
        self.eventsPerPush = config.eventsPerPush
        self.createPollingManager(dispatchGroup: dispatchGroup)
        subscribeNotifications()
    }
    
    deinit {
        #if swift(>=4.2)
            NotificationCenter.default.removeObserver(self, name: UIApplication.didEnterBackgroundNotification, object: nil)
            NotificationCenter.default.removeObserver(self, name: UIApplication.didBecomeActiveNotification, object: nil)
        #else
            NotificationCenter.default.addObserver(self, selector: #selector(applicationDidEnterBackground), name: .UIApplicationDidEnterBackground, object: nil)
            NotificationCenter.default.addObserver(self, selector: #selector(applicationDidBecomeActive), name: .UIApplicationDidBecomeActive, object: nil)
        #endif
    }
}

// MARK: Public
extension TrackManager {
    func start(){
        pollingManager.start()
    }
    
    func stop(){
        pollingManager.stop()
    }

    func appendEvent(event: EventDTO) {
        currentEventsHit.append(event)
        if currentEventsHit.count == eventsPerPush {
            appendHit()
            if eventsHits.count * eventsPerPush >= eventsQueueSize {
                sendEvents()
            }
        }
    }
    
    func appendHitAndSendAll(){
        appendHit()
        sendEvents()
    }
}

// MARK: Private
extension TrackManager {
    
    private func appendHit(){
        if currentEventsHit.count == 0 { return }
        let newHit = EventsHit(identifier: UUID().uuidString, events: currentEventsHit.all)
        eventsHits[newHit.identifier] = newHit
        currentEventsHit.removeAll()
    }
    
    private func createPollingManager(dispatchGroup: DispatchGroup?){
        var config = PollingManagerConfig()
        config.firstPollWindow = self.eventsFirstPushWindow
        config.rate = self.eventsPushRate
        
        pollingManager = PollingManager(
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
        for (_, eventsHit) in eventsHits {
            sendEvents(eventsHit: eventsHit)
        }
    }
    
    private func sendEvents(eventsHit: EventsHit) {
        if eventsHits.count == 0 { return }
        if restClient.isEventsServerAvailable() {
            eventsHit.addAttempt()
            restClient.sendTrackEvents(events: eventsHit.events, completion: { result in
                do {
                    let _ = try result.unwrap()
                    Logger.d("Event posted successfully")
                    self.eventsHits.removeValue(forKey: eventsHit.identifier)
                } catch {
                    Logger.e("Event error: \(String(describing: error))")
                    if eventsHit.attempts >= self.kMaxHitAttempts {
                        self.eventsHits.removeValue(forKey: eventsHit.identifier)
                    }
                }
            })
        }
    }
    
    func saveEventsToDisk() {
        let eventsFile = EventsFile()
        eventsFile.oldHits = eventsHits
        
        if currentEventsHit.count > 0 {
            let newHit = EventsHit(identifier: UUID().uuidString, events: currentEventsHit.all)
            eventsFile.currentHit = newHit
        }

        do {
            let json = try Json.encodeToJson(eventsFile)
            eventsFileStorage?.save(content: json, as: kEventsFileName)
        } catch {
            Logger.e("Could not save events hits)")
        }
    }
    
    func loadEventsFromDisk(){
        guard let hitsJson = eventsFileStorage?.read(fileName: kEventsFileName) else {
            return
        }
        if hitsJson.count == 0 { return }
        eventsFileStorage?.delete(fileName: kEventsFileName)
        do {
            let hitsFile = try Json.encodeFrom(json: hitsJson, to: EventsFile.self)
            eventsHits = hitsFile.oldHits ?? [String: EventsHit]()
            currentEventsHit.fill(with: hitsFile.currentHit?.events ?? [EventDTO]())
        } catch {
            Logger.e("Error while loading track events from disk")
            return
        }
    }

}

// MARK: Background / Foreground
extension TrackManager {
    @objc func applicationDidEnterBackground() {
        Logger.d("Saving Event to disk")
        saveEventsToDisk()
    }
    
    @objc func applicationDidBecomeActive() {
        loadEventsFromDisk()
    }
    
    func subscribeNotifications() {
        #if swift(>=4.2)
            NotificationCenter.default.addObserver(self, selector: #selector(applicationDidEnterBackground), name: UIApplication.didEnterBackgroundNotification, object: nil)
            NotificationCenter.default.addObserver(self, selector: #selector(applicationDidBecomeActive), name: UIApplication.didBecomeActiveNotification, object: nil)
        #else
            NotificationCenter.default.addObserver(self, selector: #selector(applicationDidEnterBackground), name: .UIApplicationDidEnterBackground, object: nil)
            NotificationCenter.default.addObserver(self, selector: #selector(applicationDidBecomeActive), name: .UIApplicationDidBecomeActive, object: nil)
        #endif
    }
}
