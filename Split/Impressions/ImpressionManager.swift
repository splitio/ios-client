//
//  ImpressionManager.swift
//  Split
//
//  Created by Natalia  Stele on 03/01/2018.
//

import Foundation

public typealias ImpressionsBulk = [ImpressionsHit]

class ImpressionManager {
    private let kImpressionsPrefix: String = "impressions_"
    var interval: Int
    var impressionsChunkSize: Int64
    private var featurePollTimer: DispatchSourceTimer?
    weak var dispatchGroup: DispatchGroup?
    var impressionStorage = SynchronizedDictionaryWrapper<String, [Impression]>()
    private var fileStorage = FileStorage()
    private var impressionsFileStorage: FileStorageManager?
    static let EMPTY_JSON: String = "[]"
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
    
    public func createImpressionsBulk() -> ImpressionsBulk {
        var hits: [ImpressionsHit] = []
        let impressions = impressionStorage.all
        for key in impressions.keys {
            if let array = impressionStorage.value(forKey: key){
                let hit = ImpressionsHit()
                hit.keyImpressions = array
                hit.testName = key
                hits.append(hit)
            }
        }
        return hits
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
        impressionStorage.removeAll()
        impressionsFileStorage?.delete(fileName: fileName)
    }
    
    func saveImpressions(json: String) {
        impressionsFileStorage?.save(content: json)
        impressionStorage.removeAll()
    }

    func createEncodedImpressions() -> Data? {
        
        //Create data set with all the impressions
        let hits: [ImpressionsHit] = createImpressionsBulk()
        
        //Create json file with impressions
        let encodedData = try? JSONEncoder().encode(hits)
        
        return encodedData
    }
    
    func createImpressionsJsonString() -> String {
        //Create json file with impressions
        let encodedData = createEncodedImpressions()
        let json = String(data: encodedData!, encoding: String.Encoding(rawValue: String.Encoding.utf8.rawValue))
        if let json = json {
            return json
        } else {
            return " "
        }
    }
    
    public func appendImpressions(impression: Impression, splitName: String) {
        var impressionsArray = impressionStorage.value(forKey: splitName) ?? []
        impressionsArray.append(impression)
        impressionStorage.set(value: impressionsArray, forKey: splitName)
        impressionAccum += 1
        if impressionAccum >= impressionsChunkSize {
            impressionAccum = 0
            saveImpressionsToDisk()
        }
    }
    
    func saveImpressionsToDisk() {
        let jsonImpression = createImpressionsJsonString()
        if jsonImpression != ImpressionManager.EMPTY_JSON {
            saveImpressions(json: jsonImpression)
        }
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
