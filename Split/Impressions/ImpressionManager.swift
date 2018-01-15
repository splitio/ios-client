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
    private var featurePollTimer: DispatchSourceTimer?
    public weak var dispatchGroup: DispatchGroup?
    public var impressionStorage: [String:[ImpressionDTO]] = [:]
    private var fileStorage = FileStorage()
    private var impressionsFileStorage: ImpressionsFileStorage?
    public static let emptyJson: String = "[]"
    
    public static let shared: ImpressionManager = {
        
        let instance = ImpressionManager()
        return instance;
    }()
    
    public init(interval: Int = 10, dispatchGroup: DispatchGroup? = nil) {
        self.interval = interval
        self.dispatchGroup = dispatchGroup
        self.impressionsFileStorage = ImpressionsFileStorage(storage: self.fileStorage)
    }
    
    public func sendImpressions() {
        
        let composeRequest = createRequest()
        let request = composeRequest["request"] as! URLRequest
        let json = composeRequest["json"] as! String
        
        var reachable: Bool = true
        
        if let reachabilityManager = Alamofire.NetworkReachabilityManager(host: "ssdk.split.io/api/version") {
            
            if (!reachabilityManager.isReachable)  {
                reachable = false
            }
            
        }
        
        if !reachable {
            
            print("SAVE IMPRESSIONS")
            saveImpressions(json: json)
            
        } else {
            
            if json != ImpressionManager.emptyJson {
                
                Alamofire.request(request).validate(statusCode: 200..<300).response {  [weak self] response in
                    
                    guard let strongSelf = self else {
                        return
                    }
                    
                    if response.error != nil {
                        
                        strongSelf.impressionsFileStorage?.saveImpressions(impressions: json)
                        let imp = strongSelf.impressionsFileStorage?.readImpressions()
                        strongSelf.createNewBulk(json: json)
                        print("[IMPRESSION] error : \(String(describing: response.error))")
                        
                    } else {
                        
                        print("[IMPRESSION FIRED]")
                        strongSelf.cleanImpressions()
                        
                    }
                    
                }
            }
            
        }
        
    }
    
    
    public func appendImpressions(impression: ImpressionDTO, splitName: String) {

        var impressionsArray = impressionStorage[splitName]
        
        if  impressionsArray != nil {
        
            impressionsArray?.append(impression)
            impressionStorage[splitName] = impressionsArray

        } else {
            
            impressionsArray = []
            impressionsArray?.append(impression)
            impressionStorage[splitName] = impressionsArray
            
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
            do {
                
                strongSelf.sendImpressions()
                
                strongSelf.dispatchGroup?.leave()
                
            } catch let error {
                
                //TODO: throw error when impressions fail
                debugPrint("Problem fetching splitChanges: %@", error.localizedDescription)
            }
        }
    }
    
    public func start() {
        startPollingForImpressions()
    }
    
    
    public func stop() {
        stopPollingForSendImpressions()
    }
    
    private func cleanImpressions() {
        
        impressionStorage = [:]
        impressionsFileStorage?.deleteImpressions()

    }
    
    func saveImpressions(json: String) {

        impressionsFileStorage?.saveImpressions(impressions: json)
        impressionStorage = [:]

    }
    
    func createNewBulk(json: String) {
        
        if let imp = impressionsFileStorage?.readImpressions(), imp != "" {
            
            let encodedData = imp.data(using: .utf8)
            
            let decoder = JSONDecoder()
            if encodedData != nil {
                
                let jsonDec = try? decoder.decode(ImpressionsBulk.self, from: encodedData!)
                
                if let impressionsSaved = jsonDec  {
                    
                    var hits: ImpressionsBulk = createImpressionsBulk()
                    hits.append(contentsOf: hits)
                    print(hits)
                }
                
            }
            
        }
        
    }
    
    
    func createRequest() -> [String:Any] {
        
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
        
        //Create data set with all the impressions
        let hits: [ImpressionsHit] = createImpressionsBulk()
        
        //Create json file with impressions
        let encodedData = try? JSONEncoder().encode(hits)
    
        let json = String(data: encodedData!, encoding: String.Encoding(rawValue: String.Encoding.utf8.rawValue))
        if let json = json {
            print(json)
        }
        
        request.httpBody = encodedData
        
        var composeRequest : [String:Any] = [:]
        
        composeRequest["request"] = request
        composeRequest["json"] = json
        
        return composeRequest
        
    }
}
