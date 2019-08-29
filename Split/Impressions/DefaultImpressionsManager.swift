//
//  ImpressionManager.swift
//  Split
//
//  Created by Javier Avrudsky on 06/14/2018.
//
// ToDo: Replace with generic implemention for track events and impressions. Temporal implementation.

import Foundation

struct ImpressionManagerConfig {
    var pushRate: Int
    var impressionsPerPush: Int64
}

class DefaultImpressionsManager: ImpressionsManager {

    private let kImpressionsFileName: String = "SPLITIO.impressions"
    private let kMaxHitAttempts = 3

    private var fileStorage: FileStorageProtocol

    private var currentImpressionsHit = SyncDictionaryCollectionWrapper<String, Impression>()
    private var impressionsHits = SyncDictionarySingleWrapper<String, ImpressionsHit>()

    private let restClient: RestClientImpressions
    private var pollingManager: PollingManager!

    private var impressionsPushRate: Int!
    private var impressionsPerPush: Int64!

    init(dispatchGroup: DispatchGroup? = nil, config: ImpressionManagerConfig, fileStorage: FileStorageProtocol,
         restClient: RestClientImpressions? = nil) {
        self.fileStorage = fileStorage
        self.impressionsPushRate = config.pushRate
        self.impressionsPerPush = config.impressionsPerPush
        self.restClient = restClient ?? RestClient()
        self.createPollingManager(dispatchGroup: dispatchGroup)
        subscribeNotifications()
    }
}

// MARK: Public
extension DefaultImpressionsManager {
    func start() {
        pollingManager.start()
    }

    func stop() {
        pollingManager.stop()
    }

    func flush() {
        appendHitAndSendAll()
    }

    func appendImpression(impression: Impression, splitName: String) {
        currentImpressionsHit.appendValue(impression, toKey: splitName)
        if currentImpressionsHit.count == impressionsPerPush {
            appendHit()
        }
    }

    func appendHitAndSendAll() {
        appendHit()
        sendImpressions()
    }
}

// MARK: Private
extension DefaultImpressionsManager {

    private func appendHit() {
        if currentImpressionsHit.count == 0 { return }
        let newHit = ImpressionsHit(identifier: UUID().uuidString, impressions: currentImpressionsTests())
        impressionsHits.setValue(newHit, forKey: newHit.identifier)
        currentImpressionsHit.removeAll()
    }

    private func createPollingManager(dispatchGroup: DispatchGroup?) {
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
        let impressionsHits = self.impressionsHits.all
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
                    _ = try result.unwrap()
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
        impressionsFile.oldHits = impressionsHits.all

        if currentImpressionsHit.count > 0 {
            let newHit = ImpressionsHit(identifier: UUID().uuidString, impressions: currentImpressionsTests())
            impressionsFile.currentHit = newHit
        }

        do {
            let json = try Json.encodeToJson(impressionsFile)
            fileStorage.write(fileName: kImpressionsFileName, content: json)
        } catch {
            Logger.e("Could not save impressions hits)")
        }
    }

    func loadImpressionsFromDisk() {
        guard let hitsJson = fileStorage.read(fileName: kImpressionsFileName) else {
            return
        }
        if hitsJson.count == 0 { return }
        fileStorage.delete(fileName: kImpressionsFileName)
        do {
            let hitsFile = try Json.encodeFrom(json: hitsJson, to: ImpressionsFile.self)
            impressionsHits = SyncDictionarySingleWrapper()
            if let hits = hitsFile.oldHits {
                for hit in hits {
                    impressionsHits.setValue(hit.value, forKey: hit.key)
                }
            }
            currentImpressionsHit = SyncDictionaryCollectionWrapper()
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
extension DefaultImpressionsManager {
    func subscribeNotifications() {
        NotificationHelper.instance.addObserver(for: AppNotification.didBecomeActive) { [weak self] in
            guard let strongSelf = self else {
                return
            }
            strongSelf.loadImpressionsFromDisk()
        }

        NotificationHelper.instance.addObserver(for: AppNotification.didEnterBackground) { [weak self] in
            guard let strongSelf = self else {
                return
            }
            strongSelf.saveImpressionsToDisk()
        }
    }
}
