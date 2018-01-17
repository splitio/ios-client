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

public class ImpressionManager {
    
    public var interval: Int
    public var impressionsChunkSize: Int64
    private var featurePollTimer: DispatchSourceTimer?
    public weak var dispatchGroup: DispatchGroup?
    public var impressionStorage: [String:[ImpressionDTO]] = [:]
    private var fileStorage = FileStorage()
    private var impressionsFileStorage: ImpressionsFileStorage?
    public static let emptyJson: String = "[]"
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
    }
    
    //------------------------------------------------------------------------------------------------------------------
    public func sendImpressions(fileContent: Data?) {
        
        let composeRequest = createRequest(content: fileContent)
        let request = composeRequest["request"] as! URLRequest
        
        var reachable: Bool = true
        
        if let reachabilityManager = Alamofire.NetworkReachabilityManager(host: "sdk.split.io/api/version") {
            
            if (!reachabilityManager.isReachable)  {
                
                reachable = false
                
            }
            
        }
        
        if !reachable {
            
            print("SAVE IMPRESSIONS")
            saveImpressionsToDisk()
            
        } else {
            
            Alamofire.request(request).validate(statusCode: 200..<300).response {  [weak self] response in
                
                guard let strongSelf = self else {
                    return
                }
                
                if response.error != nil {
                    
                    let imp = strongSelf.impressionsFileStorage?.readImpressions()
                    print("[IMPRESSION] error : \(String(describing: response.error))")
                    
                } else {
                    
                    print("[IMPRESSION FIRED]")
                    strongSelf.cleanImpressions()
                    
                }
                
            }
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
            do {
                
                strongSelf.sendImpressionsFromFile()
                
                strongSelf.dispatchGroup?.leave()
                
            } catch let error {
                
                //TODO: throw error when impressions fail
                debugPrint("Problem fetching splitChanges: %@", error.localizedDescription)
            }
            
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
    
    private func cleanImpressions() {
        
        impressionStorage = [:]
        impressionsFileStorage?.deleteImpressions()
        
    }
    //------------------------------------------------------------------------------------------------------------------
    
    func saveImpressions(json: String) {
        
        impressionsFileStorage?.saveImpressions(impressions: json)
        impressionStorage = [:]
        
    }
    //------------------------------------------------------------------------------------------------------------------
    
    func createRequest(content: Data?) -> [String:Any] {
        
        // Configure paramaters
        let url: URL = URL(string: "https://events-aws-staging.split.io/api/testImpressions/bulk")!
        var headers: HTTPHeaders = [:]
        headers["splitsdkversion"] = "go-23.1.1"
        headers["splitsdkmachineip"] = "123.123.123.123"
        headers["splitsdkmachinename"] = "ip-127-0-0-1"
        // headers["authorization"] = "Bearer k6ogh4k721d4p671h6spc04n0pg1a6h1cmpq"
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
        
        return composeRequest
        
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
    
    func sizeOfJsonString(impression: ImpressionDTO) -> Int {
        
        let encodedData = try? JSONEncoder().encode(impression)
        
        let json = String(data: encodedData!, encoding: String.Encoding(rawValue: String.Encoding.utf8.rawValue))
        if let json = json {
            
            return json.utf8.count
        }
        
        
        return 0
        
    }
    //------------------------------------------------------------------------------------------------------------------
    
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
    //------------------------------------------------------------------------------------------------------------------
    
    func saveImpressionsToDisk() {
        
        let jsonImpression = createImpressionsJsonString()
        saveImpressions(json: jsonImpression)
        
    }
    //------------------------------------------------------------------------------------------------------------------
    
    func sendImpressionsFromFile() {
        
        if let impressionsFiles = impressionsFileStorage?.readImpressions() {
            
            for file in impressionsFiles {
                
                let encodedData = file.data(using: .utf8)
                
                sendImpressions(fileContent: encodedData)
                
                
            }
            
        }
        
    }
    //------------------------------------------------------------------------------------------------------------------
    
}
