//
//  ImpressionManager.swift
//  Split
//
//  Created by Javier Avrudsky on 06/14/2018.
//
// ToDo: Replace with generic implemention for track events and impressions. Temporal implementation.

import Foundation

struct ImpressionManagerConfig {
    var pushRate: Int! // Interval
    var impressionsPerPush: Int64! // ChunkSize
}

class ImpressionManager {
    
    private let kImpressionsPrefix: String = "impressions_"
    private let kImpressionsFileName: String = "impressions_"
    private let kMaxHitAttempts = 3
    
    private var fileStorage = FileStorage()
    private var impressionsFileStorage: FileStorageManager?
    
    private var currentImpressionsHit = SynchronizedDictionaryWrapper<String, Impression>()
    private var impressionsHits = [String: ImpressionsHit]()
    
    private let restClient = RestClient()
    private var pollingManager: PollingManager!
    
    private var impressionsPushRate: Int!
    private var impressionsPerPush: Int64!
    
    init(dispatchGroup: DispatchGroup? = nil, config: ImpressionManagerConfig) {
        self.impressionsFileStorage = FileStorageManager(storage: self.fileStorage, filePrefix: kImpressionsPrefix)
        self.impressionsFileStorage?.limitAttempts = false
        self.impressionsPushRate = config.pushRate
        self.impressionsPerPush = config.impressionsPerPush
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
extension ImpressionManager {
    func start(){
        pollingManager.start()
    }
    
    func stop(){
        pollingManager.stop()
    }

    func appendImpression(impression: Impression, splitName: String) {
        currentImpressionsHit.appendValue(impression, toKey: splitName)
        if currentImpressionsHit.count == impressionsPerPush {
            appendHit()
        }
    }
    
    func appendHitAndSendAll(){
        appendHit()
        sendImpressions()
    }
}

// MARK: Private
extension ImpressionManager {
    
    private func appendHit(){
        if currentImpressionsHit.count == 0 { return }
        let newHit = ImpressionsHit(identifier: UUID().uuidString, impressions: currentImpressionsTests())
        impressionsHits[newHit.identifier] = newHit
        currentImpressionsHit.removeAll()
    }
    
    private func createPollingManager(dispatchGroup: DispatchGroup?){
        var config = PollingManagerConfig()
        config.rate = self.impressionsPushRate
        
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
    
    private func sendImpressions() {
        for (_, impressionsHit) in impressionsHits {
            sendImpressions(impressionsHit: impressionsHit)
        }
    }
    
    private func sendImpressions(impressionsHit: ImpressionsHit) {
        if impressionsHits.count == 0 { return }
        if restClient.isSdkServerAvailable() {
            impressionsHit.addAttempt()
            
            restClient.sendImpressions(impressions: impressionsHit.impressions, completion: { result in
                do {
                    let _ = try result.unwrap()
                    Logger.d("Impressions posted successfully")
                    self.impressionsHits.removeValue(forKey: impressionsHit.identifier)
                } catch {
                    Logger.e("Impressions error: \(String(describing: error))")
                    if impressionsHit.attempts >= self.kMaxHitAttempts {
                        self.impressionsHits.removeValue(forKey: impressionsHit.identifier)
                    }
                }
            })
        }
    }
    
    private func currentImpressionsTests() -> [ImpressionsTest] {
        return currentImpressionsHit.all.map { key, impressions in
            return ImpressionsTest(testName: key, keyImpressions: impressions)
        }
    }
    
    func saveImpressionsToDisk() {
        let impressionsFile = ImpressionsFile()
        impressionsFile.oldHits = impressionsHits
        
        if currentImpressionsHit.count > 0 {
            let newHit = ImpressionsHit(identifier: UUID().uuidString, impressions: currentImpressionsTests())
            impressionsFile.currentHit = newHit
        }

        do {
            let json = try Json.encodeToJson(impressionsFile)
            impressionsFileStorage?.save(content: json, as: kImpressionsFileName)
        } catch {
            Logger.e("Could not save impressions hits)")
        }
    }
    
    func loadImpressionsFromDisk(){
        guard let hitsJson = impressionsFileStorage?.read(fileName: kImpressionsFileName) else {
            return
        }
        if hitsJson.count == 0 { return }
        impressionsFileStorage?.delete(fileName: kImpressionsFileName)
        do {
            let hitsFile = try Json.encodeFrom(json: hitsJson, to: ImpressionsFile.self)
            impressionsHits = hitsFile.oldHits ?? [String: ImpressionsHit]()
            currentImpressionsHit = SynchronizedDictionaryWrapper()
            if let tests = hitsFile.currentHit?.impressions {
                for test in tests {
                    for impresion in test.keyImpressions {
                        currentImpressionsHit.appendValue(impresion, toKey: test.testName)
                    }
                }
            }
            
        } catch {
            Logger.e("Error while loading Impression impressions from disk")
            return
        }
    }

}

// MARK: Background / Foreground
extension ImpressionManager {
    @objc func applicationDidEnterBackground() {
        Logger.d("Saving Impression to disk")
        saveImpressionsToDisk()
    }
    
    @objc func applicationDidBecomeActive() {
        loadImpressionsFromDisk()
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
