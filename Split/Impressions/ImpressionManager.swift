//
//  ImpressionManager.swift
//  Split
//
//  Created by Natalia  Stele on 03/01/2018.
//

import Foundation

public typealias ImpressionsBulk = [ImpressionsHit]

public class ImpressionManager {
    private let kImpressionsPrefix: String = "impressions_"
    public var interval: Int
    public var impressionsChunkSize: Int64
    private var featurePollTimer: DispatchSourceTimer?
    public weak var dispatchGroup: DispatchGroup?
    public var impressionStorage: [String:[Impression]] = [:]
    private var fileStorage = FileStorage()
    private var impressionsFileStorage: FileStorageManager?
    public static let EMPTY_JSON: String = "[]"
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
    
    //------------------------------------------------------------------------------------------------------------------
    public func sendImpressions(fileContent: String?, fileName: String) {
        
        guard let fileContent = fileContent else {
            return
        }
        
        var reachable: Bool = true
        
        if let reachabilityManager = NetworkReachabilityManager(host: "sdk.split.io/api/version") {
            if (!reachabilityManager.isReachable)  {
                reachable = false
            }
        }
        
        if !reachable {
            Logger.v("Saving impressions")
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
    //------------------------------------------------------------------------------------------------------------------
    
    public func createImpressionsBulk() -> ImpressionsBulk {
        
        var hits: [ImpressionsHit] = []
        
        for key in impressionStorage.keys {
            
            let array = impressionStorage[key]
            let hit = ImpressionsHit()
            hit.keyImpressions = array
            hit.testName = key
            hits.append(hit)
            
        }
        
        return hits
    }
    
    //------------------------------------------------------------------------------------------------------------------
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
    //------------------------------------------------------------------------------------------------------------------
    
    
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
            strongSelf.sendImpressionsFromFile()
            strongSelf.dispatchGroup?.leave()
        }
    }
    //------------------------------------------------------------------------------------------------------------------
    
    public func start() {
        startPollingForImpressions()
    }
    //------------------------------------------------------------------------------------------------------------------
    
    
    public func stop() {
        stopPollingForSendImpressions()
    }
    //------------------------------------------------------------------------------------------------------------------
    
    private func cleanImpressions(fileName: String) {
        
        impressionStorage = [:]
        impressionsFileStorage?.delete(fileName: fileName)
        
    }
    //------------------------------------------------------------------------------------------------------------------
    
    func saveImpressions(json: String) {
        
        impressionsFileStorage?.save(content: json)
        impressionStorage = [:]
        
    }
    //------------------------------------------------------------------------------------------------------------------
    
    
    func createEncodedImpressions() -> Data? {
        
        //Create data set with all the impressions
        let hits: [ImpressionsHit] = createImpressionsBulk()
        
        //Create json file with impressions
        let encodedData = try? JSONEncoder().encode(hits)
        
        return encodedData
    }
    //------------------------------------------------------------------------------------------------------------------
    
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
    //------------------------------------------------------------------------------------------------------------------
    
    func sizeOfJsonString(impression: Impression) -> Int {
        
        let encodedData = try? JSONEncoder().encode(impression)
        
        let json = String(data: encodedData!, encoding: String.Encoding(rawValue: String.Encoding.utf8.rawValue))
        if let json = json {
            
            return json.utf8.count
        }
        
        
        return 0
        
    }
    //------------------------------------------------------------------------------------------------------------------

    public func appendImpressions(impression: Impression, splitName: String) {
        
        var impressionsArray = impressionStorage[splitName]
        var shouldSaveToDisk = false
        //calculate size
        let impressionSize: Int = sizeOfJsonString(impression: impression)
        impressionAccum = impressionAccum + impressionSize
        
        if impressionAccum >= impressionsChunkSize {
            
            shouldSaveToDisk = true
            impressionAccum = 0
            
        }
        
        if  impressionsArray != nil {
            
            impressionsArray?.append(impression)
            impressionStorage[splitName] = impressionsArray
            
            
        } else {
            
            impressionsArray = []
            impressionsArray?.append(impression)
            impressionStorage[splitName] = impressionsArray
            
        }
        
        if shouldSaveToDisk {
            
            saveImpressionsToDisk()
            
        }
        
    }
    //------------------------------------------------------------------------------------------------------------------
    
    func saveImpressionsToDisk() {
        
        let jsonImpression = createImpressionsJsonString()
        
        if jsonImpression != ImpressionManager.EMPTY_JSON {
            
            saveImpressions(json: jsonImpression)
            
        }
        
    }
    //------------------------------------------------------------------------------------------------------------------
    
    func sendImpressionsFromFile() {
        
        if let fileStorage = impressionsFileStorage {
            let impressionsFiles = fileStorage.read()
            for fileName in impressionsFiles.keys {
                let fileContent = impressionsFiles[fileName]
                sendImpressions(fileContent: fileContent, fileName: fileName)
            }
        }
        
    }
    //------------------------------------------------------------------------------------------------------------------
    @objc func applicationDidEnterBackground(_ application: UIApplication) {
        
        Logger.d("Saving impressions to disk")
        saveImpressionsToDisk()
    }
    //------------------------------------------------------------------------------------------------------------------
    func subscribeNotifications() {
        
        NotificationCenter.default.addObserver(self, selector: #selector(applicationDidEnterBackground(_:)), name: .UIApplicationDidEnterBackground, object: nil)
        
    }
    //------------------------------------------------------------------------------------------------------------------
    deinit {
        
        NotificationCenter.default.removeObserver(self, name: .UIApplicationDidEnterBackground, object: nil)
        
    }
    //------------------------------------------------------------------------------------------------------------------
}
