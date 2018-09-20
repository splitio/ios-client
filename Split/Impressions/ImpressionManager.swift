//
//  ImpressionManager.swift
//  Split
//
//  Created by Natalia  Stele on 03/01/2018.
//

import Foundation

class ImpressionManager {
    private let kImpressionsPrefix: String = "impressions_"
    var interval: Int
    var impressionsChunkSize: Int64
    private var featurePollTimer: DispatchSourceTimer?
    weak var dispatchGroup: DispatchGroup?
    var impressionStorage = SynchronizedDictionaryWrapper<String, Impression>()
    private var fileStorage = FileStorage()
    private var impressionsFileStorage: FileStorageManager?
    let kEmptyJson: String = "[]"
    private var impressionAccum: Int = 0
    
    private let restClient = RestClient()
    
    public static let shared: ImpressionManager = {
        
        let instance = ImpressionManager()
        return instance;
    }()
    
    public init(interval: Int = 10, dispatchGroup: DispatchGroup? = nil, impressionsChunkSize: Int64 = 100) {
        self.interval = interval
        self.dispatchGroup = dispatchGroup
        self.impressionsFileStorage = FileStorageManager(storage: self.fileStorage, filePrefix: kImpressionsPrefix)
        self.impressionsChunkSize = impressionsChunkSize
        subscribeNotifications()
    }
    
    public func sendImpressions(fileContent: String?, fileName: String) {
        
        guard let fileContent = fileContent else {
            return
        }
        
        if !restClient.isSdkServerAvailable() {
            saveImpressionsToDisk()
        } else {
            restClient.sendImpressions(impressions: fileContent, completion: { result in
                do {
                    let _ = try result.unwrap()
                    Logger.d("Impressions posted successfully")
                    self.cleanImpressions(fileName: fileName)
                } catch {
                    self.impressionsFileStorage?.save(fileName: fileName)
                    Logger.e("Impressions error : \(String(describing: error))")
                }
            })
        }
    }

    private func startPollingForImpressions() {
        
        let queue = DispatchQueue(label: "split-polling-queue")
        featurePollTimer = DispatchSource.makeTimerSource(queue: queue)
        featurePollTimer!.schedule(deadline: .now(), repeating: .seconds(self.interval))
        featurePollTimer!.setEventHandler { [weak self] in
            guard let strongSelf = self else {
                return
            }
            guard strongSelf.featurePollTimer != nil else {
                strongSelf.stopPollingForSendImpressions()
                return
            }
            strongSelf.pollForSendImpressions()
        }
        featurePollTimer!.resume()
    }

    private func stopPollingForSendImpressions() {
        featurePollTimer?.cancel()
        featurePollTimer = nil
    }
    
    private func pollForSendImpressions() {
        
        dispatchGroup?.enter()
        let queue = DispatchQueue(label: "split-impressions-queue")
        queue.async { [weak self] in
            guard let strongSelf = self else {
                return
            }
            strongSelf.saveImpressionsToDisk()
            strongSelf.sendImpressionsFromFile()
            strongSelf.dispatchGroup?.leave()
        }
    }
    
    public func start() {
        startPollingForImpressions()
    }
    
    public func stop() {
        stopPollingForSendImpressions()
    }
    
    private func cleanImpressions(fileName: String) {
        impressionsFileStorage?.delete(fileName: fileName)
    }

    public func appendImpressions(impression: Impression, splitName: String) {
        impressionStorage.appendValue(value: impression, toKey: splitName)
        impressionAccum += 1
        if impressionAccum >= impressionsChunkSize {
            impressionAccum = 0
            saveImpressionsToDisk()
        }
    }
    
    func saveImpressionsToDisk() {
        //Create data set with all the impressions
        let impressionsToSave = impressionStorage.all
        if let jsonImpression = encodeImpressions(hits: buildImpressionsHits(impressions: impressionsToSave)), jsonImpression != kEmptyJson {
            impressionsFileStorage?.save(content: jsonImpression)
            impressionStorage.removeValues(forKeys: impressionsToSave.keys)
        }
    }
    
    func encodeImpressions(hits: [ImpressionsHit]) -> String? {
        let encodedData = try? JSONEncoder().encode(hits)
        guard let json = String(data: encodedData!, encoding: String.Encoding(rawValue: String.Encoding.utf8.rawValue)) else {
            return nil
        }
        return json
    }
    
    public func buildImpressionsHits(impressions: [String: [Impression]]) -> [ImpressionsHit] {
        var hits: [ImpressionsHit] = []
        for key in impressions.keys {
            if let array = impressions[key] {
                let hit = ImpressionsHit()
                hit.keyImpressions = array
                hit.testName = key
                hits.append(hit)
            }
        }
        return hits
    }
    
    func sendImpressionsFromFile() {
        if let fileStorage = impressionsFileStorage {
            let impressionsFiles = fileStorage.read()
            for fileName in impressionsFiles.keys {
                let fileContent = impressionsFiles[fileName]
                sendImpressions(fileContent: fileContent, fileName: fileName)
            }
        }
    }
    
    @objc func applicationDidEnterBackground(_ application: UIApplication) {
        
        saveImpressionsToDisk()
    }
    
    func subscribeNotifications() {
        
        NotificationCenter.default.addObserver(self, selector: #selector(applicationDidEnterBackground(_:)), name: .UIApplicationDidEnterBackground, object: nil)
        
    }
    
    deinit {
        
        NotificationCenter.default.removeObserver(self, name: .UIApplicationDidEnterBackground, object: nil)
        
    }
    
}
