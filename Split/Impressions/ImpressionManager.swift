//
//  ImpressionManager.swift
//  Split
//
//  Created by Natalia  Stele on 03/01/2018.
//

import Foundation
import Alamofire
import SwiftyJSON

public typealias ImpressionsBulk = [ImpressionsHit]

extension Request {
    public func debugLog() -> Self {
        #if DEBUG
            debugPrint(self)
        #endif
        return self
    }
}

public class ImpressionManager {
    
    public var interval: Int
    public var impressionsChunkSize: Int64
    private var featurePollTimer: DispatchSourceTimer?
    public weak var dispatchGroup: DispatchGroup?
    public var impressionStorage: [String:[ImpressionDTO]] = [:]
    private var fileStorage = FileStorage()
    private var impressionsFileStorage: ImpressionsFileStorage?
    public static let EMPTY_JSON: String = "[]"
    private var impressionAccum: Int = 0
    
    
    public static let shared: ImpressionManager = {
        
        let instance = ImpressionManager()
        return instance;
    }()
    
    public init(interval: Int = 10, dispatchGroup: DispatchGroup? = nil, impressionsChunkSize: Int64 = 100) {
        self.interval = interval
        self.dispatchGroup = dispatchGroup
        self.impressionsFileStorage = ImpressionsFileStorage(storage: self.fileStorage)
        self.impressionsChunkSize = impressionsChunkSize
        subscribeNotifications()
    }
    
    public func sendImpressions(fileContent: Data?, fileName: String) {
        
        let composeRequest = createRequest(content: fileContent, fileName: fileName)
        let request = composeRequest["request"] as! URLRequest
        let filename: String = composeRequest["fileName"] as! String
        var reachable: Bool = true
        
        if let reachabilityManager = Alamofire.NetworkReachabilityManager(host: "sdk.split.io/api/version") {
            if (!reachabilityManager.isReachable)  {
                reachable = false
            }
        }
        
        if !reachable {
            Logger.d("SAVE IMPRESSIONS TO DISK")
            saveImpressionsToDisk()
        } else {
            
            Alamofire
                .request(request)
                .debugLog()
                .validate(statusCode: 200..<500)
                .response {  [weak self] response in
                
                guard let strongSelf = self else {
                    return
                }
                
                if response.error != nil && reachable {
                    strongSelf.impressionsFileStorage?.saveImpressions(fileName: filename)
                    Logger.e("[IMPRESSION] error : \(String(describing: response.error))")
                } else {
                    Logger.d("[IMPRESSION FIRED]")
                    strongSelf.cleanImpressions(fileName: filename)
                    
                }
            }
        }
    }
    
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
        
        impressionStorage = [:]
        impressionsFileStorage?.deleteImpressions(fileName: fileName)
        
    }
    
    func saveImpressions(json: String) {
        
        impressionsFileStorage?.saveImpressions(impressions: json)
        impressionStorage = [:]
        
    }

    
    func createRequest(content: Data?, fileName: String) -> [String:Any] {
        let url: URL
        url = ConfigurableTarget.GetImpressions().url
        
        //var headers: HTTPHeaders = TargetConfiguration.getCommonHeaders()
        var headers: HTTPHeaders = [:]
        headers["splitsdkversion"] = Version.toString()
        headers["authorization"] = "Bearer " + SecureDataStore.shared.getToken()!
        headers["content-type"] = "application/json"
        
        //Create new request
        var request = URLRequest(url: url)
        request.httpMethod = HTTPMethod.post.rawValue
        request.allHTTPHeaderFields = headers
        
        
        //Create json file with impressions
        let encodedData = content
        
        request.httpBody = encodedData
        
        var composeRequest : [String:Any] = [:]
        
        composeRequest["request"] = request
        composeRequest["fileName"] = fileName
        
        return composeRequest
        
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
    
    
    func sizeOfJsonString(impression: ImpressionDTO) -> Int {
        
        let encodedData = try? JSONEncoder().encode(impression)
        
        let json = String(data: encodedData!, encoding: String.Encoding(rawValue: String.Encoding.utf8.rawValue))
        if let json = json {
            
            return json.utf8.count
        }
        
        
        return 0
        
    }
    
    public func appendImpressions(impression: ImpressionDTO, splitName: String) {
        
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

    
    func saveImpressionsToDisk() {
        
        let jsonImpression = createImpressionsJsonString()
        
        if jsonImpression != ImpressionManager.EMPTY_JSON {
            
            saveImpressions(json: jsonImpression)
            
        }
        
    }

    
    func sendImpressionsFromFile() {
        
        if let impressionsFiles = impressionsFileStorage?.readImpressions() {
            
            for fileName in impressionsFiles.keys {
                
                let file = impressionsFiles[fileName]
                
                let encodedData = file?.data(using: .utf8)
                
                sendImpressions(fileContent: encodedData,fileName: fileName)
                
                
            }
            
        }
        
    }

    @objc func applicationDidEnterBackground(_ application: UIApplication) {
        Logger.d("SAVE IMPRESSIONS TO DISK")
        saveImpressionsToDisk()
    }

    func subscribeNotifications() {
        
        NotificationCenter.default.addObserver(self, selector: #selector(applicationDidEnterBackground(_:)), name: .UIApplicationDidEnterBackground, object: nil)

    }

    deinit {
        
        NotificationCenter.default.removeObserver(self, name: .UIApplicationDidEnterBackground, object: nil)

    }

}
